Read

Read

Read , lines 1 to 50

Read



Searched for text `op.env`, 10 results

Fetched https://github.com/dstewen/talos-mixed



Good question. Here's the comparison:

## talos-home-ops: 1Password Direct (No SOPS)

The flow is:

```
1Password → op run → envsubst → topf apply
```

1. **Template**: `talsecret.yaml` contains `${talos_*}` placeholders
2. **Mapping**: `.justfiles/talos/op.env` maps each `${talos_*}` variable to a `op://$VAULT/talos/CLUSTER_field` reference
3. **Rendering**: `op run --env-file=op.env` resolves all `op://` references into env vars, then `envsubst` fills the template
4. **topf**: The `secretsProvider` script in `topf.yaml` calls `$0 secrets get <cluster>` which runs the same pipeline
5. **Result**: The rendered Talos config has real secrets inline — nothing encrypted in Git

The `secrets-provider` script **refuses** `secrets put` — it won't write back to 1Password. The bundle must be created manually in 1Password first.

## talos-mixed: SOPS Encrypted Files

```
SOPS (age key) → encrypted YAML files → git commit
```

In `talos-mixed`, secrets are stored as **SOPS-encrypted YAML files** committed to Git:
- `talos/secrets.sops.yaml` — Talos cluster secrets
- `bootstrap/**/*.sops.*` — Bootstrap secrets
- `kubernetes/**/*.sops.*` — App secrets

SOPS encrypts with an **age key** stored locally. When you run `just configure`, it decrypts the SOPS files to render configs, then re-encrypts before committing.

## Do Talos Secrets Need to Pre-exist in 1Password?

**Yes.** The `secrets-provider` only does `get` — it reads from 1Password, never writes. You need to create the 1Password item **before** bootstrapping.

### Required 1Password Item

**Vault**: `Kubernetes`
**Item name**: `talos`
**Type**: `Password` (with generated fields)

**Per-cluster fields** (one set per cluster):

| Field Name | Description |
|---|---|
| `utility_id` | Talos cluster ID |
| `utility_secret` | Talos cluster secret |
| `utility_secrets/bootstrap_token` | Bootstrap token |
| `utility_secrets/secretbox_encryption_secret` | Secretbox encryption key (32-byte hex) |
| `utility_trustdinfo/token` | Trustd info token |
| `utility_certs_etcd/cert` | etcd certificate (PEM) |
| `utility_certs_etcd/key` | etcd private key (PEM) |
| `utility_certs_k8s/cert` | Kubernetes API certificate (PEM) |
| `utility_certs_k8s/key` | Kubernetes API private key (PEM) |
| `utility_certs_k8saggregator/cert` | K8s aggregator certificate (PEM) |
| `utility_certs_k8saggregator/key` | K8s aggregator private key (PEM) |
| `utility_certs_k8sserviceaccount/key` | Service account signing key |
| `utility_certs_os/cert` | OS certificate (PEM) |
| `utility_certs_os/key` | OS private key (PEM) |

Plus `main_*` and `test_*` variants for those clusters.

### How to Create Them

You'd generate the Talos secrets bundle first (e.g., from an existing cluster or a fresh `talosctl gen`), extract the values, then create the 1Password item with those values as fields. The `just talos-secrets verify CLUSTER=utility` command will tell you if all fields are present and accessible.

**The key difference from SOPS**: with SOPS, the secrets live in Git (encrypted). With 1Password, they live in 1Password and are never committed. The `op.env` file in Git only contains `op://` references — no actual secret values.
