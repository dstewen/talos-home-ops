# 🔄 Volsync Component

This component manages data orchestration and disaster recovery (Backup & Restore) for the cluster. It is designed to be a reusable template that becomes specialized via Flux `postBuild` substitutions.

## 🚀 Architecture & Templating

The component uses a **Template $\rightarrow$ Substitution $\rightarrow$ Specialized Resource** workflow.

We use a standard set of variables to ensure that `ReplicationSource` and `ReplicationDestination` objects are correctly mapped to the specific application and its PVCs.

### 🛠️ Variable Reference

| Variable                   | Default Value (Template) | Description                                                                               |
| :------------------------- | :----------------------- | :---------------------------------------------------------------------------------------- |
| `${APP}`                   | `(app-name)`             | The name of the application (e.g., `ftb-2`). Used for naming the resource and the volume. |
| `${VOLSYNC_CLAIM}`         | `${APP}`                 | The specific PVC name to be backed up.                                                    |
| `${VOLSYNC_CAPACITY}`      | `10Gi`                   | (Used in some configurations) The size of the volume.                                     |
| `${VOLSYNC_SNAPSHOTCLASS}` | `csi-ceph-blockpool`     | The CSI snapshot class used for volume snapshots.                                         |
| `${APP_UID}`               | `1000`                   | The User ID that the data will be owned by after restoration.                             |
| `${APP_GID}`               | `1000`                   | The Group ID that the data will be owned by after restoration.                            |

---

## ⚠️ CRITICAL: The "Mover" Permission Trap

When performing a **Restore** operation, the Volsync "Mover" container is responsible for mounting the volume and applying ownership to the files.

### The Problem: UID/GID Mismatch

The `ReplicationSource` uses a `moverSecurityContext` to set the permissions on the restored volume:

```yaml
moverSecurityContext:
    runAsUser: ${APP_UID:-1000}
    runAsGroup: ${APP_GID:-1000}
    fsGroup: ${APP_GID:-1000}
```

**If there is a mismatch between the `APP_UID` used by the Mover and the `runAsUser` defined in your Application's Helm chart/Dockerfile, the application will fail to start with `Permission Denied` errors.**

**Example of a Failure:**

1.  **Volsync Mover** runs as `UID 1000` and mounts the volume, setting ownership of the data to `1000`.
2.  **Application (e.g., a specialized Docker image)** is configured to run as `UID 2000`.
3.  **Result:** The application attempts to write to its data directory, but the OS denies the request because the files are owned by `1000`.

### 🛡️ How to Avoid This

Always ensure that the `APP_UID` and `APP_GID` variables passed to the Volsync component match the `securityContext` of your application's workload.

**Always check your `kustomization.yaml` or `postBuild` substitutions to verify that:**
`APP_UID` (in Volsync) **==** `runAsUser` (in your Application HelmRelease).

---

## 🛡️ Backup/Restore Workflow

### 1. Backup (ReplicationSource)

The `ReplicationSource` triggers an orchestrated snapshot via the CSI driver (e.g., Ceph) and uses **Restic** to push the data to the `ReplicationDestination` (e.g., Minio/Garage).

### 2. Restore (ReplicationDestination)

When a `ReplicationDestination` is triggered, Volsync:

1.  Creates a new PVC.
2.  Uses the **Mover** container to pull the Restic repository.
3.  **Applies the `moverSecurityContext` ownership to the restored files.**
4.  The application can then mount the volume with the correct permissions.

```

```
