# Pi-hole (OpenTofu)

Manages **configuration** for the Pi-hole LXC at `192.168.1.11` (VMID 106 on homelab02). Deployment stays on Proxmox now; k8s later via Argo. Same module — change `pihole_url` when you cut over.

**Provider:** [barryw/pihole-v6](https://registry.opentofu.org/providers/barryw/pihole-v6/latest) (Pi-hole **v6** API).

## Source of truth

**Git is the source of truth.** Edit config in the repo, then apply:

```bash
moon run pihole:apply
```

Do **not** change lists, domains, or upstreams in the Pi-hole UI — those changes will drift and get reverted on the next apply.

`*.auto.tfvars` is the OpenTofu convention for var files that are auto-loaded on plan/apply (not a “generated” marker). These are committed as source of truth.

## Prerequisites

1. **Pi-hole v6** app-password (Settings → API → Configure app password).
2. **app_sudo** for write access: `sudo pihole-FTL --config webserver.api.app_sudo true`
3. **1Password** item **`Pi-hole API`** in vault **Homelab**
4. `op signin`

## What is managed

| File | Resources |
|------|-----------|
| `lists.auto.tfvars` | Block/allow list subscriptions (`pihole_adlist`) |
| `domains.auto.tfvars` | Per-domain allow/deny (`pihole_domain_list`) |
| `upstreams.auto.tfvars` | Upstream resolvers (`pihole_dns_upstreams`) |
| `local_dns.tf` | Homelab infra `*.lab` A records (`pihole_dns_record`) |

Not in scope yet: DHCP, groups/clients, full `pihole_config_*` — add as needed.

## Secrets

`PIHOLE_PASSWORD` is loaded via `op` (never committed).

## HA (later)

When running two Pi-hole replicas, duplicate provider with aliases or run this module twice with different `pihole_url` values.
