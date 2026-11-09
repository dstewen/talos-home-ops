#!just
# yaml-language-server: $schema=https://just.systems/schema.json

set          default
set          export-vars
set          fallback
set          ignore-errors
set          include-dotenv
set          positional-prefix := '::'
set          shell := ['bash', '-euo', 'pipefail', '-c']
set          shell-command := false
set          silence-all := true

# ============================================================================
# Vars
# ============================================================================

CLUSTERS := ['main', 'utility', 'test']
CLUSTER  := 'main'
ROOT_DIR := justfile_dir()
BOOTSTRAP_DIR := ROOT_DIR + '/bootstrap'
TALOS_DIR := ROOT_DIR + '/talos/' + CLUSTER
KUBERNETES_DIR := ROOT_DIR + '/kubernetes'
KUBECONFIG := KUBERNETES_DIR + '/clusters/' + CLUSTER + '/kubeconfig'
TALOSCONFIG := TALOS_DIR + '/talosconfig'

# ============================================================================
# Group: bootstrap — Full cluster bootstrap (talos → k8s → kubeconfig → base → apps)
# ============================================================================

# Bootstrap a full Talos + Kubernetes cluster
# Usage: just bootstrap utility | just bootstrap test | just bootstrap main
bootstrap: CLUSTER ?= 'main'
    echo "Bootstrap cluster {{ CLUSTER }}"
    just bootstrap.nodes {{ CLUSTER }}
    just bootstrap.k8s {{ CLUSTER }}
    just bootstrap.kubeconfig {{ CLUSTER }}
    just bootstrap.base {{ CLUSTER }}
    just bootstrap.apps {{ CLUSTER }}

[private]
bootstrap.nodes: CLUSTER ?= 'main'
    "Apply Talos config to all nodes in {{ CLUSTER }}"
    topf apply --auto-bootstrap --confirm=false --config {{ TALOS_DIR }}/topf.yaml --talos-dir {{ TALOS_DIR }}

[private]
bootstrap.k8s: CLUSTER ?= 'main'
    "Bootstrap Kubernetes via Talos"
    until out=$(talosctl --talosconfig {{ TALOSCONFIG }} bootstrap 2>&1 || true) && [[ "$out" == *"AlreadyExists"* ]]; do
        echo "Kubernetes bootstrap in progress, retrying in 5s..."
        sleep 5
    done

[private]
bootstrap.kubeconfig: CLUSTER ?= 'main'
    "Generate kubeconfig for {{ CLUSTER }}"
    mkdir -p {{ KUBERNETES_DIR }}/clusters/{{ CLUSTER }}
    talosctl --talosconfig {{ TALOSCONFIG }} kubeconfig --nodes "$(talosctl --talosconfig {{ TALOSCONFIG }} config info --output yaml | yq -r '.endpoints[0]')" \
        -f --force-context-name {{ CLUSTER }} {{ KUBERNETES_DIR }}/clusters/{{ CLUSTER }}

[private]
bootstrap.base: CLUSTER ?= 'main'
    "Apply base manifests (namespaces + secrets + CRDs) for {{ CLUSTER }}"
    "Waiting for nodes to register..."
    until kubectl --context {{ CLUSTER }} get nodes --no-headers 2>/dev/null | grep -q .; do
        echo "Waiting for nodes to register..."
        sleep 5
    done
    "Applying namespaces + secrets..."
    minijinja-cli {{ BOOTSTRAP_DIR }}/secrets/{{ CLUSTER }}.yaml.tpl | op inject | kubectl --context {{ CLUSTER }} apply --server-side --force-conflicts --filename -
    "Applying CRDs..."
    helmfile --file {{ BOOTSTRAP_DIR }}/helmfile/crds.yaml template | yq ea -r -e 'select(.kind == "CustomResourceDefinition")' | kubectl --context {{ CLUSTER }} apply --server-side --field-manager bootstrap --force-conflicts --filename -

