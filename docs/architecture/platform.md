# Kubernetes platform

Stack choices and where workloads live. Leans: [decisions](../decisions.md).

## Platform

| Piece | Choice | Notes |
|-------|--------|--------|
| OS | **Talos Linux** | Immutable, API-driven |
| Bootstrap | `talosctl` + configs in Git | Under `infrastructure/talos/prd/` |
| CNI | **Cilium** | |
| GitOps | **Argo CD** | Live on `prd` — root → `clusters/prd/applications`; UI port-forward until Envoy |
| Secrets | **1Password** + Connect + ESO | Live — [secrets](secrets.md) |
| Storage | **NFS CSI + iSCSI CSI → Unraid** | Live — `scarif-nfs`, `scarif-iscsi` — [storage](storage.md) |
| Ingress | **Envoy Gateway** | **Next** — Gateway API / HTTPRoute |
| Mesh | **Tailscale operator** | Subnet router for **`192.168.5.0/24`** on `prd`; complements split DNS |
| DNS app | **Pi-hole** | In cluster |
| Monitoring | Prometheus, Grafana (Phase 5); **Uptime Kuma** after Argo | Bootstrap debug: `connect/` + k9s + talosctl — no early metrics stack on 16 GB yavin |

### Node layout

| Stage | Nodes | Notes |
|-------|-------|--------|
| **Bootstrap** | 1× bare-metal CP on Mac Mini (**yavin**) | Single-node `prd`; **`allowSchedulingOnControlPlanes: true`**; **no HA** |
| **Interim** | **yavin** (CP) + **naboo** (worker VM on scarif) | Extra RAM/CPU until mini PCs; **naboo is never a CP** |
| **Steady** | **3× bare-metal control planes** — **yavin** + **hoth** + **endor** | Expand **in place**; all CPs schedule workloads; **drain + remove naboo** |

**Interim worker (Phase 2):** **naboo** — **live** on `prd` (Sep 2026). Unraid KVM on **scarif**, Homelab `192.168.5.14`, 6 vCPU / 20 GB, SSD vdisk on `/mnt/disks/naboo-ssd`. Same cluster secrets / Talos **1.12.7** as yavin; **worker** only (ROLE `<none>` in k8s is expected). scarif maintenance takes naboo down — acceptable stopgap. Does **not** replace “Unraid = storage only” for apps (no Unraid Docker).

**Scale-out (Phase 4):** when **hoth** and **endor** arrive, **join them as control planes** to the existing cluster (**1→3** etcd members). Drain workloads off **naboo**, then delete the VM. Use the same cluster secrets and a **stable API endpoint** (DNS or VIP) defined at first bootstrap. Media stays on **scarif NFS** — expansion does not touch library data.

**Bootstrap requirements (day one):**

- Kubernetes API: **`k8s.lab.jacobdrury.com`** (OpenTofu → yavin on homelab VLAN; VIP later at 3 CPs)  
- Homelab **VLAN** live before install — not flat `192.168.1.0/24`  
- One `talosctl gen config` / secrets bundle reused for join configs  
- Per-node machine config patches (hostname, interfaces) kept in `infrastructure/talos/prd/`  
- **etcd snapshots** on a schedule while single-node  
- Odd CP count only: **1 → 3**, not 1 → 2  

**Joining mental model:** boot Talos → apply machine config (shared cluster secrets + API endpoint) → node Ready. Control planes use `controlplane` config; **naboo** uses **worker**. New pods can land on new nodes; existing pods stay until roll/drain.

### yavin networking (Mac Mini 2018)

| Interface | Role | Hardware |
|-----------|------|----------|
| `enx6c1ff721c616` / `enp8s0u2` | **Primary** (2.5G) | UGREEN USB-C · Realtek **RTL8156BG** → Pro Max 16 **Port 13** |
| `enp4s0` (`68:fe:f7:10:39:b9`) | **Secondary** (1G) | Onboard Intel → Pro Max 16 **Port 5** (Homelab `192.168.5.111`) |

Pin both in Talos machine config by **MAC** or predictable interface name. Verify **2500 Mbps** link after install.

Machine configs live under `infrastructure/talos/prd/`; keep CP patches consistent across all nodes. Node hostnames: [naming](naming.md).

## App placement

| Workload | Where | Notes |
|----------|--------|--------|
| Jellyfin | k8s | NFS `media/`; GPU worker — [gpu](gpu.md) |
| Sonarr ×2, Prowlarr, qBittorrent | k8s | NFS downloads; **peers via Mullvad WG**, **UI/API off-VPN** — [media](media.md) |
| Pi-hole | k8s | Migrate **last** from pc (black) LXC — `.11` until cutover |
| Homepage | k8s | **First** GitOps app after Envoy; tiles use `*.lab` (incl. transitional proxies) — [gethomepage.dev](https://gethomepage.dev) |
| Home Assistant | k8s | Before Pi-hole; downtime OK; USB passthrough if radio needs it |
| ATM10 (Minecraft) | k8s | Phase 6 — iSCSI PVC; friend access via Tailscale `.ts.net` — [games](games.md) |
| Argo CD | k8s | bootstrap once |
| Uptime Kuma | k8s | With/right after Homepage |
| Prometheus / Grafana | k8s | **Phase 5** — not during single-node bootstrap |

Migration order: [roadmap Phase 3](../roadmap.md#phase-3--migrate-apps).

## Repo layout

```text
homelab/
  .prototools / .moon / moon.yml   # proto + moon
  connect/                         # cd connect/prd (direnv) — kubeconfig/talosconfig gitignored
  docs/                            # you are here
  infrastructure/
    talos/
      prd/                         # Talos for prd
      stg/                         # reserved
    dns/                           # OpenTofu Cloudflare
    unifi/                         # OpenTofu UniFi
    pihole/                        # OpenTofu Pi-hole config (API)
    tailscale/                     # OpenTofu Tailscale
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
| `connect/` | Local kubectl / talosctl / k9s — [README](../../connect/README.md) |
| `apps/*` | Shared manifests; env overlays for hostnames |
| `clusters/prd` | What `prd` Argo syncs → `*.lab.jacobdrury.com` |
| `clusters/stg` | Later → `*.stg.lab.jacobdrury.com` |
| `infrastructure/talos/prd` | Talos machine configs |

**Contract:** merge to `main` → Argo on that cluster applies `clusters/<env>/` only.

**Bootstrap:** stand up **`prd` only**. Add `stg` when you want a scratch cluster (e.g. extra hardware or a small VM elsewhere).
