# Multicluster Migration Plan
## talos-mixed → talos-home-ops

> **Date:** 2026-11-09
> **Branch:** `multicluster-reset` (pushed to origin)
> **Strategy:** Full wipe-and-rebootstrap of all nodes to validate the new process

---

## Pre-Migration Checklist

- [ ] Confirm volsync replication sources are healthy (check `ReplicationSource` resources in apps that use persistent volumes)
- [ ] Confirm CNPG barman backups are current (check `kubectl --context main get backups.postgresql.cnpg.io -n database -o wide` — should show daily completed backups)
- [ ] Ensure 1Password `kubernetes` vault exists with:
  - `OP_SESSION_JSON` field
  - `OP_CONNECT_TOKEN` field
  - `davidstewen-com-tls` secret (tls.crt, tls.key)
- [ ] Ensure `just` is installed on the management node
- [ ] Ensure `talosctl`, `topf`, `op`, `kubectl`, `helmfile`, `minijinja-cli` are available
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

### Main Cluster (ms1-3, blade5-8, nuc1-2)
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

Cluster endpoint: `https://10.200.15.253:6443`

---

## Step 1 — Wipe Utility Nodes (blade1-3)

These nodes are control-planes in `talos-mixed`'s main cluster. Wipe them and they'll be removed from that cluster.

```bash
# blade1
just talos.reset-node main NODE=blade1

# blade2
just talos.reset-node main NODE=blade2

# blade3
just talos.reset-node main NODE=blade3
```

**Verify each node has rebooted into Talos maintenance mode:**
```bash
talosctl --nodes blade1 get health  # should fail — node is no longer in a cluster
talosctl --nodes blade2 get health  # same
talosctl --nodes blade3 get health  # same
```

You should see a Talos CLI prompt at the serial console. If you see a normal shell, the reset didn't work and you may need to run it again or check IPMI.

---

## Step 2 — Bootstrap Utility Cluster

```bash
just bootstrap utility
```

This runs the full pipeline:

1. **`bootstrap.nodes`** — applies topf config to blade1-3, they join the utility cluster
2. **`bootstrap.k8s`** — runs `talosctl bootstrap` on the control plane (waits for KubeAPI)
3. **`bootstrap.kubeconfig`** — generates kubeconfig/talosconfig for `utility` context
4. **`bootstrap.base`** — applies namespaces + secrets (with OP inject) + CRDs
5. **`bootstrap.apps`** — syncs helmfile core apps (cilium, coredns, cert-manager, external-secrets, onepassword-connect, flux-operator, flux-instance)

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
helmfile --kube-context utility --file bootstrap/helmfile/apps.yaml diff
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

## Step 3 — Wipe Test Node (blade4)

```bash
just talos.reset-node main NODE=blade4
```

**Verify maintenance mode:**
```bash
talosctl --nodes blade4 get health  # should fail
```

---

## Step 4 — Bootstrap Test Cluster

```bash
just bootstrap test
```

Same pipeline as utility but for the single control-plane node.

**Verify the test cluster:**
```bash
kubectl --context test get nodes
flux -n flux-system get ks --context test
kubectl --context test get pods -A | grep -E "cilium|coredns|flux|external-secrets|onepassword"
```

---

## Step 5 — Rebootstrap Main Cluster

Main cluster has 10 nodes (3 control-planes + 7 workers). Wipe all of them.

```bash
# Control-planes
just talos.reset-node main NODE=ms1
just talos.reset-node main NODE=ms2
just talos.reset-node main NODE=ms3

# Workers
just talos.reset-node main NODE=blade5
just talos.reset-node main NODE=blade6
just talos.reset-node main NODE=blade7
just talos.reset-node main NODE=blade8
just talos.reset-node main NODE=nuc1
just talos.reset-node main NODE=nuc2
```

**Verify all nodes are in maintenance mode:**
```bash
for node in ms1 ms2 ms3 blade5 blade6 blade7 blade8 nuc1 nuc2; do
  echo -n "$node: "
  talosctl --nodes $node get health 2>&1 | head -1
done
```

---

## Step 6 — Bootstrap Main Cluster

```bash
just bootstrap main
```

**Verify the main cluster:**
```bash
kubectl --context main get nodes
flux -n flux-system get ks --context main
kubectl --context main get pods -A | grep -E "cilium|coredns|flux|external-secrets|onepassword|metallb|nginx"
```

---

## Step 7 — Post-Bootstrap Validation

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

## Step 8 — Push Configs to 1Password

```bash
just op.push
```

This updates `KUBECONFIG_MAIN`, `KUBECONFIG_UTILITY`, `KUBECONFIG_TEST`, `TALOSCONFIG_MAIN`, `TALOSCONFIG_UTILITY`, `TALOSCONFIG_TEST` in the OP vault.

---

## Step 9 — Cleanup talos-mixed

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

- **Schematic IDs** are set in `talos/topf/<CLUSTER>/topf.yaml`. CM4 blades use `de1619e1...`, NUCs use `a2645a18...`, DGX Sparks use `1dd2cbb3...`
- **Talos version:** v1.14.5 / Kubernetes v1.37.1
- **Disk encryption:** disabled (`encryptDisk: false`) for all nodes
- **MTU:** 1500 for all nodes
- **`topf`** generates the machine config from `talos/topf/<CLUSTER>/` and applies via `talosctl`
- The `bootstrap.nodes` target uses `--auto-bootstrap --confirm=false` which applies config and reboots nodes into the new cluster
