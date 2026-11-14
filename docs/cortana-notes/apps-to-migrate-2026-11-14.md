

I'll go namespace by namespace. Let me start with `actions-runner-system`.







Read

Read

Read

Read

Searched dstewen/talos-mixed for "kubernetes/apps/actions-runner-system/", 1 result

Read



**actions-runner-system** — ✅ Match found

| App | NS_Mixed | NS_New | CLUSTER | KS Exists? |
|---|---|---|---|---|
| actions-runner-controller | actions-runner-system | actions-runner-system | main, utility, test | ✅ |

Structure mapping:
- talos-mixed: `kubernetes/apps/actions-runner-system/actions-runner-controller/app/`
- talos-home-ops: `app`

Same namespace, same app. Let me continue with the next namespace.







Read

Read

Read

Read

Searched dstewen/talos-mixed for "kubernetes/apps/cert-manager/", 2 results



**cert-manager** — ✅ Match found

| App | NS_Mixed | NS_New | CLUSTER | KS Exists? |
|---|---|---|---|---|
| cert-manager | cert-manager | cert-manager | main, utility, test | ✅ |

Let me continue with the next namespace.







Read

Read

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/utility/database'

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/test/database'

Searched dstewen/talos-mixed for "kubernetes/apps/database/", 7 results



**database** — ⚠️ Partial match

| App | NS_Mixed | NS_New | CLUSTER | KS Exists? |
|---|---|---|---|---|
| cloudnative-pg | database | database | main | ✅ |
| dragonfly | database | database | main | ✅ |
| plugin-barman-cloud | database | database | — | ❌ MISSING |
| valkey | database | database | — | ❌ MISSING |
| pgadmin | database | database | — | ❌ MISSING |
| influxdb3 | database | database | — | ❌ MISSING |

Missing from talos-home-ops: **plugin-barman-cloud, valkey, pgadmin, influxdb3**

Let me continue with the next namespace.







Read

Read

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/utility/downloads'

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/test/downloads'

Searched dstewen/talos-mixed for "kubernetes/apps/downloads/", no results



No downloads namespace in talos-mixed — it's under `media/`. Let me check that.



Searched dstewen/talos-mixed for "kubernetes/apps/media/", 21 results



**downloads** — ⚠️ Namespace split in talos-home-ops

In talos-mixed, these apps live in `media/` namespace. In talos-home-ops, they're split into `downloads/` and `media/`.

| App | NS_Mixed | NS_New | CLUSTER | KS Exists? |
|---|---|---|---|---|
| autobrr | media | downloads | main | ✅ |
| bazarr | media | downloads | main | ✅ |
| brrpolice | media | downloads | main | ✅ |
| cleanrr | media | downloads | main | ✅ |
| decluttarr | media | downloads | main | ✅ |
| flaresolverr | media | downloads | main | ✅ |
| kapowarr | media | downloads | main | ✅ |
| metube | media | downloads | main | ✅ |
| mylar | media | downloads | main | ✅ |
| pinchflat | media | downloads | main | ✅ |
| prowlarr | media | downloads | main | ✅ |
| qbittorrent | media | downloads | main | ✅ |
| qui | media | downloads | main | ✅ |
| radarr | media | downloads | main | ✅ |
| recyclarr | media | downloads | main | ✅ |
| sabnzbd | media | downloads | main | ✅ |
| sonarr | media | downloads | main | ✅ |
| tdarr | media | downloads | ✅ |
| tdarr-node | media | downloads | main | ✅ |

Now let me check what's in talos-home-ops `media/` namespace:






Read

Read

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/utility/media'

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/test/media'



**media** — ⚠️ Namespace split + different apps

In talos-mixed, all media apps are in `media/` namespace. In talos-home-ops, they're split into `downloads/` and `media/`.

