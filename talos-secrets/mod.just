set quiet
set shell := ['bash', '-euo', 'pipefail', '-c']
set script-interpreter := ['bash', '-euo', 'pipefail']

# Secret management for Talos clusters.
# Each cluster has a 1Password item named <cluster>-talos containing the
# Talos secrets bundle (id, secret, certs, tokens).
#
# The secretsProvider (topf) fetches the bundle at build time from 1Password,
# so nothing secret is stored in the repo.
#
# Usage: just talos-secrets <command> CLUSTER=<cluster>

# === Generate secrets bundle ===
# Renders the 1Password-referenced talsecret.yaml with actual values resolved.
# This is what topf uses at build time.
# Outputs to stdout. Redirect to file if needed for review.

[doc('Generate the secrets bundle for cluster [CLUSTER=main]')]
[group('talos-secrets')]
generate CLUSTER:
    just log info "Generating secrets bundle" cluster {{CLUSTER}}
    CLUSTER={{CLUSTER}} \
      op run --env-file="{{ source_directory() }}/.justfiles/talos/op.env" --no-masking -- \
      envsubst < "{{ source_directory() }}/.justfiles/talos/talsecret.yaml"

# === Verify secrets ===
# Checks that 1Password is reachable and the cluster's secrets item exists.
# Useful for CI or pre-flight checks before applying configs.

[doc('Verify 1Password access for cluster secrets [CLUSTER=main]')]
[group('talos-secrets')]
verify CLUSTER:
    just log info "Verifying 1Password access" cluster {{CLUSTER}}
    @echo "Checking op account..."
    op account get
    @echo "Checking {{.CLUSTER}}-talos item in 1Password..."
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
