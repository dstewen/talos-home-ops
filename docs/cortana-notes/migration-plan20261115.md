

Here's the complete updated `MIGRATION_PLAN.md`:

```markdown
# Multicluster Migration Plan
## talos-mixed → talos-home-ops

> **Date:** 2026-11-09
> **Last updated:** 2026-11-15 — updated wipe flags for CM4/Spark NVMe safety, added spark1-2 inventory, upgraded to Talos v1.14.6
> **Branch:** `main` (all config changes merged)
> **Strategy:** Full wipe-and-rebootstrap of all nodes to validate the new process
>
> **IMPORTANT: Prerequisites checked during this session:**
> - `just` must be installed on the management node (run `just --list` to verify)
> - `topf` replaces `talosctl gen` for config rendering — ensure it's installed
> - All Talos secrets are now in 1Password (no SOPS files in git)
> - Secret provider script at `.justfiles/talos/secrets-provider` is wired into all cluster topf.yaml files
> - 3 clusters: **utility**, **main**, **test** (no `infra` cluster — it was consolidated into `utility`)
> - **DGX Spark MAC addresses are correct** in `talos/topf/main/topf.yaml` (spark1: `4c:bb:47:ec:9d:9e`, spark2: `4c:bb:47:ec:9c:99`)
>
> **⚠️ CRITICAL: CM4/Spark NVMe wipe safety**
> - **Never use `--wipe-mode all`** on CM4 blades or DGX Sparks — it wipes the bootloader and bricks the NVMe
> - Always use `--system-labels-to-wipe STATE --system-labels-to-wipe EPHEMERAL` (or `--wipe-mode system-disk`)
> - The `just talos reset-node` wrapper has been updated with the correct flags
> - When removing nodes from the **old** `talos-mixed` cluster, use the explicit `talosctl reset` commands below

---

## Pre-Migration Checklist

- [ ] Confirm volsync replication sources are healthy (check `ReplicationSource` resources in apps that use persistent volumes)
- [ ] **Download DGX Spark Talos ISO** from https://factory.talos.dev/ (arm64, v1.14.6) — required for spark1/spark2 bootstrap
- [ ] **Confirm all 1Password Talos items exist** — run `just talos-secrets verify CLUSTER=<cluster>` for each cluster to validate fields
- [ ] **Confirm all 1Password app items exist** — `1password-{utility,main,test}` items with `OP_SESSION_JSON` and `OP_CONNECT_TOKEN` fields
- [ ] Confirm CNPG barman backups are current (check `kubectl --context main get backups.postgresql.cnpg.io -n database -o wide` — should show daily completed backups)
- [ ] Ensure 1Password `kubernetes` vault exists with:
  - `OP_SESSION_JSON` field
  - `OP_CONNECT_TOKEN` field
  - `davidstewen-com-tls` secret (tls.crt, tls.key)
- [ ] Ensure `just` is installed on the management node (minimum version 1.55.1)
- [ ] Ensure `topf` is installed (Postfinance config tool for rendering Talos configs)
- [ ] Ensure `talosctl`, `op`, `kubectl`, `helmfile`, `minijinja-cli` are available
- [ ] Verify serial console / IPMI access to all nodes is working
- [ ] Confirm no one is actively using apps in `talos-mixed` that haven't been backed up

---

## Node Inventory

### Utility Cluster (blade1-3)
| Host | IP | Role | MAC Address | Disk Serial |
|---|---|---|---|---|
| blade1 | 10.200.15.31 | control-plane | e4:5f:01:50:27:2d | 22061X806385 |
| blade2 | 10.200.15.32 | control-plane | e4:5f:01:ec:16:54 | 220628800784 |
| blade3 | 10.200.15.33 | control-plane | e4:5f:01:ec:16:a2 | 22061X805700 |

Cluster endpoint: `https://10.200.15.251:6443`

### Test Cluster (blade4)
| Host | IP | Role | MAC Address | Disk Serial |
|---|---|---|---|---|
| blade4 | 10.200.15.34 | control-plane | e4:5f:01:ec:16:66 | 22061X806791 |

Cluster endpoint: `https://10.200.15.252:6443`