| App | NS_Mixed | NS_New | CLUSTER | KS Exists? |
|---|---|---|---|---|
| plex | media | media | main | ✅ |
| tdarr | media | downloads | main | ✅ |
| seerr | media | media | main | ✅ |
| sonarr | media | downloads | main | ✅ |
| bazarr | media | downloads | main | ✅ |
| immich | media | — | — | ❌ MISSING |
| radarr | media | downloads | main | ✅ |
| lidarr | media | — | — | ❌ MISSING |
| calibre | media | — | — | ❌ MISSING |
| sabnzbd | media | downloads | main | ✅ |
| prowlarr | media | downloads | main | ✅ |
| whisparr | media | — | — | ❌ MISSING |
| tautulli | media | media | main | ✅ |
| paperless | media | — | — | ❌ MISSING |
| recyclarr | media | downloads | main | ✅ |
| radarr-uhd | media | — | — | ❌ MISSING |
| sonarr-uhd | media | — | — | ❌ MISSING |
| maintainerr | media | media | main | ✅ |
| calibre-web | media | — | — | ❌ MISSING |
| qbittorrent | media | downloads | main | ✅ |
| paperless-scan | media | — | — | ❌ MISSING |

**talos-home-ops media/ has apps NOT in talos-mixed:**
- ersatztv, kavita, komga, kyoo, stash, wizarr, your-spotify

Let me continue with the next namespace.







Read

Read

Read

Read

Searched dstewen/talos-mixed for "kubernetes/apps/external-secrets/", 2 results



**external-secrets** — ✅ Match found

| App | NS_Mixed | NS_New | CLUSTER | KS Exists? |
|---|---|---|---|---|
| external-secrets | external-secrets | external-secrets | main, utility, test | ✅ |
| onepassword-connect | external-secrets | external-secrets | main, utility, test | ✅ |

Let me continue with the next namespace.







Read

Read

Read

Read

Searched dstewen/talos-mixed for "kubernetes/apps/flux-system/", 6 results



**flux-system** — ⚠️ Partial match

| App | NS_Mixed | NS_New | CLUSTER | KS Exists? |
|---|---|---|---|---|
| flux-operator | flux-system | flux-system | main, utility, test | ✅ |
| flux-instance | flux-system | flux-system | — | ❌ MISSING |
| headlamp | flux-system | flux-system | main, utility, test | ✅ |
| konflate | flux-system | flux-system | main, utility, test | ✅ |

Missing from talos-home-ops: **flux-instance** (expected - Flux is bootstrapped via helmfile/bootstrap in talos-home-ops, not as a Flux app)

Let me continue with the next namespace.







Read

Read

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/utility/games'

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/test/games'

Searched dstewen/talos-mixed for "kubernetes/apps/gameserver/", 2 results

Read

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/main/home-automation'

Read

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/test/home-automation'

Searched dstewen/talos-mixed for "kubernetes/apps/home/", 11 results



**home-automation** — ⚠️ Partial match

| App | NS_Mixed | NS_New | CLUSTER | KS Exists? |
|---|---|---|---|---|
| home-assistant | home | home-automation | utility | ✅ |
| matter-server | home | home-automation | utility | ✅ |
| mosquitto | home | home-automation | utility | ✅ |
| rtlamr2mqtt | home | home-automation | utility | ✅ |
| zigbee | home | home-automation | utility | ✅ |
| unifi | home | — | — | ❌ MISSING |
| wallos | home | — | — | ❌ MISSING |
| frigate | home | — | — | ❌ MISSING |
| esphome | home | — | — | ❌ MISSING |
| node-red | home | — | — | ❌ MISSING |
| smtp-relay | home | — | — | ❌ MISSING |
| wyoming-piper | home | — | — | ❌ MISSING |
| wyoming-whisper | home | — | — | ❌ MISSING |

Let me continue with the remaining namespaces.







Read

Read

Read

Read

Searched dstewen/talos-mixed for "kubernetes/apps/kube-system/", 17 results



**kube-system** — ⚠️ Partial match

| App | NS_Mixed | NS_New | CLUSTER | KS Exists? |
|---|---|---|---|---|
| cilium | kube-system | kube-system | main, utility, test | ✅ |
| coredns | kube-system | kube-system | main, utility, test | ✅ |
| metrics-server | kube-system | kube-system | main, utility, test | ✅ |
| spegel | kube-system | — | — | ❌ MISSING |
| reloader | kube-system | — | — | ❌ MISSING |
| ocharted | kube-system | — | — | ❌ MISSING |
| irqbalance | kube-system | kube-system | main | ✅ |
| descheduler | kube-system | — | — | ❌ MISSING |
| drm-exporter | kube-system | — | — | ❌ MISSING |
| node-feature-discovery | kube-system | — | — | ❌ MISSING |
| intel-gpu-resource-driver | kube-system | kube-system | main | ✅ |
| intel-gpu-resource-driver-xe | kube-system | — | — | ❌ MISSING |
| nvidia-device-plugin | kube-system | kube-system | main | ✅ |
| nvidia-gpu-operator | kube-system | kube-system | main | ✅ |
| nvidia-power-limit | kube-system | kube-system | main | ✅ |
| etcd-defrag | kube-system | kube-system | main | ✅ |
| k8s-gpu-dra-driver | kube-system | kube-system | main, utility, test | ✅ |
| k8s-gpu-dra-driver-xe | kube-system | — | — | ❌ MISSING |

