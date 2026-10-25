# 🤖 AGENTS.md - OpenClaw Agent Guide

This file defines how AI agents should interact with and understand the `talos-mixed` repository. It provides the mental model of the repository structure and the underlying infrastructure.

## 📂 Repository Structure

The repository follows a functional organization within the `apps/` directory. It leverages `makejinja` for templating and `FluxCD` for synchronizing the cluster state.

```text
talos-mixed/
├── .agents/             # AI instructions & skills (OpenClaw custom)
├── .github/             # GitHub Actions workflows & evidence providers
├── .renovate/           # Local Renovate configuration presets
├── bootstrap/           # Bootstrap templates (helmfile, minijinja) for cluster creation
├── docs/                # Markdown documentation
├── kubernetes/          # Kubernetes configurations (Flux-managed)
│   ├── apps/            # Application deployments, organized by FUNCTIONAL type
│   │   ├── ai/          # AI workloads (e.g., openclaw)
│   │   ├── database/    # Database operators (e.g., cloudnative-pg)
│   │   ├── external-secrets/  # Secret management
│   │   ├── network/     # Networking (Envoy Gateway, Multus, etc.)
│   │   ├── renovate/    # Dependency automation (Renovate Operator)
│   │   ├── storage/     # Storage infrastructure (Garage, Snapshot-Controller, Kopiur)
│   |   ├── volsync/    # Disaster Recovery & Data Sync (Backup/Restore)
│   |   └── ...          # Other functional categories
│   ├── components/      # Reusable Kubernetes components (non-namespaced)
│   └── flux/            # Flux lifecycle management
├── talos/               # Talos Linux machine configurations
└── template/            # Master cluster templates for re-bootstrapping
```

**Agent Note on `apps/` directory:** Each functional directory (e.g., `database/`) contains the configurations for the services belonging to that category. Within those, look for the specific application folder (e.g., `talos-mixed/kubernetes/apps/database/cloudnative-pg/`).

## 🏗️ Cluster Architecture

The `talos-mixed` repository manages a heterogeneous, high-availability cluster spanning multiple architectures.

### 🖥️ Compute Nodes

| Role              | Hardware               | Architecture | Key Specs                                            |
| :---------------- | :--------------------- | :----------- | :--------------------------------------------------- |
| **Control Plane** | 3x MS-01 (i9-13900H)   | `amd64`      | 96GB RAM each, Ceph Storage, Intel iGPU in each node |
| **Worker Nodes**  | 2x Intel NUCs          | `amd64`      | mid-performance compute, Intel iGPU in each node     |
| **Worker Nodes**  | ComputeBlade (RPi CM4) | `arm64`      | 500GB NVMe (emmc disabled)                           |

### 🛠️ Key Technologies

| Category       | Tool                                   | Purpose                                                                   |
| -------------- | -------------------------------------- | ------------------------------------------------------------------------- |
| **GitOps**     | FluxCD                                 | Continuous delivery of manifests and Helm charts.                         |
| **Networking** | Cilium (eBPF)                          | CNI, L3/L4 networking, and eBPF-based network policies.                   |
| **Ingress**    | Envoy Gateway                          | L7 ingress/egress via Kubernetes Gateway API (HTTPRoutes).                |
| **DNS**        | external-dns                           | Synchronizing Kubernetes resources to Cloudflare.                         |
| **TLS**        | cert-manager                           | Automated TLS certificate management (Let's Encrypt).                     |
| **Secrets**    | ExternalSecrets                        | Fetching secrets from external providers (e.g., Cloudflare/Vault).        |
| **Storage**    | Garage (S3), Ceph, Snapshot-Controller | Storage backend, CSI, and volume snapshots (Kopiur disabled).             |
| **Backup/DR**  | Volsync                                | Orchestrated data synchronization and disaster recovery (Backup/Restore). |
| **Automation** | Renovate                               | Automated dependency updates (Image/Helm/etc.) via PRs.                   |

---

**Instructions for the Agent:**

- **Architecture Awareness:** Always consider whether a workload/manifest is compatible with `amd64` vs `arm64`.
- **Deployment Logic:** To find a specific application, first identify its **functional category** in `kubernetes/apps/`, then locate its specific folder.
- **Configuration Change:** To change cluster-wide settings, modify `template/` and use `just configure`.
- **Troubleshooting:** For issues in a specific functional area, start by checking the related directory in `kubernetes/apps/`.
