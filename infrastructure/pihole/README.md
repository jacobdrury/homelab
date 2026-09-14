# Pi-hole (OpenTofu) — LXC only until k8s cutover

Manages **configuration** for the Pi-hole **LXC** (host in [`../lab.yaml`](../lab.yaml) `services.pihole.host`).

**k8s policy SoT is ConfigMaps** under [`clusters/prd/apps/pihole/`](../../clusters/prd/apps/pihole/) — not this module. See [docs/architecture/pihole.md](../../docs/architecture/pihole.md). After DHCP cutover, **retire** this OpenTofu project (no dual-apply to pods).

**Provider:** [barryw/pihole-v6](https://registry.opentofu.org/providers/barryw/pihole-v6/latest) (Pi-hole **v6** API).

## Source of truth (LXC transitional)

```bash
moon run pihole:apply
```

Do **not** change lists/domains/upstreams in the LXC UI — reverted on apply. Prefer editing k8s ConfigMaps once you are soaking the cluster VIP; keep LXC TF in sync only if both must match during dual-DNS soak.

## Prerequisites

1. Pi-hole v6 app-password + `webserver.api.app_sudo = true`
2. 1Password item **`Pi-hole API`** in vault **Homelab**
3. `op signin`

## What is managed (LXC)

| File | Resources |
|------|-----------|
| `lists.auto.tfvars` | Block/allow list subscriptions |
| `domains.auto.tfvars` | Per-domain allow/deny |
| `upstreams.auto.tfvars` | Upstream resolvers |
| `local_dns.auto.tfvars` | LAN local DNS |
| `dns_forward.tf` | `*.lab` → Cloudflare |

Mirror the same policy into `clusters/prd/apps/pihole/configmap-*.yaml` when changing lists during migration.