Let me continue with the remaining namespaces.







Read

Read

Read

Read

Searched dstewen/talos-mixed for "kubernetes/apps/kube-tools/", no results



**kube-tools** — No equivalent in talos-mixed (this is a talos-home-ops-only namespace)

Let me continue with the remaining namespaces.







Read

Read

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/utility/llm'

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/test/llm'

Searched dstewen/talos-mixed for "kubernetes/apps/ai/", 34 results



**llm** — ⚠️ Namespace renamed from `ai` to `llm`

| App | NS_Mixed | NS_New | CLUSTER | KS Exists? |
|---|---|---|---|---|
| mem0 | ai | — | — | ❌ MISSING |
| memini | ai | llm | main | ✅ |
| qdrant | ai | — | — | ❌ MISSING |
| k8sgpt | ai | — | — | ❌ MISSING |
| ha-mcp | ai | — | — | ❌ MISSING |
| ollama | ai | — | — | ❌ MISSING |
| n8n-mcp | ai | — | — | ❌ MISSING |
| litellm | ai | llm | main | ✅ |
| llmkube | ai | llm | main | ✅ |
| arr-mcp | ai | — | — | ❌ MISSING |
| local-ai | ai | — | — | ❌ MISSING |
| flux-mcp | ai | — | — | ❌ MISSING |
| plex-mcp | ai | — | — | ❌ MISSING |
| opencode | ai | llm | main | ✅ |
| toolhive | ai | llm | main | ✅ |
| turnstone | ai | — | — | ❌ MISSING |
| seerr-mcp | ai | — | — | ❌ MISSING |
| github-mcp | ai | — | — | ❌ MISSING |
| open-webui | ai | llm | main | ✅ |
| memory-mcp | ai | — | — | ❌ MISSING |
| sidero-mcp | ai | — | — | ❌ MISSING |
| boinc-amd64 | ai | — | — | ❌ MISSING |
| boinc-arm64 | ai | — | — | ❌ MISSING |
| kubectl-mcp | ai | — | — | ❌ MISSING |
| searxng-mcp | ai | — | — | ❌ MISSING |
| grafana-mcp | ai | — | — | ❌ MISSING |
| paperless-ai | ai | — | — | ❌ MISSING |
| prometheus-mcp | ai | — | — | ❌ MISSING |
| litellm-operator | ai | llm | main | ✅ |
| openclaw-xunholy | ai | — | — | ❌ MISSING |
| stable-diffusion | ai | — | — | ❌ MISSING |
| openclaw-operator | ai | — | — | ❌ MISSING |
| openclaw-test | ai | — | — | ❌ MISSING |
| open-webui-pipelines | ai | — | — | ❌ MISSING |

**talos-home-ops llm/ has apps NOT in talos-mixed:**
- comfyui, courier, dispatch, headroom, hermes, lemonade-tts, llm-wake, miso-gallery, openclaw, paseo, repo-wiki, searxng, whisper

Let me continue with the remaining namespaces.







Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/base/mispospace-ci'

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/main/mispospace-ci'

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/utility/mispospace-ci'

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/test/mispospace-ci'

Searched dstewen/talos-mixed for "kubernetes/apps/mispoces-ci/", no results

Read

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/main/misospace-ci'

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/utility/misospace-ci'

Read

Searched dstewen/talos-mixed for "kubernetes/apps/misospace-ci/", no results



**misospace-ci** — Only in test cluster (RBAC only)

Let me continue with the remaining namespaces.







Read

Read

Read

Read

Searched dstewen/talos-mixed for "kubernetes/apps/network/", 11 results



