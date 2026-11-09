set quiet
set shell := ['bash', '-euo', 'pipefail', '-c']
set script-interpreter := ['bash', '-euo', 'pipefail']
set default-list
set default-script

# === Talos operations (per-cluster) ===
# Usage: just talos <command> CLUSTER=<cluster>
# where CLUSTER is one of: infra, main, test, utility

# === Per-cluster operations ===
# Most tasks take CLUSTER=<cluster> as first parameter
# Some also take NODE=<nodename> to target specific nodes

[doc('List cluster nodes and their current state [CLUSTER=main]')]
[group('talos')]
nodes CLUSTER:
    just log info "Listing nodes" cluster {{CLUSTER}}
    [ -f "talos/topf/{{.CLUSTER}}/talosconfig" ] || (
        just log warn "No talosconfig found, generating..."
        cd talos/topf/{{.CLUSTER}} && topf talosconfig && cd -
    )
    topf --talosconfig talos/topf/{{.CLUSTER}}/talosconfig nodes --config talos/topf/{{.CLUSTER}}/topf.yaml

[doc('Apply Talos config to a node [CLUSTER=main] [NODE=required]')]
[group('talos')]
apply-node CLUSTER NODE:
    just log info "Applying Talos config" cluster {{CLUSTER}} node {{NODE}}
    if [ -f "talos/topf/{{.CLUSTER}}/talosconfig" ]; then
        minijinja-cli "talos/topf/{{.CLUSTER}}/machineconfig.yaml.j2" 2>/dev/null || true
        talosctl --nodes {{.NODE}} apply-config --mode auto --talosconfig "talos/topf/{{.CLUSTER}}/talosconfig"
    else
        just log fatal "No talosconfig found for cluster {{.CLUSTER}}"
    fi

[doc('Upgrade Talos on a node [CLUSTER=main] [NODE=required] [VERSION=required]')]
[group('talos')]
upgrade-node CLUSTER NODE VERSION:
    just log info "Upgrading Talos" cluster {{CLUSTER}} node {{NODE}} version {{VERSION}}
    talosctl --talosconfig "talos/topf/{{.CLUSTER}}/talosconfig" --nodes {{.NODE}} upgrade --image=talos:v{{.VERSION}} --timeout=10m

[doc('Upgrade Kubernetes across the cluster [CLUSTER=main] [VERSION=required]')]
[group('talos')]
upgrade-k8s CLUSTER VERSION:
    just log info "Upgrading Kubernetes" cluster {{CLUSTER}} version {{VERSION}}
    talosctl --talosconfig "talos/topf/{{.CLUSTER}}/talosconfig" --nodes {{.NODES}} upgrade-k8s --to {{.VERSION}}
    vars:
        NODES:
            sh: kubectl --context {{.CLUSTER}} get nodes --no-headers --output=jsonpath='{.items[0].metadata.name}'

[doc('Reset Talos on a node [CLUSTER=main] [NODE=required]')]
[group('talos')]
reset-node CLUSTER NODE:
    just log info "Resetting Talos node" cluster {{CLUSTER}} node {{NODE}}
    talosctl --talosconfig "talos/topf/{{.CLUSTER}}/talosconfig" reset --nodes {{.NODE}} --graceful=false --reboot

[doc('Generate kubeconfig for cluster [CLUSTER=main]')]
[group('talos')]
kubeconfig CLUSTER:
    just log info "Generating kubeconfig" cluster {{CLUSTER}}
    if [ -f "talos/topf/{{.CLUSTER}}/talosconfig" ]; then
        talosctl kubeconfig --talosconfig "talos/topf/{{.CLUSTER}}/talosconfig" --nodes "$(kubectl --context {{.CLUSTER}} get nodes --no-headers -o custom-columns=NAME:.metadata.name | head -1)" "{{.ROOT_DIR}}/kubeconfig-{{.CLUSTER}}"
    else
        just log fatal "No talosconfig found for cluster {{.CLUSTER}}"
    fi

[doc('Render Talos machine configs to output/ directory [CLUSTER=main]')]
[group('talos')]
render CLUSTER:
    just log info "Rendering Talos configs" cluster {{CLUSTER}}
    cd "talos/topf/{{.CLUSTER}}" && topf render --config topf.yaml --output output
    just log info "Rendered configs are in talos/topf/{{.CLUSTER}}/output/"

[doc('Show what an apply would change (dry run) [CLUSTER=main]')]
[group('talos')]
diff CLUSTER:
    just log info "Diffing Talos config" cluster {{CLUSTER}}
    cd "talos/topf/{{.CLUSTER}}" && topf apply --dry-run --config topf.yaml
