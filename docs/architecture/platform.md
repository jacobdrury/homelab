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
| Mesh | **Tailscale operator** | Subnet router for **`192.168.5.0/24`** on `prd`; complements split DNS |
| DNS app | **Pi-hole** | In cluster |
| Monitoring | Prometheus, Grafana, Uptime Kuma | Discord alerts |

### Node layout

| Stage | Nodes | Notes |
|-------|-------|--------|
| **Bootstrap** | 1× bare-metal CP on Mac Mini (**yavin**) | Single-node `prd`; **`allowSchedulingOnControlPlanes: true`**; **no HA** |
| **Steady** | **3× bare-metal control planes** — **yavin** + **hoth** + **endor** | Expand **in place**; all CPs schedule workloads; no dedicated workers |

**Scale-out (Phase 4):** when **hoth** and **endor** arrive, **join them as control planes** to the existing cluster (**1→3** etcd members). Use the same cluster secrets and a **stable API endpoint** (DNS or VIP) defined at first bootstrap. Media stays on **scarif NFS** — expansion does not touch library data.

**Bootstrap requirements (day one):**

- Kubernetes API: **`k8s.lab.jacobdrury.com`** (OpenTofu → yavin on homelab VLAN; VIP later at 3 CPs)  
- Homelab **VLAN** live before install — not flat `192.168.1.0/24`  
- One `talosctl gen config` / secrets bundle reused for join configs  
- Per-node machine config patches (hostname, interfaces) kept in `infrastructure/prd/`  
- **etcd snapshots** on a schedule while single-node  
- Odd CP count only: **1 → 3**, not 1 → 2  

**Joining mental model:** boot Talos → apply `controlplane` machine config (shared cluster secrets + API endpoint) → node Ready. New pods can land on new nodes; existing pods stay until roll/drain.

### yavin networking (Mac Mini 2018)

| Interface | Role | Hardware |
|-----------|------|----------|
| `enx6c1ff721c616` | **Primary** (2.5G) | UGREEN USB-C · Realtek **RTL8156BG** → Pro Max 16 Port 15 |
| `enp4s0` | **Secondary** (1G) | Onboard Intel · fallback / recovery |

Pin both in Talos machine config by **MAC** or predictable interface name. Verify **2500 Mbps** link after install.

Machine configs live under `infrastructure/prd/`; keep CP patches consistent across all nodes. Node hostnames: [naming](naming.md).

## App placement

| Workload | Where | Notes |
|----------|--------|--------|
| Jellyfin | k8s | NFS `media/`; GPU worker — [gpu](gpu.md) |
| Sonarr ×2, Prowlarr, qBittorrent | k8s | NFS downloads; **peers via Mullvad WG**, **UI/API off-VPN** — [media](media.md) |
| Pi-hole | k8s | Migrate **last** from pc (black) LXC — `.11` until cutover |
| Homepage | k8s | [gethomepage.dev](https://gethomepage.dev) |
| Home Assistant | k8s | Before Pi-hole; downtime OK; USB passthrough if radio needs it |
| ATM10 (Minecraft) | k8s | Phase 6 — iSCSI PVC; friend access via Tailscale `.ts.net` — [games](games.md) |
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
    pihole/                        # OpenTofu Pi-hole config (API)
  bootstrap/                       # Argo install notes
  apps/
    system/                        # cilium, nfs-csi, iscsi, cert-manager, tailscale,
                                   # 1password-connect, external-secrets, envoy-gateway,
                                   # actions-runner-controller (Phase 2b)
    media/                         # jellyfin, *arr, qbittorrent (+ Mullvad WG for peers)
    home/                          # homeassistant, homepage
    games/                         # minecraft-atm10 (Phase 6)
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

**Bootstrap:** stand up **`prd` only**. Add `stg` when you want a scratch cluster (e.g. extra hardware or a small VM elsewhere).
