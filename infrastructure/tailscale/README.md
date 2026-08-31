# Tailscale (OpenTofu)

Tailnet configuration in Git — applied with `moon run tailscale:apply`.

## Managed in Git

| File | Resource | Purpose |
|------|----------|---------|
| `acl.tf` | `tailscale_acl` | Policy: allow-all, SSH check, `autoApprovers` for lab subnets, `tag:k8s` |
| `tailnet_settings.tf` | `tailscale_tailnet_settings` | Externally managed ACL + link to this repo |
| `dns.tf` | `tailscale_dns_split_nameservers` | Split DNS `lab.jacobdrury.com` → Cloudflare |
| `dns_preferences.tf` | `tailscale_dns_preferences` | MagicDNS on |
| `devices.tf` | `tailscale_device_*` | homelab02: subnet routes enabled, key expiry off |
| `auth_keys.tf` | `tailscale_tailnet_key` | Reusable preauth key `tag:k8s` for Phase 2 operator |

**Not in Terraform** (host/client): `--advertise-routes` on homelab02, `--accept-routes` on clients, Tailscale package install.

## Remote `http://scarif.lab.jacobdrury.com`

1. Split DNS → Cloudflare → `192.168.5.10` (applied)
2. Subnet router routes enabled on homelab02 (applied)
3. **homelab02 must advertise routes** (SSH once):

```bash
sudo tailscale set --advertise-routes=192.168.1.0/24,192.168.5.0/24 --advertise-exit-node=false
```

4. Mac: `Tailscale set --accept-routes=true` (already on)

**HTTPS:** Phase 2 Envoy + cert-manager — same hostname, switch to `https://`.

## OAuth credentials

1Password item **`Tailscale OAuth`** (`client id`, `credential`). User created with **`all`** scope.

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
curl -sI http://scarif.lab.jacobdrury.com
```

## Steady state (Phase 2+)

- Point `devices.tf` at the k8s operator node; drop Drury route when pc (black) leaves.
- Operator Helm uses auth key from 1Password / ESO.
- Split DNS unchanged.