### Main Cluster (ms1-3, blade5-8, nuc1-2, spark1-2)
| Host | IP | Role | MAC Address | Disk Serial |
|---|---|---|---|---|
| ms1 | 10.200.15.51 | control-plane | 58:47:ca:77:cf:36 | 1925E20E2038 |
| ms2 | 10.200.15.52 | control-plane | 58:47:ca:78:f1:32 | 220628801124 |
| ms3 | 10.200.15.53 | control-plane | 58:47:ca:78:f8:4a | 22061X806789 |
| blade5 | 10.200.15.35 | worker | e4:5f:01:ec:16:b4 | 220628800811 |
| blade6 | 10.200.15.36 | worker | e4:5f:01:ec:16:a5 | 220628800731 |
| blade7 | 10.200.15.37 | worker | e4:5f:01:ec:16:9c | 220628800801 |
| blade8 | 10.200.15.38 | worker | e4:5f:01:ec:16:5a | 220628800737 |
| nuc1 | 10.200.15.61 | worker | d4:5d:df:1a:27:fe | BTHH811211KF512D |
| nuc2 | 10.200.15.62 | worker | d4:5d:df:1a:28:c4 | BTHH81000E09512D |
| spark1 | 10.200.15.71 | worker | 4c:bb:47:ec:9d:9e | — |
| spark2 | 10.200.15.72 | worker | 4c:bb:47:ec:9c:99 | — |

Cluster endpoint: `https://10.200.15.253:6443`

---

## Step 0 — Remove Nodes from Old talos-mixed Cluster

> **⚠️ CRITICAL:** Before wiping, remove each node from the **old** `talos-mixed` cluster using the safe wipe flags. **Never use `--wipe-mode all`** on CM4 blades or DGX Sparks — it wipes the bootloader and bricks the NVMe.

### Step 0a — Remove Utility Nodes (blade1-3) from talos-mixed

```bash
# blade1 — remove from old cluster, safe wipe
talosctl --talosconfig ~/.talos/config-talos-mixed reset --nodes blade1 \
  --graceful \
  --system-labels-to-wipe STATE \
  --system-labels-to-wipe EPHEMERAL \
  --reboot \
  --wait \
  --timeout 30m

# blade2
talosctl --talosconfig ~/.talos/config-talos-mixed reset --nodes blade2 \
  --graceful \
  --system-labels-to-wipe STATE \
  --system-labels-to-wipe EPHEMERAL \
  --reboot \
  --wait \
  --timeout 30m

# blade3
talosctl --talosconfig ~/.talos/config-talos-mixed reset --nodes blade3 \
  --graceful \
  --system-labels-to-wipe STATE \
  --system-labels-to-wipe EPHEMERAL \
  --reboot \
  --wait \
  --timeout 30m
```

### Step 0b — Remove Test Node (blade4) from talos-mixed

```bash
talosctl --talosconfig ~/.talos/config-talos-mixed reset --nodes blade4 \
  --graceful \
  --system-labels-to-wipe STATE \
  --system-labels-to-wipe EPHEMERAL \
  --reboot \
  --wait \
  --timeout 30m
```

### Step 0c — Remove Main Cluster Nodes from talos-mixed

```bash
# Control-planes
talosctl --talosconfig ~/.talos/config-talos-mixed reset --nodes ms1 \
  --graceful \
  --system-labels-to-wipe STATE \
  --system-labels-to-wipe EPHEMERAL \
  --reboot \
  --wait \
  --timeout 30m

talosctl --talosconfig ~/.talos/config-talos-mixed reset --nodes ms2 \
  --graceful \
  --system-labels-to-wipe STATE \
  --system-labels-to-wipe EPHEMERAL \
  --reboot \
  --wait \
  --timeout 30m

talosctl --talosconfig ~/.talos/config-talos-mixed reset --nodes ms3 \
  --graceful \
  --system-labels-to-wipe STATE \
  --system-labels-to-wipe EPHEMERAL \
  --reboot \
  --wait \
  --timeout 30m

# Workers
talosctl --talosconfig ~/.talos/config-talos-mixed reset --nodes blade5 \
  --graceful \
  --system-labels-to-wipe STATE \
  --system-labels-to-wipe EPHEMERAL \
  --reboot \
  --wait \
  --timeout 30m

talosctl --talosconfig ~/.talos/config-talos-mixed reset --nodes blade6 \
  --graceful \
  --system-labels-to-wipe STATE \
  --system-labels-to-wipe EPHEMERAL \
  --reboot \
  --wait \
  --timeout 30m

talosctl --talosconfig ~/.talos/config-talos-mixed reset --nodes blade7 \
  --graceful \
  --system-labels-to-wipe STATE \
  --system-labels-to-wipe EPHEMERAL \
  --reboot \
  --wait \
  --timeout 30m

talosctl --talosconfig ~/.talos/config-talos-mixed reset --nodes blade8 \
  --graceful \
  --system-labels-to-wipe STATE \
  --system-labels-to-wipe EPHEMERAL \
  --reboot \
  --wait \
  --timeout 30m

talosctl --talosconfig ~/.talos/config-talos-mixed reset --nodes nuc1 \
  --graceful \
  --system-labels-to-wipe STATE \
  --system-labels-to-wipe EPHEMERAL \
  --reboot \
  --wait \
  --timeout 30m

talosctl --talosconfig ~/.talos/config-talos-mixed reset --nodes nuc2 \
  --graceful \
  --system-labels-to-wipe STATE \
  --system-labels-to-wipe EPHEMERAL \
  --reboot \
  --wait \
  --timeout 30m
```

