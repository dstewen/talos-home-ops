# talos-home-ops — Codebase Review

> **Date:** 2026-11-09
> **Reviewed by:** cortananexus-bot[bot]
> **Commit:** d5a9230
> **Scope:** Full structural and functional review of the repository

---

## 1. Overview

| Metric | Value |
|---|---|
| Total files | ~1,336 |
| Clusters | 3 (utility, main, test) |
| Nodes | 14 (utility: 3 CP, main: 3 CP + 7 workers + 2 planned, test: 1 CP) |
| Talos version | v1.14.5 |
| Kubernetes version | v1.37.2 |
| Secret provider | 1Password via topf (no SOPS) |
| Flux bootstrap | helmfile-based CRD + app sync |
| Renovate | Extends joryirving/renovate-config from a separate repo |

---

## 2. Architecture

### 2.1 Directory Structure

```
talos-home-ops/
├── .justfiles/              # Justfile modules (not in PATH)
│   ├── talos/               # secrets-provider, op.env, talsecret.yaml
│   └── volsync/             # snapshot, restore, unlock
├── .taskfiles/              # Taskfile.yaml clusters (bootstrap, kubernetes, etc.)
├── bootstrap/
│   ├── helmfile/            # crds.yaml, apps.yaml (bootstrap helmfile)
│   ├── kustomize/           # secrets.yaml.tpl (app-level secrets)
│   ├── secrets/             # Per-cluster app secrets templates
│   └── templates/           # helmfile gotmpl templates
├── kubernetes/
│   ├── apps/
│   │   ├── base/            # Shared HelmRelease, externalsecret, etc.
│   │   ├── main/            # Cluster-specific Kustomization.yaml (per app)
│   │   ├── test/            # Same pattern
│   │   └── utility/         # Same pattern
│   └── components/          # Reusable kustomize patches (gpu, postgres, etc.)
├── talos/topf/              # Postfinance topf cluster definitions
│   ├── utility/             # 3 CP nodes (CM4 blades)
│   ├── main/                # 3 CP + 7 workers + 2 DGX Sparks
│   └── test/                # 1 CP node (CM4 blade)
├── terraform/               # OpenTofu IaC (externalservices)
├── ansible/                 # Columbina server config
├── docker/                  # Docker Compose (Columbina)
├── hack/                    # Convenience scripts
└── docs/src/                # Docusaurus docs
```

### 2.2 Cluster Layout

| Cluster | Nodes | Roles | Endpoint |
|---|---|---|---|
| **utility** | blade1-3 (CM4) | Control-plane only | 10.200.15.251:6443 |
| **main** | ms1-3 (MinForum), blade5-8 (CM4), nuc1-2 (NUC) | CP + Workers | 10.200.15.253:6443 |
| **main** | spark1-2 (DGX Spark) | Workers (arm64, placeholder MAC) | (see above) |
| **test** | blade4 (CM4) | Control-plane only | 10.200.15.252:6443 |

### 2.3 Flux/GitOps

- **Flux operator + instance** deployed via bootstrap helmfile
- **Flux Kustomization** manages `kubernetes/apps/<CLUSTER>/<namespace>/<app>/kustomization.yaml`
- **HelmRelease** manifests live in `kubernetes/apps/base/` (shared)
- Cluster-specific overrides are thin wrapper Kustomizations in `kubernetes/apps/<CLUSTER>/`
- **Renovate** handles automated dependency updates (extends external config repo)
- **opinject** used for app-level secrets (onepassword-connect → ExternalSecrets)

### 2.4 Secret Management

Two-layer secret strategy:

**Layer 1 — Talos cluster secrets (via topf secretsProvider):**
- `secretsProvider: ../../../../.justfiles/talos/secrets-provider` in each cluster's `topf.yaml`
- Provider script uses `op run` with `op.env` references to 1Password
- `talsecret.yaml` template renders `${talos_*}` placeholders with resolved values
- `put` operation is refused — secrets are one-way (1Password → cluster)

**Layer 2 — Kubernetes app secrets (via onepassword-connect):**
- `bootstrap/kustomize/secrets.yaml.tpl` → templated with minijinja → `op inject` → applied
- References: `op://kubernetes/1password-{CLUSTER}/OP_SESSION_JSON`, TLS certs, etc.
- ExternalSecrets resources in `kubernetes/apps/base/external-secrets/` sync from 1Password

### 2.5 Schematics

Schematics (custom Talos ISO overlays) live in `talos/topf/<CLUSTER>/schematics/`:
- `cm4-blade.yaml` — CM4 with NUT client, UART, USB host
- `minforums-ms1.yaml` — MinForum with NUT client
- `nuc.yaml` — Intel NUC with NUT client
- `dgx.yaml` — NVIDIA Grace/Blackwell (placeholder)

---

## 3. Justfile System

### 3.1 Structure

