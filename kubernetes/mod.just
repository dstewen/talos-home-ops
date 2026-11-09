set quiet
set shell := ['bash', '-euo', 'pipefail', '-c']
set script-interpreter := ['bash', '-euo', 'pipefail']
set default-list
set default-script

# === Flux operations (per-cluster) ===
# Usage: just kube reconcile CLUSTER=<cluster>
# where CLUSTER is one of: infra, main, test, utility (defaults to main)

[doc('Force Flux to pull in changes for cluster [CLUSTER=main]')]
[group('kube')]
reconcile CLUSTER='main':
    just log info "Reconciling Flux" cluster {{CLUSTER}}
    flux --context {{CLUSTER}} --namespace flux-system reconcile kustomization flux-system --with-source
    flux get ks --all-namespaces --context {{CLUSTER}} --no-header | \
        awk '{print $1, $2}' | xargs -L1 bash -c 'flux reconcile ks -n $0 $1 --context {{CLUSTER}}'

[doc('Suspend Kustomizations for cluster [CLUSTER=main]')]
[group('kube')]
suspend CLUSTER='main':
    just log info "Suspending Kustomizations" cluster {{CLUSTER}}
    flux --context {{CLUSTER}} --namespace flux-system suspend kustomization flux-system --with-source
    flux get ks --all-namespaces --context {{CLUSTER}} --no-header | \
        awk '{print $1, $2}' | xargs -L1 bash -c 'flux suspend ks -n $0 $1 --context {{CLUSTER}}'

[doc('Resume Kustomizations for cluster [CLUSTER=main]')]
[group('kube')]
resume CLUSTER='main':
    just log info "Resuming Kustomizations" cluster {{CLUSTER}}
    flux --context {{CLUSTER}} --namespace flux-system resume kustomization flux-system --with-source
    flux get ks --all-namespaces --context {{CLUSTER}} --no-header | \
        awk '{print $1, $2}' | xargs -L1 bash -c 'flux resume ks -n $0 $1 --context {{CLUSTER}}'

[doc('Restart all failed Helm Releases for cluster [CLUSTER=main]')]
[group('kube')]
hr-restart CLUSTER='main':
    just log info "Restarting failed HelmReleases" cluster {{CLUSTER}}
    flux --context {{CLUSTER}} suspend hr --all --all-namespaces || true
    sleep 2
    flux --context {{CLUSTER}} reconcile hr --all --all-namespaces

[doc('Force update a specific Flux Kustomization [CLUSTER=main] [KS=required]')]
[group('kube')]
reconcile-ks CLUSTER KS:
    just log info "Reconciling Kustomization" cluster {{CLUSTER}} kustomization {{KS}}
    flux --context {{CLUSTER}} reconcile ks {{KS}}

[doc('Get Flux Kustomization status for cluster [CLUSTER=main]')]
[group('kube')]
ks-status CLUSTER='main':
    flux get ks --all-namespaces --context {{CLUSTER}}

[doc('Get Flux HelmRelease status for cluster [CLUSTER=main]')]
[group('kube')]
hr-status CLUSTER='main':
    flux get hr --all-namespaces --context {{CLUSTER}}
