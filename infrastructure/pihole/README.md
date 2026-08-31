# Pi-hole (OpenTofu)

Manages **configuration** for the Pi-hole LXC (host in [`../lab.yaml`](../lab.yaml)). Deployment stays on Proxmox now; k8s later via Argo — update `pihole.host` in `lab.yaml` when you cut over.

**Provider:** [barryw/pihole-v6](https://registry.opentofu.org/providers/barryw/pihole-v6/latest) (Pi-hole **v6** API).

## Source of truth

**Git is the source of truth** for Pi-hole policy (lists, domains, upstreams, zone forwarding). DNS records for `*.lab.jacobdrury.com` live in **`infrastructure/dns/`** (Cloudflare); Pi-hole forwards that zone to Cloudflare resolvers.

```bash
moon run pihole:apply
```

Do **not** change lists, domains, or upstreams in the Pi-hole UI — those changes will drift and get reverted on the next apply.

`*.auto.tfvars` is the OpenTofu convention for auto-loaded var files (committed, not “generated”).

## Prerequisites

1. **Pi-hole v6** app-password (Settings → API → Configure app password).
2. **app_sudo** for write access: Settings → All settings → `webserver.api.app_sudo` = `true`
3. **1Password** item **`Pi-hole API`** in vault **Homelab**
4. `op signin`

## What is managed

| File | Resources |
|------|-----------|
| `lists.auto.tfvars` | Block/allow list subscriptions (`pihole_adlist`) |
| `domains.auto.tfvars` | Per-domain allow/deny (`pihole_domain_list`) |
| `upstreams.auto.tfvars` | Default upstream resolvers (`pihole_dns_upstreams`) |
| `local_dns.auto.tfvars` | LAN local DNS (`pihole_dns_record`) — e.g. `*.homelab.com` |
| `dns_forward.tf` | Zone forward for `lab.yaml` → `zone` via Cloudflare (`cloudflare_dns`) |
| `local_dns.tf` | Local DNS record resources |

**Not here:** `*.lab.jacobdrury.com` DNS records → `infrastructure/dns/` (+ external-dns for apps in Phase 2+).

## Secrets

`PIHOLE_PASSWORD` is loaded via `op` (never committed).

## HA (later)

When running two Pi-hole replicas, duplicate provider with aliases or run this module twice with different `lab.yaml` / provider config.
