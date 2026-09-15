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
| Config | ConfigMaps + sync sidecar (`clusters/prd/apps/pihole/`) |

## Stats (ephemeral)

Query counts are per-pod / lost on restart. Homepage is **link-only**. **Follow-up:** Prometheus + Grafana.

## Auth

Authentik Proxy; Pi-hole web password **disabled**. Config-sync uses localhost (no public `/api` skip).

## Cutover status (Sep 2026)

| Path | Backend |
|------|---------|
| LAN DNS / DHCP | **`192.168.5.22`** (k8s) |
| `pihole.lab` UI | Authentik → in-cluster |
| Policy / local DNS | GitOps ConfigMaps (LXC OpenTofu **retired**) |
| LXC `.11` (VMID **106**) | Stop when soak is trusted |

**Still open:** DHCP clients renew automatically (lease **24h**, typically ~**12h** at T1); force renew to pick up `.22` sooner. Then stop LXC **106**.

## Related

- [networking](networking.md) · Cilium: `clusters/prd/platform/cilium/resources.yaml`