**network** — ⚠️ Partial match

| App | NS_Mixed | NS_New | CLUSTER | KS Exists? |
|---|---|---|---|---|
| k8s-gateway | network | — | — | ❌ MISSING |
| envoy-gateway | network | network | main, utility, test | ✅ |
| cloudflare-dns | network | network | main, utility, test | ✅ |
| cloudflare-tunnel | network | — | — | ❌ MISSING |
| multus | network | network | main, utility | ✅ |
| netboot | network | — | — | ❌ MISSING |
| external-dns-pihole | network | — | — | ❌ MISSING |

**talos-home-ops network/ has apps NOT in talos-mixed:**
- certificates, echo, unifi-dns

Let me continue with the remaining namespaces.







Read

Read

Read

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/test/observability'

Searched dstewen/talos-mixed for "kubernetes/apps/monitoring/", 28 results



**observability** — ⚠️ Namespace renamed from `monitoring` to `observability`

| App | NS_Mixed | NS_New | CLUSTER | KS Exists? |
|---|---|---|---|---|
| keda | monitoring | — | — | ❌ MISSING |
| loki | monitoring | — | — | ❌ MISSING |
| tempo | monitoring | — | — | ❌ MISSING |
| alloy | monitoring | — | — | ❌ MISSING |
| kromgo | monitoring | observability | main | ✅ |
| netdata | monitoring | — | — | ❌ MISSING |
| rsyslog | monitoring | — | — | ❌ MISSING |
| unpoller | monitoring | — | — | ❌ MISSING |
| patchmon | monitoring | — | — | ❌ MISSING |
| promtail | monitoring | — | — | ❌ MISSING |
| sparkdash | monitoring | — | — | ❌ MISSING |
| nut-exporter | monitoring | — | — | ❌ MISSING |
| snmp-exporter | monitoring | — | — | ❌ MISSING |
| otel-collector | monitoring | — | — | ❌ MISSING |
| snmp-generator | monitoring | — | — | ❌ MISSING |
| pihole-exporter | monitoring | — | — | ❌ MISSING |
| grafana-operator | monitoring | — | — | ❌ MISSING |
| frigate-exporter | monitoring | — | — | ❌ MISSING |
| smartctl-exporter | monitoring | — | — | ❌ MISSING |
| opnsense-exporter | monitoring | — | — | ❌ MISSING |
| blackbox-exporter | monitoring | — | — | ❌ MISSING |
| speedtest-exporter | monitoring | — | — | ❌ MISSING |
| cloudflare-exporter | monitoring | — | — | ❌ MISSING |
| qbittorrent-exporter | monitoring | — | — | ❌ MISSING |
| kube-prometheus-stack | monitoring | observability | main, utility | ✅ |
| node-problem-detector | monitoring | — | — | ❌ MISSING |
| actual-budget-exporter | monitoring | — | — | ❌ MISSING |
| k8s-ephemeral-storage-metrics | monitoring | — | — | ❌ MISSING |

**talos-home-ops observability/ has apps NOT in talos-mixed:**
- alert-triage, exporters, gatus-sidecar, grafana, karma, network-ups-tools, prometheus-adapter, promxy, silence-operator, victoria-logs

Let me continue with the remaining namespaces.







Read

Read

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/utility/renovate'

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/test/renovate'

Searched dstewen/talos-mixed for "kubernetes/apps/renovate/", 1 result



**renovate** — ⚠️ Partial match

| App | NS_Mixed | NS_New | CLUSTER | KS Exists? |
|---|---|---|---|---|
| renovate-operator | renovate | renovate | main | ✅ |

Let me continue with the remaining namespaces.







Read

Read

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/utility/rook-ceph'

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/test/rook-ceph'

Searched dstewen/talos-mixed for "kubernetes/apps/rook-ceph/", 2 results



**rook-ceph** — ✅ Match found (main only)

| App | NS_Mixed | NS_New | CLUSTER | KS Exists? |
|---|---|---|---|---|
| rook-ceph | rook-ceph | rook-ceph | main | ✅ |
| ceph-csi-drivers | rook-ceph | rook-ceph | main | ✅ |

Let me continue with the remaining namespaces.







Read

Read

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/utility/security'

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/test/security'

Searched dstewen/talos-mixed for "kubernetes/apps/security/", 2 results



