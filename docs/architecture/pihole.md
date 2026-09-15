# Pi-hole

LAN DNS / ad blocking on Talos `prd`. Leans: [decisions](../decisions.md) · app: [apps/pihole](../../clusters/prd/apps/pihole/).

## Placement

| Piece | Choice |
|-------|--------|
| Runtime | Official `pihole/pihole:**2026.07.2**` (pinned digest), **Deployment** |
| Replicas | **2** with soft `podAntiAffinity` (yavin + naboo) |
| State | **Stateless** — `emptyDir` for `/etc/pihole`; gravity rebuilt per pod |
| Config SoT | **ConfigMaps** in Git + sync sidecar |
| DNS | Cilium L2 LoadBalancer VIP **`192.168.5.22`** — UDP/TCP **53** |
| Admin | ClusterIP `:80` → Envoy + **Authentik Proxy** |
| DHCP / ZBF | UniFi → **`.22`** (Homelab DHCP + IoT/Isolated DNS allows) |

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

**Manual:** set Drury / IoT / Guest / Camera **DHCP DNS** to `.22` in UniFi if those networks are not Git-managed (only Homelab `dhcp_dns` is in OpenTofu).

**Talos:** patches set nameservers to `.22` first — `./gen.sh` then `talosctl apply-config` on yavin + naboo when convenient.

## Related

- [networking](networking.md) · Cilium: `clusters/prd/platform/cilium/resources.yaml`