[private]
bootstrap.apps: CLUSTER ?= 'main'
    "Sync bootstrap applications via helmfile for {{ CLUSTER }}"
    helmfile --kube-context {{ CLUSTER }} --file {{ BOOTSTRAP_DIR }}/helmfile/apps.yaml sync --hide-notes

# ============================================================================
# Group: talos — Talos node management
# ============================================================================

# Apply Talos config to a node
# Usage: just talos.apply-node utility NODE=blade1
talos.apply-node: CLUSTER ?= 'main' NODE ?= ''
    "Apply Talos config to {{ NODE }} in {{ CLUSTER }}"
    topf apply --config {{ TALOS_DIR }}/topf.yaml --nodes {{ NODE }} --talos-dir {{ TALOS_DIR }} --op inject

# Reset a Talos node
# Usage: just talos.reset-node main NODE=blade1
talos.reset-node: CLUSTER ?= 'main' NODE ?= ''
    "Reset Talos node {{ NODE }} in {{ CLUSTER }}"
    talosctl --talosconfig {{ TALOSCONFIG }} reset --nodes {{ NODE }} --system-labels-to-wipe STATE --system-labels-to-wipe EPHEMERAL --graceful=false --reboot

# Reset the whole cluster
# Usage: just talos.reset-cluster main
talos.reset-cluster: CLUSTER ?= 'main'
    "Reset Talos cluster {{ CLUSTER }}"
    NODES=$(talosctl --talosconfig {{ TALOSCONFIG }} config info --output json | jq --join-output '[.nodes[]] | join(",")')
    talosctl --talosconfig {{ TALOSCONFIG }} reset --nodes "$NODES" --graceful=false --reboot

# Upgrade Kubernetes across the cluster
# Usage: just talos.upgrade-k8s main VERSION=v1.38.0
talos.upgrade-k8s: CLUSTER ?= 'main' VERSION ?= ''
    "Upgrade Kubernetes to {{ VERSION }}"
    talosctl --talosconfig {{ TALOSCONFIG }} upgrade-k8s --to {{ VERSION }}

# Reboot a single node
# Usage: just talos.reboot-node main NODE=blade1
talos.reboot-node: CLUSTER ?= 'main' NODE ?= ''
    "Reboot {{ NODE }} in {{ CLUSTER }}"
    talosctl --nodes {{ NODE }} reboot --talosconfig {{ TALOSCONFIG }}

# ============================================================================
# Group: kube — Kubernetes operations
# ============================================================================

# Merge kubeconfigs into a single unified config (~/.kube/config)
kube.merge-configs:
    "Merge all cluster kubeconfigs into ~/.kube/config"
    mkdir -p ~/.kube
    for cluster in {{ CLUSTERS | join " " }}; do
        if [ -f {{ KUBERNETES_DIR }}/clusters/$$cluster/kubeconfig ]; then
            KUBECONFIG={{ KUBERNETES_DIR }}/clusters/$$cluster/kubeconfig kubectl config view --flatten --merge > /tmp/kubeconfig-merge-$$$$.yaml
            if [ -f ~/.kube/config ]; then
                KUBECONFIG=~/.kube/config /usr/bin/env python3 -c "
import yaml, sys
with open(sys.argv[1]) as f:
    cfg1 = yaml.safe_load(f)
with open(sys.argv[2]) as f:
    cfg2 = yaml.safe_load(f)
# Merge clusters, contexts, users
cfg1['clusters'] = {k: v for k, v in {**cfg2.get('clusters', []), **{c['name']: c for c in cfg1.get('clusters', [])}}.items()}
cfg1['contexts'] = {k: v for k, v in {**cfg2.get('contexts', []), **{c['name']: c for c in cfg1.get('contexts', [])}}.items()}
cfg1['users'] = {k: v for k, v in {**cfg2.get('users', []), **{u['name']: u for u in cfg1.get('users', [])}}.items()}
if 'current-context' in cfg2:
    cfg1['current-context'] = cfg2['current-context']