**security** — ⚠️ Partial match

| App | NS_Mixed | NS_New | CLUSTER | KS Exists? |
|---|---|---|---|---|
| lldap | security | — | — | ❌ MISSING |
| authentik | security | security | main | ✅ |

Let me continue with the remaining namespaces.







Read

Read

Read

Read

Searched dstewen/talos-mixed for "kubernetes/apps/selfhosted/", 8 results



**self-hosted** — ⚠️ Partial match

| App | NS_Mixed | NS_New | CLUSTER | KS Exists? |
|---|---|---|---|---|
| n8n | selfhosted | — | — | ❌ MISSING |
| wiki | selfhosted | — | — | ❌ MISSING |
| atuin | selfhosted | self-hosted | main, utility | ✅ |
| webhook | selfhosted | self-hosted | main | ✅ |
| searxng | selfhosted | — | — | ❌ MISSING |
| it-tools | selfhosted | self-hosted | utility | ✅ |
| lubelogger | selfhosted | — | — | ❌ MISSING |
| changedetection | selfhosted | — | — | ❌ MISSING |

**talos-home-ops self-hosted/ has apps NOT in talos-mixed:**
- acars, actual, archiveteam, bentopdf, forgejo, free-game-notifier, hypermind, meshcentral, netboot, paperless, picoshare, rss-forwarder, scanservjs, spoolman, thelounge, waypoint

Let me continue with the remaining namespaces.







Read

Read

Read

Read

Searched dstewen/talos-mixed for "kubernetes/apps/storage/", 7 results



**storage** — ⚠️ Partial match

| App | NS_Mixed | NS_New | CLUSTER | KS Exists? |
|---|---|---|---|---|
| minio | storage | — | — | ❌ MISSING |
| garage | storage | — | — | ❌ MISSING |
| kopiur | storage | storage | main, utility, test | ✅ |
| synology-csi | storage | — | — | ❌ MISSING |
| snapshot-controller | storage | storage | main, utility, test | ✅ |
| local-path-provisioner | storage | — | — | ❌ MISSING |
| democratic-csi-iscsi-synology | storage | — | — | ❌ MISSING |

**talos-home-ops storage/ has apps NOT in talos-mixed:**
- democratic-csi, kopia, openebs

Let me check the last namespace.







Read

Read

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/utility/workadventure'

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/test/workadventure'

Searched dstewen/talos-mixed for "kubernetes/apps/workadventure/", no results



**workadventure** — Only in main cluster, no equivalent in talos-mixed

Let me check the `finance` namespace from talos-mixed.







Searched dstewen/talos-mixed for "kubernetes/apps/finance/", 2 results

Searched dstewen/talos-mixed for "kubernetes/apps/default/", 4 results

Searched dstewen/talos-mixed for "kubernetes/apps/volsync/", 2 results

Searched dstewen/talos-mixed for "kubernetes/apps/netflow/", 3 results

Searched dstewen/talos-mixed for "kubernetes/apps/system-upgrade/", 1 result



Let me check if these remaining namespaces exist in talos-home-ops.








Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/base/finance'

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/base/default'

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/base/volsync'

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/base/netflow'

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/base/system-upgrade'

Read
Tool execution failed: Error: ENOENT: no such file or directory, scandir '/home/dstewen/git/talos-home-ops/kubernetes/apps/base/gameserver'



I've completed the namespace-by-namespace comparison. Here's the full summary:

---

## Namespace Mapping

| talos-mixed NS | talos-home-ops NS | Status |
|---|---|---|
| actions-runner-system | actions-runner-system | ✅ Same |
| ai | llm | 🔄 Renamed |
| cert-manager | cert-manager | ✅ Same |
| database | database | ✅ Same |
| default | — | ❌ Removed |
| finance | — | ❌ Removed |
| gameserver | games | 🔄 Renamed |
| home | home-automation | 🔄 Renamed |
| external-secrets | external-secrets | ✅ Same |
| flux-system | flux-system | ✅ Same |
| kube-system | kube-system | ✅ Same |
| media | downloads + media | 🔄 Split |
| monitoring | observability | 🔄 Renamed |
| network | network | ✅ Same |
| netflow | — | ❌ Removed |
| renovate | renovate | ✅ Same |
| rook-ceph | rook-ceph | ✅ Same |
| security | security | ✅ Same |
| selfhosted | self-hosted | 🔄 Renamed |
| storage | storage | ✅ Same |
| system-upgrade | — | ❌ Removed |
| volsync | — | ❌ Removed |

