# Pi-hole

LAN DNS / ad blocking on Talos `prd`. Leans: [decisions](../decisions.md) · app: [apps/pihole](../../clusters/prd/apps/pihole/).

## Placement

| Piece | Choice |
|-------|--------|
| Runtime | Official `pihole/pihole:**2026.07.2**` (pinned digest), **Deployment** |
| Replicas | **3** with soft `podAntiAffinity` (spread across nodes) |
| State | **Stateless** — `emptyDir` for `/etc/pihole`; gravity rebuilt per pod |
| Config SoT | **ConfigMaps** in Git + sync sidecar |
| DNS | Cilium L2 LoadBalancer VIP **`192.168.5.22`** — UDP/TCP **53** |
| Admin | ClusterIP `:80` → Envoy + **Authentik Proxy** |
| DHCP / ZBF | UniFi (all VLANs) → **`.22`** — OpenTofu `infrastructure/unifi/` |

## Stats (ephemeral)

Query counts are per-pod / lost on restart. Homepage is **link-only**. **Follow-up:** Prometheus + Grafana.

## Auth

Authentik Proxy; Pi-hole web password **disabled**. Config-sync uses localhost (no public `/api` skip).

## Cutover status (Sep 2026)

| Path | Backend |
|------|---------|
| LAN DNS / DHCP | **`192.168.5.22`** (k8s) |
| `pihole.lab` UI | Authentik → in-cluster |
| LXC `.11` | Keep running briefly as break-glass; stop VMID **106** when soak is trusted |
| OpenTofu `infrastructure/pihole/` | Still targets LXC (`services.pihole.lxc`) — **retire** after LXC stop |

**Cutover done (Sep 2026):** LAN DHCP DNS on Drury / Homelab / IoT / Guest / Camera → `.22` via OpenTofu. ZBF allows IoT/Isolated → Homelab DNS VIP. Talos nameservers → `.22`.

**Still open:**
1. Renew DHCP leases (or wait) so clients pick up `.22`
2. After soak: stop Pi-hole LXC **106** on Proxmox
3. Retire OpenTofu `infrastructure/pihole/` (still targets `services.pihole.lxc`)

## Related

- [networking](networking.md) · Cilium: `clusters/prd/platform/cilium/resources.yaml`