with open(sys.argv[1], 'w') as f:
    yaml.dump(cfg1, f)
" ~/.kube/config /tmp/kubeconfig-merge-$$$$.yaml
            else
                cp /tmp/kubeconfig-merge-$$$$.yaml ~/.kube/config
            fi
            rm /tmp/kubeconfig-merge-$$$$.yaml
        fi
    done

# Merge talosconfigs into a single unified config (~/.talos/config)
kube.merge-talos:
    "Merge all cluster talosconfigs into ~/.talos/config"
    mkdir -p ~/.talos
    for cluster in {{ CLUSTERS | join " " }}; do
        if [ -f {{ TALOS_DIR }}/$$cluster/talosconfig ]; then
            talosctl --talosconfig {{ TALOS_DIR }}/$$cluster/talosconfig config merge {{ TALOS_DIR }}/$$cluster/talosconfig > /tmp/talosconfig-merge-$$$$.yaml
            if [ -f ~/.talos/config ]; then
                mv /tmp/talosconfig-merge-$$$$.yaml ~/.talos/config
            else
                mv /tmp/talosconfig-merge-$$$$.yaml ~/.talos/config
            fi
        fi
    done

# Apply a Flux Kustomization
# Usage: just kube.apply-ks main PATH=cert-manager
kube.apply-ks: CLUSTER ?= 'main' PATH ?= ''
    "Apply Kustomization {{ PATH }} for {{ CLUSTER }}"
    flux build --namespace flux-system ks {{ PATH }} \
        --kustomization-file {{ KUBERNETES_DIR }}/apps/{{ CLUSTER }}/{{ PATH }} \
        --path {{ KUBERNETES_DIR }}/apps/{{ CLUSTER }}/{{ PATH }} \
        | yq 'with(select(.apiVersion == "kustomize.toolkit.fluxcd.io/v1" and .kind == "Kustomization"); .metadata.namespace = "flux-system")' - | kubectl apply --server-side --field-manager=kustomize-controller --filename -

# Force Flux reconciliation
# Usage: just kube.reconcile main
kube.reconcile: CLUSTER ?= 'main'
    "Force Flux reconciliation for {{ CLUSTER }}"
    flux get ks --no-header -n flux-system --context {{ CLUSTER }} | awk '{print $1, $2}' | xargs -L1 flux reconcile ks -n flux-system --context {{ CLUSTER }}
    flux get ks --all-namespaces --no-header --context {{ CLUSTER }} | awk '{print $1, $2}' | xargs -L1 flux reconcile ks -n $$1 --context {{ CLUSTER }}

# Sync all ExternalSecrets
# Usage: just kube.sync-secrets main
kube.sync-secrets: CLUSTER ?= 'main'
    "Sync all ExternalSecrets in {{ CLUSTER }}"
    SECRETS=$(kubectl get externalsecret --all-namespaces --no-headers --output=jsonpath='{range .items[*]}{.metadata.namespace},{.metadata.name}{"\n"}{end}' --context {{ CLUSTER }})
    echo "$SECRETS" | while IFS=',' read -r ns name; do
        kubectl --namespace "$ns" annotate externalsecret "$name" force-sync="$(date +%s)" --overwrite --context {{ CLUSTER }}
    done

# Restart failed HelmReleases
# Usage: just kube.hr-restart main
kube.hr-restart: CLUSTER ?= 'main'
    "Restart failed HelmReleases in {{ CLUSTER }}"
    kubectl get hr --all-namespaces --context {{ CLUSTER }} | grep False | awk '{print $1, $2}' | while read -r ns hr; do
        flux suspend hr -n "$ns" "$hr" --context {{ CLUSTER }}
        flux resume hr -n "$ns" "$hr" --context {{ CLUSTER }}
    done