---

## Apps Missing from talos-home-ops

### ❌ Entirely missing namespaces (no base/ directory):
- **default** — echo, homepage
- **finance** — actual, firefly-iii
- **netflow** — kafka, akvorado, clickhouse
- **system-upgrade** — tuppr
- **volsync** — volsync, kopia

### ❌ Apps missing from existing namespaces:

**ai → llm:**
mem0, qdrant, k8sgpt, ha-mcp, ollama, n8n-mcp, arr-mcp, local-ai, flux-mcp, plex-mcp, turnstone, seerr-mcp, github-mcp, memory-mcp, sidero-mcp, boinc-amd64, boinc-arm64, kubectl-mcp, searxng-mcp, grafana-mcp, paperless-ai, prometheus-mcp, openclaw-xunholy, stable-diffusion, openclaw-operator, openclaw-test, open-webui-pipelines

**database:**
plugin-barman-cloud, valkey, pgadmin, influxdb3

**home → home-automation:**
unifi, wallos, frigate, esphome, node-red, smtp-relay, wyoming-piper, wyoming-whisper

**kube-system:**
spegel, reloader, ocharted, descheduler, drm-exporter, node-feature-discovery, intel-gpu-resource-driver-xe, k8s-gpu-dra-driver-xe

**media → downloads + media:**
immich, lidarr, calibre, whisparr, paperless, radarr-uhd, sonarr-uhd, calibre-web, qbittorrent, paperless-scan

**monitoring → observability:**
keda, loki, tempo, alloy, netdata, rsyslog, unpoller, patchmon, promtail, sparkdash, nut-exporter, snmp-exporter, otel-collector, snmp-generator, pihole-exporter, grafana-operator, frigate-exporter, smartctl-exporter, opnsense-exporter, blackbox-exporter, speedtest-exporter, cloudflare-exporter, qbittorrent-exporter, node-problem-detector, actual-budget-exporter, k8s-ephemeral-storage-metrics

**network:**
k8s-gateway, cloudflare-tunnel, netboot, external-dns-pihole

**security:**
lldap

**selfhosted → self-hosted:**
n8n, wiki, searxng, lubelogger, changedetection

**storage:**
minio, garage, synology-csi, local-path-provisioner, democratic-csi-iscsi-synology

---

## Apps in talos-home-ops NOT in talos-mixed

**downloads:**
autobrr, brrpolice, cleanrr, decluttarr, flaresolverr, kapowarr, metube, mylar, pinchflat, qui

**llm:**
comfyui, courier, dispatch, headroom, hermes, lemonade-tts, llm-wake, miso-gallery, openclaw, paseo, repo-wiki, searxng, whisper

**media:**
ersatztv, kavita, komga, kyoo, stash, wizarr, your-spotify

**observability:**
alert-triage, exporters, gatus-sidecar, grafana, karma, network-ups-tools, prometheus-adapter, promxy, silence-operator, victoria-logs

**self-hosted:**
acars, actual, archiveteam, bentopdf, forgejo, free-game-notifier, hypermind, meshcentral, netboot, paperless, picoshare, rss-forwarder, scanservjs, spoolman, thelounge, waypoint

**storage:**
democratic-csi, kopia, openebs

**workadventure:**
livekit, synapse, workadventure

**kube-tools:**
descheduler, ocharted, reloader, spegel, tuppr

**misospace-ci:**
rbac

---

## Structure Difference

**talos-mixed:**
```
kubernetes/apps/<namespace>/<app>/ks.yaml
```

**talos-home-ops:**
```
kubernetes/apps/base/<namespace>/<app>/          # shared base manifests
kubernetes/apps/<cluster>/<namespace>/<app>.yaml  # Flux Kustomization overlay
```

The key difference: talos-home-ops uses a **base/cluster overlay pattern** where base manifests are shared across all clusters, and each cluster has its own Flux Kustomization file that points to the base. talos-mixed uses a single-cluster template-based approach where `ks.yaml` files live alongside the app manifests.