**Verify all nodes have rebooted into Talos maintenance mode:**
```bash
for node in blade1 blade2 blade3 blade4 ms1 ms2 ms3 blade5 blade6 blade7 blade8 nuc1 nuc2; do
  echo -n "$node: "
  talosctl --talosconfig ~/.talos/config-talos-mixed --nodes $node get health 2>&1 | head -1
done
```

You should see failures (nodes are no longer in the old cluster) and a Talos CLI prompt at the serial console. If you see a normal shell, the reset didn't work and you may need to run it again or check IPMI.

---

## Step 1 — Bootstrap Utility Cluster

```bash
just bootstrap talos CLUSTER=utility
just bootstrap apps CLUSTER=utility
```

This runs the full pipeline (justfile modules):

1. **`bootstrap talos`** — generates Talos secrets from 1Password, applies topf config, bootstraps K8s, fetches kubeconfig
2. **`bootstrap apps`** — applies namespaces, secrets, CRDs, then syncs helmfile core apps

> **Why two commands?** The `just` bootstrap module separates Talos infrastructure bootstrap (secrets, topf apply, kubeconfig) from K8s apps bootstrap (namespaces, CRDs, helmfile sync). This separation allows debugging Talos issues separately from K8s app issues.

**Verify the utility cluster:**
```bash
# Nodes
kubectl --context utility get nodes

# Namespaces (should see: external-secrets, flux-system, kube-system, kube-tools, network, observability)
kubectl --context utility get ns

# Flux Kustomizations (all should be Ready)
flux -n flux-system get ks --context utility

# Core apps running
kubectl --context utility get pods -A | grep -E "cilium|coredns|flux|external-secrets|onepassword"

# OP connect status
kubectl --context utility get pods -n external-secrets | grep onepassword

# Helmfile sync
helmfile --kube-context utility --file `apps.yaml` diff
```

**Expected working state before proceeding:**
- ✅ All 3 control-plane nodes are Ready
- ✅ cilium, coredns, cert-manager, external-secrets, onepassword-connect are Running
- ✅ Flux operator and instance are reconciled
- ✅ `flux reconcile` shows all Kustomizations Ready
- ✅ No failed pods

