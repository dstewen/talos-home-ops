

Here are all the files, corrected with `ceph-block` as the default storage class:

## 1. Component root: `kubernetes/components/volsync/kustomization.yaml`

```yaml
---
# yaml-language-server: $schema=https://json.schemastore.org/component.json
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component
resources:
  - ./minio
  - ./pvc.yaml
```

## 2. PVC bootstrap: `kubernetes/components/volsync/pvc.yaml`

```yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: "${VOLSYNC_CLAIM:-${APP}}"
  labels:
    app.kubernetes.io/name: "${APP}"
spec:
  accessModes: ["${VOLSYNC_ACCESSMODES:-ReadWriteOnce}"]
  dataSourceRef:
    kind: ReplicationDestination
    apiGroup: volsync.backube
    name: "${APP}-bootstrap"
  resources:
    requests:
      storage: "${VOLSYNC_CAPACITY:-2Gi}"
  storageClassName: "${VOLSYNC_STORAGECLASS:-ceph-block}"
```

## 3. Minio backend: `kubernetes/components/volsync/minio/kustomization.yaml`

```yaml
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ./externalsecret.yaml
  - ./replicationdestination.yaml
  - ./replicationsource.yaml
```

## 4. Minio ExternalSecret: `kubernetes/components/volsync/minio/externalsecret.yaml`

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/external-secrets.io/externalsecret_v1.json
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: "${APP}-volsync-minio"
spec:
  secretStoreRef:
    kind: ClusterSecretStore
    name: onepassword
  target:
    name: "${APP}-volsync-minio"
    creationPolicy: Owner
    template:
      engineVersion: v2
      data:
        RESTIC_REPOSITORY: "{{ .REPOSITORY_TEMPLATE }}/${APP}"
        RESTIC_PASSWORD: "{{ .RESTIC_PASSWORD }}"
        AWS_ACCESS_KEY_ID: "{{ .AWS_ACCESS_KEY_ID }}"
        AWS_SECRET_ACCESS_KEY: "{{ .AWS_SECRET_ACCESS_KEY }}"
  dataFrom:
    - extract:
        key: volsync-minio-template
```

## 5. Minio ReplicationSource: `kubernetes/components/volsync/minio/replicationsource.yaml`

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/volsync.backube/replicationsource_v1alpha1.json
apiVersion: volsync.backube/v1alpha1
kind: ReplicationSource
metadata:
  name: "${APP}-minio-rsrc"
spec:
  sourcePVC: "${VOLSYNC_CLAIM:-${APP}}"
  trigger:
    schedule: "0 * * * *"
  restic:
    copyMethod: Snapshot
    pruneIntervalDays: 7
    repository: "${APP}-volsync-minio"
    volumeSnapshotClassName: "${VOLSYNC_SNAPSHOTCLASS:-}"
    cacheCapacity: "${VOLSYNC_CACHE_CAPACITY:-2Gi}"
    cacheStorageClassName: "${VOLSYNC_CACHE_SNAPSHOTCLASS:-}"
    cacheAccessModes: ["${VOLSYNC_CACHE_ACCESSMODES:-ReadWriteOnce}"]
    storageClassName: "${VOLSYNC_STORAGECLASS:-ceph-block}"
    accessModes: ["${VOLSYNC_ACCESSMODES:-ReadWriteOnce}"]
    moverSecurityContext:
      runAsUser: ${APP_UID:-1000}
      runAsGroup: ${APP_GID:-1000}
      fsGroup: ${APP_GID:-1000}
    retain:
      hourly: 24
      daily: 10
      weekly: 4
      monthly: 3
      yearly: 1
```

## 6. Minio ReplicationDestination: `kubernetes/components/volsync/minio/replicationdestination.yaml`

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/volsync.backube/replicationdestination_v1alpha1.json
apiVersion: volsync.backube/v1alpha1
kind: ReplicationDestination
metadata:
  name: "${APP}-bootstrap"
  labels:
    kustomize.toolkit.fluxcd.io/ssa: IfNotPresent
spec:
  trigger:
    manual: restore-once
  restic:
    copyMethod: Snapshot
    repository: "${APP}-volsync-minio"
    cacheStorageClassName: "${VOLSYNC_CACHE_SNAPSHOTCLASS:-}"
    cacheAccessModes: ["${VOLSYNC_CACHE_ACCESSMODES:-ReadWriteOnce}"]
    cacheCapacity: "${VOLSYNC_CACHE_CAPACITY:-2Gi}"
    storageClassName: "${VOLSYNC_STORAGECLASS:-ceph-block}"
    volumeSnapshotClassName: "${VOLSYNC_SNAPSHOTCLASS:-}"
    moverSecurityContext:
      runAsUser: ${APP_UID:-1000}
      runAsGroup: ${APP_GID:-1000}
      fsGroup: ${APP_GID:-1000}
    accessModes: ["${VOLSYNC_ACCESSMODES:-ReadWriteOnce}"]
    capacity: "${VOLSYNC_CAPACITY:-2Gi}"
    enableFileDeletion: true
    cleanupCachePVC: true
    cleanupTempPVC: true
```

## 7. 1Password secret: `volsync-minio-template`

Create this in your 1Password **Kubernetes** vault:

| Field | Example value |
|---|---|
| `REPOSITORY_TEMPLATE` | `s3.garage` (or your Minio/Garage endpoint) |
| `RESTIC_PASSWORD` | (generate a strong password) |
| `AWS_ACCESS_KEY_ID` | (Minio/Garage access key) |
| `AWS_SECRET_ACCESS_KEY` | (Minio/Garage secret key) |

## Directory structure

```
kubernetes/components/volsync/
├── kustomization.yaml
├── pvc.yaml
└── minio/
    ├── kustomization.yaml
    ├── externalsecret.yaml
    ├── replicationsource.yaml
    └── replicationdestination.yaml
```

## How to use in an app's `ks.yaml`

```yaml
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: &app sonarr
  namespace: &namespace media
spec:
  targetNamespace: *namespace
  path: ./kubernetes/apps/main/media/sonarr/app
  postBuild:
    substitute:
      APP: *app
      VOLSYNC_STORAGECLASS: ceph-block
      VOLSYNC_SNAPSHOTCLASS: csi-ceph-blockpool
  components:
    - ../../../../components/volsync
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
    namespace: flux-system
```

For utility/test clusters, override `VOLSYNC_STORAGECLASS` to `local-hostpath` since they don't have Rook/Ceph.