# Delete failed/pending pods
# Usage: just kube.delete-failed-pods main
kube.delete-failed-pods: CLUSTER ?= 'main'
    "Delete failed pods in {{ CLUSTER }}"
    kubectl --context {{ CLUSTER }} delete pods --field-selector status.phase=Failed -A --ignore-not-found=true
    kubectl --context {{ CLUSTER }} delete pods --field-selector status.phase=Pending -A --ignore-not-found=true

# Open a shell on a node
# Usage: just kube.node-shell main NODE=blade1
kube.node-shell: CLUSTER ?= 'main' NODE ?= ''
    "Shell on {{ NODE }} in {{ CLUSTER }}"
    kubectl node-shell -n kube-system -x {{ NODE }}

# Browse a PVC
# Usage: just kube.browse-pvc main CLAIM=my-pvc
kube.browse-pvc: CLUSTER ?= 'main' CLAIM ?= ''
    "Browse PVC {{ CLAIM }} in {{ CLUSTER }}"
    kubectl browse-pvc --namespace default --image docker.io/library/alpine:latest {{ CLAIM }}

# Suspend or resume Kustomizations
# Usage: just kube.ks-suspend main | just kube.ks-resume main
kube.ks-suspend: CLUSTER ?= 'main'
    "Suspend all Kustomizations in {{ CLUSTER }}"
    flux suspend ks --all --namespace flux-system --context {{ CLUSTER }}

kube.ks-resume: CLUSTER ?= 'main'
    "Resume all Kustomizations in {{ CLUSTER }}"
    flux resume ks --all --namespace flux-system --context {{ CLUSTER }}

# ============================================================================
# Group: onepassword — 1Password operations
# ============================================================================

# Validate 1Password login
op.validate:
    "Validate 1Password login"
    op account get

# Push kubeconfig/talosconfig for all clusters to 1Password
op.push:
    "Push configs to 1Password"
    for cluster in {{ CLUSTERS | join " " }}; do
        op item edit kubernetes KUBECONFIG_$(echo "$cluster" | tr '[:lower:]' '[:upper:]')[text]="$(cat {{ KUBERNETES_DIR }}/clusters/$cluster/kubeconfig)" 2>/dev/null
        op item edit kubernetes TALOSCONFIG_$(echo "$cluster" | tr '[:lower:]' '[:upper:]')[text]="$(cat {{ TALOS_DIR }}/$cluster/talosconfig)" 2>/dev/null
    done

# Pull kubeconfig/talosconfig from 1Password
op.pull:
    "Pull configs from 1Password"
    mkdir -p {{ KUBERNETES_DIR }}/clusters ~/.kube ~/.talos
    for cluster in {{ CLUSTERS | join " " }}; do
        op item get kubernetes --fields label=KUBECONFIG_$(echo "$cluster" | tr '[:lower:]' '[:upper:]') | tr -d '"' > {{ KUBERNETES_DIR }}/clusters/$cluster/kubeconfig
        op item get kubernetes --fields label=TALOSCONFIG_$(echo "$cluster" | tr '[:lower:]' '[:upper:]') | tr -d '"' > {{ TALOS_DIR }}/$cluster/talosconfig
    done

# ============================================================================
# Group: workstation — Local setup
# ============================================================================

# Install workstation tools (Homebrew, Krew)
workstation.setup:
    "Install workstation tools"
    brew bundle --file {{ BOOTSTRAP_DIR }}/resources/Brewfile
    kubectl krew install cert-manager cnpg browse-pvc node-shell rook-ceph view-secret

# ============================================================================
# Group: validate
# ============================================================================

# Validate cluster config locally
# Usage: just validate main
validate: CLUSTER ?= 'main'
    "Validate {{ CLUSTER }} config"
    flate test all --path {{ KUBERNETES_DIR }}/clusters/{{ CLUSTER }}

# ============================================================================
# Default
# ============================================================================

# List all commands
default:
    just --list
