# Tailscale (OpenTofu)

Tailnet configuration in Git — applied with `moon run tailscale:apply` (or CI on `main`).

## Managed in Git

| File | Resource | Purpose |
|------|----------|---------|
| `acl.tf` | `tailscale_acl` | Grants (members → Homelab; `tag:ci` → UniFi/kube); SSH check; `autoApprovers`; `tag:k8s` / `tag:ci` |
| `tailnet_settings.tf` | `tailscale_tailnet_settings` | Externally managed ACL + link to this repo |
| `dns.tf` | `tailscale_dns_split_nameservers` | Split DNS `lab.jacobdrury.com` → Cloudflare |
| `dns_preferences.tf` | `tailscale_dns_preferences` | MagicDNS on |
| `devices.tf` | `tailscale_device_*` | k8s Connector routes (+ optional interim router — **off**) |
| `auth_keys.tf` | `tailscale_tailnet_key` | Reusable preauth key `tag:k8s` for Phase 2 operator |

**Not in Terraform** (host/client): `--accept-routes` on clients; Tailscale package / GitHub Action install.

## Remote `https://scarif.lab.jacobdrury.com`

1. Split DNS → Cloudflare → Homelab IPs (applied)
2. **Steady subnet router:** k8s Connector `prd-homelab-router` advertises **`192.168.5.0/24`**
3. Mac / CI: `--accept-routes` (Tailscale app or GitHub Action `args`)

**Retired:** homelab02 Drury/Homelab advertise (`enable_drury_subnet_route = false`, `manage_subnet_router = false`).

## OAuth credentials

| Item | Use |
|------|-----|
| **Tailscale OAuth** | OpenTofu provider (`moon run tailscale:…`) |
| **Tailscale CI OAuth** | GitHub Action ephemeral nodes (`tag:ci`) — [opentofu-ci](../../docs/setup/opentofu-ci.md) |

## Apply

```bash
op signin
moon run tailscale:apply
```

## k8s operator auth key

After apply, copy the preauth key to 1Password (not in Git):

```bash
cd infrastructure/tailscale && source ../../.moon/scripts/tofu/env.sh
tofu output -raw k8s_operator_auth_key
```

Key ID is in output `k8s_operator_auth_key_id`. Terraform recreates when invalid (`recreate_if_invalid = always`).

## Verify away from home

```bash
dig scarif.lab.jacobdrury.com +short
ping -c 1 192.168.5.10
curl -sI https://scarif.lab.jacobdrury.com
```

## Steady state

- Operator Helm chart: `clusters/prd/platform/tailscale-operator/` (OAuth from 1Password **Tailscale OAuth**).
- Connector `prd-homelab-router` advertises **`192.168.5.0/24`** (`tag:k8s`).
- Split DNS unchanged.
- CI: `tag:ci` → Homelab gateway `:443` + kube API `:6443` (IPs from `lab.yaml`).

## Friend access (Phase 6)

**Admins:** subnet router + `*.lab` URLs (unchanged).

**Friends:** Jellyfin via Tailscale **L7 Ingress** (`https://jellyfin.<tailnet>.ts.net`); Minecraft via **L3 Service expose** (`minecraft.<tailnet>.ts.net:25565`). ACL `group:friends` → `tag:shared` only — **not** homelab subnet routes.

Full design: [docs/architecture/games.md](../../docs/architecture/games.md#friend-access--tailscale). Tighten `acl.tf` before issuing friend auth keys.

## MagicDNS & tailnet naming

MagicDNS hostnames look like **`jellyfin.ibex-ladon.ts.net`** — hostname prefix + tailnet suffix (see `lab.yaml`).
