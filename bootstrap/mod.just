set no-exit-message
set quiet
set shell := ['bash', '-euo', 'pipefail', '-c']
set script-interpreter := ['bash', '-euo', 'pipefail']
set default-list
set default-script

kubernetes_dir := justfile_dir() + '/kubernetes'

# === Talos bootstrap (per-cluster) ===
# Usage: just bootstrap talos CLUSTER=<cluster>
# where CLUSTER is one of: infra, main, test, utility

[doc('Bootstrap Talos cluster (generates secrets, applies config, fetches kubeconfig)')]
[group('bootstrap')]
talos CLUSTER: talos-generate-secrets talos-apply talos-talosconfig talos-kubeconfig

[private]
talos-generate-secrets CLUSTER:
    just log info "Generating secrets bundle" cluster {{CLUSTER}}
    just talos-secrets generate CLUSTER={{CLUSTER}} > /dev/null

[private]
[working-directory('talos/topf/{{.CLUSTER}}')]
talos-apply CLUSTER:
    just log info "Applying talos config and bootstrapping" cluster {{CLUSTER}}
    topf apply --auto-bootstrap --confirm=false

[private]
[working-directory('talos/topf/{{.CLUSTER}}')]
talos-talosconfig CLUSTER:
    just log info "Generating talosconfig" cluster {{CLUSTER}}
    topf talosconfig > talosconfig

# topf issues short-lived admin certs by default; 8760h keeps the
# kubeconfig usable long-term.
[private]
[working-directory('talos/topf/{{.CLUSTER}}')]
talos-kubeconfig CLUSTER:
    just log info "Fetching kubeconfig" cluster {{CLUSTER}}
    topf kubeconfig --validity 8760h > kubeconfig

# === Apps bootstrap (per-cluster) ===
# Usage: just bootstrap apps CLUSTER=<cluster>

[doc('Bootstrap apps into the Talos cluster')]
[group('bootstrap')]
apps CLUSTER: apps-ready apps-namespaces apps-secrets apps-crds apps-helm
    just log info "Cluster bootstrapped — Flux will start syncing the Git repository" cluster {{CLUSTER}}

[private]
apps-crds CLUSTER:
    just log info "Applying CRDs" cluster {{CLUSTER}}
    if ! helmfile --file "{{ source_directory() }}/bootstrap/helmfile/crds.yaml" template --quiet | \
        yq eval-all --exit-status 'select(.kind == "CustomResourceDefinition")' | \
        kubectl --context {{CLUSTER}} apply --server-side --force-conflicts --filename -; then
        just log fatal "Failed to apply crds"
    fi

[private]
apps-helm CLUSTER:
    just log info "Syncing helmfile" cluster {{CLUSTER}}
    if ! CLUSTER={{CLUSTER}} helmfile --file "{{ source_directory() }}/bootstrap/helmfile/apps.yaml" sync --hide-notes; then
        just log fatal "Failed to sync helmfile"
    fi

[private]
apps-namespaces CLUSTER:
    just log info "Applying namespaces for apps" cluster {{CLUSTER}}
    for app in "{{ kubernetes_dir }}/apps"/*/; do
        ns="$(basename "$app")"
        if kubectl --context {{CLUSTER}} create namespace "$ns" --dry-run=client -o yaml \
                | kubectl --context {{CLUSTER}} apply --server-side --filename - &>/dev/null; then
            just log info "Namespace applied" namespace "$ns"
        else
            just log fatal "Failed to apply namespace" namespace "$ns"
        fi
    done

[private]
apps-secrets CLUSTER:
    just log info "Applying secrets for apps" cluster {{CLUSTER}}
    for secret in \
        "{{ kubernetes_dir }}/kustomize/secrets.yaml.tpl"
    do
        if [ -f "$secret" ]; then
            name="$(basename "$secret" .tpl)"
            minijinja-cli "$secret" | kubectl --context {{CLUSTER}} apply --server-side --filename - &>/dev/null || \
                just log warn "Failed to apply secret" resource "$name"
        fi
    done

[private]
apps-ready CLUSTER:
    just log info "Waiting for nodes to register" cluster {{CLUSTER}}
    deadline=$((SECONDS + 600))
    until kubectl --context {{CLUSTER}} wait nodes --for=condition=Ready=True --all --timeout=10s &>/dev/null; do
        if (( SECONDS >= deadline )); then
            just log fatal "Timed out waiting for nodes to register"
        fi
        just log info "Nodes not available, waiting. Retrying in 5 seconds..."
        sleep 5
    done
