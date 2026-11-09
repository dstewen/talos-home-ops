# Secret management for Talos clusters.
# Each cluster's secrets live in a single 1Password item named `talos`
# in the Kubernetes vault, with per-cluster fields: {cluster}_<field>.
#
# 1Password structure:
#   Vault: Kubernetes
#   Item: talos
#   Fields:
#     infra_id, infra_secret, infra_secrets/bootstrap_token,
#     infra_secrets/secretbox_encryption_secret, infra_trustdinfo/token,
#     infra_certs_etcd/cert, infra_certs_etcd/key,
#     infra_certs_k8s/cert, infra_certs_k8s/key,
#     infra_certs_k8saggregator/cert, infra_certs_k8saggregator/key,
#     infra_certs_k8sserviceaccount/key, infra_certs_os/cert, infra_certs_os/key
#     main_*, test_*, utility_* (same pattern)
#
# Usage: just talos-secrets <command> CLUSTER=<cluster>

set quiet
set shell := ['bash', '-euo', 'pipefail', '-c']
set script-interpreter := ['bash', '-euo', 'pipefail']

# === Generate secrets bundle ===
# Renders the 1Password-referenced talsecret.yaml with actual values resolved.
# This is what topf uses at build time.

[doc('Generate the secrets bundle for cluster [CLUSTER=main]')]
[group('talos-secrets')]
generate CLUSTER:
    just log info "Generating secrets bundle" cluster {{CLUSTER}}
    CLUSTER={{CLUSTER}} \
      op run --env-file="{{ source_directory() }}/.justfiles/talos/op.env" --no-masking -- \
      envsubst < "{{ source_directory() }}/.justfiles/talos/talsecret.yaml"

# === Verify secrets ===
# Checks that 1Password is reachable and all fields exist for the cluster.

[doc('Verify 1Password access for cluster secrets [CLUSTER=main]')]
[group('talos-secrets')]
verify CLUSTER:
    just log info "Verifying 1Password access" cluster {{CLUSTER}}
    @echo "Checking op account..."
    op account get
    @echo "Checking {{.CLUSTER}}-talos fields in 1Password..."
    CLUSTER={{CLUSTER}} op run --env-file="{{ source_directory() }}/.justfiles/talos/op.env" --no-masking -- \
      envsubst < "{{ source_directory() }}/.justfiles/talos/talsecret.yaml" > /dev/null
    just log info "Verified" cluster {{CLUSTER}}

# === Show rendered secrets ===
# Like generate, but also shows which 1Password references were resolved.
# Useful for debugging when secrets don't seem to match.

[doc('Show rendered secrets bundle (debug) [CLUSTER=main]')]
[group('talos-secrets')]
show CLUSTER:
    just log info "Showing rendered secrets" cluster {{CLUSTER}}
    @echo "=== 1Password references ==="
    cat "{{ source_directory() }}/.justfiles/talos/op.env"
    @echo ""
    @echo "=== Rendered talsecret.yaml ==="
    CLUSTER={{CLUSTER}} \
      op run --env-file="{{ source_directory() }}/.justfiles/talos/op.env" --no-masking -- \
      envsubst < "{{ source_directory() }}/.justfiles/talos/talsecret.yaml"