**If something fails:**
- Check `talosctl --nodes blade1 get logs` (or `--nodes blade2`, `--nodes blade3`)
- Check `kubectl --context utility describe pod <pod> -n <namespace>`
- Check `op validate` to ensure 1Password login is active
- Re-run `just bootstrap utility` (it's idempotent; the k8s/bootstrap step has an `AlreadyExists` guard)

---

## Step 2 — Bootstrap Test Cluster

```bash
just bootstrap talos CLUSTER=test
just bootstrap apps CLUSTER=test
```

Same pipeline as utility but for the single control-plane node.

**Verify the test cluster:**
```bash
kubectl --context test get nodes
flux -n flux-system get ks --context test
kubectl --context test get pods -A | grep -E "cilium|coredns|flux|external-secrets|onepassword"
```

---

## Step 3 — Bootstrap Main Cluster

Main cluster has 12 nodes (3 control-planes + 7 workers + 2 DGX Spark workers).

> **Note:** DGX Sparks (spark1, spark2) are arm64 Blackwell nodes. Ensure the v1.14.6 arm64 ISO is downloaded from https://factory.talos.dev/ before bootstrapping.

```bash
just bootstrap talos CLUSTER=main
just bootstrap apps CLUSTER=main
```

**Verify the main cluster:**
```bash
kubectl --context main get nodes
flux -n flux-system get ks --context main
kubectl --context main get pods -A | grep -E "cilium|coredns|flux|external-secrets|onepassword|metallb|nginx"
```

---

## Step 4 — Post-Bootstrap Validation

### Cluster Health
```bash
# All 3 clusters should show Ready nodes
kubectl --context utility get nodes
kubectl --context test get nodes
kubectl --context main get nodes

# Flux reconciliation across all clusters
for ctx in utility test main; do
  echo "=== $ctx ==="
  flux -n flux-system get ks --context $ctx
  flux -n flux-system get helmrelease -A --context $ctx 2>/dev/null | head -20
done
```

### ExternalSecrets (OP connectivity)
```bash
for ctx in utility test main; do
  echo "=== $ctx ExternalSecrets ==="
  kubectl --context $ctx get externalsecret -A
  kubectl --context $ctx describe clustersecretstore -n external-secrets onepassword-connect-credentials 2>&1 | head -20
done
```

### App Verification
```bash
# Check that critical apps are deployed in main
kubectl --context main get helmrelease -A | grep -E "cert-manager|external-secrets|cilium|cni"

# Check volsync status
kubectl --context main get replicatedset -A 2>/dev/null || kubectl --context main get replicationdestination -A

# Check CNPG backups
kubectl --context main get backup -A 2>/dev/null || kubectl --context main get postgresql -A
```

---

## Step 5 — Push Configs to 1Password

```bash
just template configure  # Render config files (kubeconfig, talosconfig, etc.)
```

> **Note:** The `op.push` Taskfile task (`Taskfile.yaml`) pushes kubeconfig and talosconfig to 1Password fields: `KUBECONFIG_MAIN`, `KUBECONFIG_UTILITY`, `KUBECONFIG_TEST`, `TALOSCONFIG_MAIN`, `TALOSCONFIG_UTILITY`, `TALOSCONFIG_TEST`, plus combined `KUBECONFIG` and `TALCONFIG` flat files.
>
> **Alternative:** `just template init` — initializes configuration files (cluster.toml, age key, deploy key, webhook token).

---

## Step 6 — Cleanup talos-mixed

Once all 3 clusters are verified working:

1. The `clusters/` directory in `talos-mixed` can be archived or removed
2. The old Jinja-based configs are already removed from `talos-home-ops`
3. Consider archiving the `talos-mixed` repository if it's no longer needed

---

## Rollback Plan

If a cluster fails to bootstrap and needs rollback:

1. The Talos nodes can be manually provisioned using the old `talos-mixed` config files if available
2. volsync/CNPG backups can restore app data to a fresh cluster
3. The `just` bootstrap is idempotent — a second `just bootstrap <CLUSTER>` can be run after fixing issues

---

## Notes

- **Schematic IDs** are set in `talos/topf/<CLUSTER>/topf.yaml`. CM4 blades use `@schematics/cm4-blade.yaml`, NUCs use `@schematics/nuc.yaml`, DGX Sparks use `@schematics/dgx.yaml`
- **Talos version:** v1.14.6 / Kubernetes v1.37.2
- **DGX Sparks:** Download the arm64 ISO from https://factory.talos.dev/ (schematic `@schematics/dgx.yaml`). v1.14.6 is available for DGX Sparks — all other nodes are already running it.
- **Disk encryption:** disabled (`encryptDisk: false`) for all nodes
- **MTU:** 1500 for all nodes
- **`topf`** generates the machine config from `talos/topf/<CLUSTER>/` and applies via `talosctl`
- The `bootstrap.nodes` target uses `--auto-bootstrap --confirm=false` which applies config and reboots nodes into the new cluster

### CM4/Spark NVMe Wipe Safety

> **⚠️ CRITICAL:** CM4 blades and DGX Sparks use NVMe storage where the bootloader lives on the same disk as the OS partitions. Using `--wipe-mode all` wipes the partition table and bootloader, leaving the node un-bootable and requiring a USB reinstall.
>
> **Always use one of these:**
> ```bash
> # Option A: Explicit labels (recommended)
> talosctl reset --nodes <node> --graceful --system-labels-to-wipe STATE --system-labels-to-wipe EPHEMERAL --reboot --wait
>
> # Option B: system-disk mode (equivalent)
> talosctl reset --nodes <node> --graceful --wipe-mode system-disk --reboot --wait
> ```
>
> The `just talos reset-node` wrapper uses Option A. When removing nodes from the old `talos-mixed` cluster, use the explicit commands in Step 0 above.
```
