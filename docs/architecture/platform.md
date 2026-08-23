# Kubernetes platform

Stack choices and where workloads live. Leans: [decisions](../decisions.md).

## Platform

| Piece | Choice | Notes |
|-------|--------|--------|
| OS | **Talos Linux** | Immutable, API-driven |
| Bootstrap | `talosctl` + configs in Git | Under `infrastructure/prd/` |
| CNI | **Cilium** | |
| GitOps | **Argo CD** | Root → `clusters/prd` |
| Secrets | **1Password** + Connect + ESO | [secrets](secrets.md) |
| Storage | **NFS CSI + iSCSI → Unraid** | [storage](storage.md) — NFS media/shared; iSCSI block |
| Ingress | **Envoy Gateway** | Gateway API / HTTPRoute |
| Mesh | **Tailscale operator** | + Unraid on tailnet |
| DNS app | **Pi-hole** | In cluster |
| Monitoring | Prometheus, Grafana, Uptime Kuma | Discord alerts |

### Node layout

| Stage | Nodes | Notes |
|-------|-------|--------|
| **Interim** | 1× Talos VM on Mac Mini Proxmox | Single-node CP; **`allowSchedulingOnControlPlanes: true`** |
| **Steady** | **3× bare-metal control planes** — Mac Mini + 2 mini PCs | All CPs; all schedule workloads; no dedicated workers |

**Scale-out (Phase 4):** when the two mini PCs arrive, prefer a **fresh 3-CP bootstrap** + Argo resync over expanding the interim VM cluster’s etcd live. Unraid holds data; Git holds desired apps — short cutover, less etcd risk.

**Joining mental model:** boot Talos → apply `controlplane` machine config (shared cluster secrets + API endpoint) → node Ready. New pods can land on new nodes; existing pods stay until roll/drain. Use a stable API endpoint (DNS or VIP) before going multi-CP.

Machine configs live under `infrastructure/prd/`; keep CP patches consistent across the three nodes.

## App placement

| Workload | Where | Notes |
|----------|--------|--------|
| Jellyfin | k8s | NFS `media/`; GPU worker — [gpu](gpu.md) |
| Sonarr ×2, Prowlarr, qBittorrent | k8s | NFS downloads; **peers via Mullvad WG**, **UI/API off-VPN** — [media](media.md) |
| Pi-hole | k8s | keep Pi-hole |
| Homepage | k8s | [gethomepage.dev](https://gethomepage.dev) |
| Home Assistant | k8s | **After** Jellyfin/*arr; downtime OK; USB passthrough if radio needs it |
| Argo CD | k8s | bootstrap once |
| Monitoring | k8s | Phase 5 |

Migration order: [roadmap Phase 3](../roadmap.md#phase-3--migrate-apps).

## Repo layout

```text
homelab/
  .prototools / .moon / moon.yml   # proto + moon
  docs/                            # you are here
  infrastructure/
    prd/                           # Talos for prd
    stg/                           # reserved
    dns/                           # OpenTofu Cloudflare
    unifi/                         # OpenTofu UniFi
  bootstrap/                       # Argo install notes
  apps/
    system/                        # cilium, nfs-csi, iscsi, cert-manager, tailscale,
                                   # 1password-connect, external-secrets, envoy-gateway
    media/                         # jellyfin, *arr, qbittorrent (+ Mullvad WG for peers)
    home/                          # homeassistant, homepage
    network/                       # pihole
  clusters/
    prd/                           # Argo app-of-apps
    stg/                           # reserved
```

| Path | Role |
|------|------|
| `apps/*` | Shared manifests; env overlays for hostnames |
| `clusters/prd` | What `prd` Argo syncs → `*.lab.jacobdrury.com` |
| `clusters/stg` | Later → `*.stg.lab.jacobdrury.com` |
| `infrastructure/prd` | Talos machine configs |

**Contract:** merge to `main` → Argo on that cluster applies `clusters/<env>/` only.

**Bootstrap:** stand up **`prd` only**. Add `stg` when you want a scratch cluster (e.g. minimal VMs on the Mac Mini).
