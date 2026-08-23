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

- **Learning / interim:** 1 CP + 1–2 workers as VMs on Mac Mini  
- **Steady state:** odd CP count (1 or 3) on mini PCs; workers as needed  
- Same machine configs should move from Proxmox VMs → bare metal with little rewrite  

## App placement

| Workload | Where | Notes |
|----------|--------|--------|
| Jellyfin | k8s | NFS `media/`; GPU worker — [gpu](gpu.md) |
| Sonarr ×2, Prowlarr, qBittorrent | k8s | downloads on Unraid NFS |
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
    media/                         # jellyfin, *arr, qbittorrent
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