| File | Purpose |
|---|---|
| `justfile` | Top-level: bootstraps, talos, talos-secrets, volsync, template modules |
| `bootstrap/mod.just` | Cluster bootstrap pipeline (talos → apps) |
| `talos/mod.just` | Per-cluster talos operations (nodes, apply, upgrade, reset) |
| `talos-secrets/mod.just` | Generate/verify/show 1Password-backed Talos secrets |
| `kubernetes/mod.just` | Flux operations (reconcile, suspend, resume, status) |
| `.justfiles/volsync/mod.just` | VolSync snapshot/restore operations |

### 3.2 Key Commands

```bash
just bootstrap talos CLUSTER=<cluster>    # Full Talos bootstrap
just bootstrap apps CLUSTER=<cluster>     # Full K8s bootstrap
just talos nodes CLUSTER=<cluster>        # List nodes
just talos upgrade-k8s CLUSTER=<c> VERSION=<v>  # Upgrade all nodes
just kube reconcile CLUSTER=<cluster>     # Force Flux reconcile
just volSync snapshot                     # Trigger all VolSync snapshots
just volSync restore ns=<ns> app=<app>    # Restore from VolSync backup
```

### 3.3 Observations

- `justfile` requires `minimum-version 1.55.1`
- All tasks use `set quiet` and `set no-exit-message` for clean output
- `log` helper uses `gum log` for structured terminal output
- Cluster parameter defaults vary: bootstrap/talos default to first param, kubernetes defaults to `main`

---

## 4. Kubernetes Applications

### 4.1 Base Apps (shared across all clusters)

Total of ~120+ HelmRelease resources across these categories:

| Category | Examples |
|---|---|
| **Flux System** | flux-operator, flux-instance, headlamp, konflate, tofu-controller |
| **Cert Manager** | cert-manager, Let's Encrypt clusterissuer |
| **External Secrets** | external-secrets, onepassword-connect, ClusterSecretStore |
| **Storage** | rook-ceph, democratic-csi, openebs, snapshot-controller, kopiur |
| **Database** | cloudnative-pg, dragonfly |
| **Network** | cilium, envoy-gateway, cloudflare-dns, unifi-dns, multus |
| **Observability** | kube-prometheus-stack, grafana-operator, victoria-logs, promxy, DCgm-exporter |
| **Media** | Plex (Kometa, Aggregarr), Seerr, Stash, Komga, Kavita |
| **Downloads** | Radarr, Sonarr,qbittorrent, Sabnzbd, Prowlarr, Flaresolverr |
| **LLM/AI** | LiteLLM, OpenWebUI, LM-Kube, Miso-Gallery, ComfyUI, SearXNG, ToolHive MCP |
| **Games** | Palworld, Enshrouded, Minecraft servers (Cobbleverse, Jellycraft), Valheim |
| **Self-Hosted** | Paperless, Forgejo, MeshCentral, Netboot, Picoshare |
| **Workadventure** | Livekit, Synapse, Workadventure |
| **Security** | Authentik |
| **CI** | Actions Runner Controller (GitHub self-hosted runners) |

### 4.2 Cluster-Specific Configs

Each cluster has thin wrapper Kustomizations in `kubernetes/apps/<CLUSTER>/`:
- **main**: Most apps, largest deployment
- **utility**: External services (terraform for autentik/garage/uptimerobot), observability exporters
- **test**: Minimal subset (cilium, coredns, cert-manager, external-secrets, onepassword-connect, flux, kubetools, storage, actions-runner, misospace CI)

### 4.3 Components (reusable patches)

| Component | Purpose |
|---|---|
| `gpu/` | NVIDIA GPU resource claims |
| `igpu-spread/` | Intel iGPU workload spreading |
| `dragonfly/` | Dragonfly cluster config + auth |
| `postgres/` | CNPG cluster + backups |
| `kopiur/` | Kopia backup/restore |
| `zeroscaler/` | HPA for zero-cost scaling |
| `namespace/alerts/` | GitHub/Alermanager alerting |
| `replacements/` | Flux Kustomization value replacements |

---

## 5. Node Inventory

| Host | IP | Role | Cluster | Hardware | Disk Serial |
|---|---|---|---|---|---|
| blade1 | 10.200.15.31 | CP | utility | CM4 | 22061X806385 |
| blade2 | 10.200.15.32 | CP | utility | CM4 | 220628800784 |
| blade3 | 10.200.15.33 | CP | utility | CM4 | 22061X805700 |
| blade4 | 10.200.15.34 | CP | test | CM4 | 22061X806791 |
| blade5 | 10.200.15.35 | worker | main | CM4 | 220628800811 |
| blade6 | 10.200.15.36 | worker | main | CM4 | 220628800731 |
| blade7 | 10.200.15.37 | worker | main | CM4 | 220628800801 |
| blade8 | 10.200.15.38 | worker | main | CM4 | 220628800737 |
| ms1 | 10.200.15.51 | CP | main | MinForum | 1925E20E2038 |
| ms2 | 10.200.15.52 | CP | main | MinForum | 220628801124 |
| ms3 | 10.200.15.53 | CP | main | MinForum | 22061X806789 |
| nuc1 | 10.200.15.61 | worker | main | Intel NUC | BTHH811211KF512D |
| nuc2 | 10.200.15.62 | worker | main | Intel NUC | BTHH81000E09512D |
| spark1 | 10.200.15.71 | worker | main | DGX Spark | PLACEHOLDER |
| spark2 | 10.200.15.72 | worker | main | DGX Spark | PLACEHOLDER |

**Notes:**
- `encryptDisk: false` for all nodes
- `mtu: 1500` for all nodes
- DGX Spark nodes have placeholder MAC addresses — need real values before bootstrap
- DGX Spark uses arm64 architecture (different schematic)

---

## 6. Configuration Quality

### 6.1 What's Good ✅

- **Clean separation of concerns**: base K8s configs are shared, cluster wrappers are thin
- **No secrets in git**: 1Password topf provider + onepassword-connect handles everything
- **Good documentation**: topf.yaml files have clear comments, schematics are well-described
- **Renovate integration**: Automated dependency updates with sensible defaults
- **Helmfile bootstrap**: CRDs extracted first, then apps with proper `needs` ordering
- **Cilium without kube-proxy**: Modern CNI setup with BGP support
- **NUT integration**: UPS monitoring configured across nodes (serial + NUT server)
- **WorkloadIsolation false**: Correctly disabled for Talos 1.14 to maintain host access
- **Filesystem trim/scrub**: Weekly XFS maintenance configured
- **Security hardening**: Inotify limits, ARP cache protection, network tuning
- **VolSync**: Comprehensive snapshot/restore/backup recipes

### 6.2 Areas for Improvement ⚠️

1. **DGX Spark nodes** — MAC addresses are placeholders (`PLACEHOLDER`). Must be updated before cluster bootstrap.

2. **Test cluster** — Minimal but complete. No app-level workloads yet beyond infrastructure. Fine for a test cluster.

3. **utility cluster** — Primarily hosts external services (terraform, observability exporters). Consider whether any workloads should migrate to main.

4. **No persistent volume claims** — No PVC definitions in base configs. Storage is managed dynamically via democratic-csi/openebs.

5. **No service mesh** — Cilium provides L3/L4 networking but no L7 service mesh (envoy-gateway is configured for external ingress).

6. **Talos version pinned** — `v1.14.5` / `kubernetesVersion: v1.37.2` — no Renovate auto-update for Talos itself (though `talosFactory.json5` may handle this).

7. **Backup strategy** — Kopia (kopiur) exists but no explicit backup schedule defined in this repo (likely managed by Taskfiles or external cron).

8. **No network policies** — Cilium is deployed but no NetworkPolicies visible in the base config (might be intentional, relying on zero-trust via Cilium).

9. **Single certificate** — Only `davidstewen.com` (with wildcard) is configured in secrets.yaml.tpl. Additional services may need separate certificates.

10. **Node-level configs** — Each main cluster node has individual config in `talos/topf/main/node/<node>/`. This is thorough but could be consolidated if nodes share identical config.

---

## 7. Risk Assessment

### 7.1 Low Risk
- Secret management is clean and well-documented
- Flux/GitOps pattern is mature and well-understood
- Bootstrap pipeline has good error handling and idempotency

### 7.2 Medium Risk
- **No SOPS** — If 1Password goes down, Talos cluster recovery is blocked (by design, but reduces air-gap recovery options)
- **Single TLS cert** — If `davidstewen-com-tls` is lost, all services using it need re-provisioning
- **No disk encryption** — Physical theft of nodes exposes data

### 7.3 High Risk
- **DGX Spark nodes** — Placeholder MAC addresses will cause topf to fail. Must fix before main cluster bootstrap.
- **Physical access required** — All bootstrap steps require IPMI/serial console access to nodes

---

## 8. Recommendations

1. **Fix DGX Spark MAC addresses** before any production bootstrap
2. **Add disk encryption** for sensitive nodes (workers with data)
3. **Consider additional TLS certificates** for other services (plex, paperless, etc.)
4. **Add NetworkPolicies** for defense-in-depth (even with Cilium as CNI)
5. **Document the rollback procedure** for 1Password outages
6. **Consolidate node configs** where identical (e.g., all blades can share a template)
7. **Add monitoring** for 1Password-connect pod health (it's a critical dependency)
8. **Consider adding a staging cluster** between test and main for pre-production validation

---

## 9. Session Changes (2026-11-09)

Changes made during this session (detailed in `session-summary.md`):
- Replaced SOPS with 1Password topf secretsProvider
- Fixed 4 critical bugs in justfiles
- Corrected commit authorship to bot identity
- Removed redundant `infra` cluster (consolidated into `utility`)
- Updated all comments and documentation to reflect 3-cluster layout
