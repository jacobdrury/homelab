# Shared lab constants — see ../lab.yaml (zone, subnets, hosts, Cloudflare DNS, Pi-hole, Tailscale).

Apply from your Mac on the LAN. State files stay **local** (gitignored).

**IaC policy:** Git is source of truth for everything here; see [docs/architecture/iac.md](../docs/architecture/iac.md).

**Shared constants:** [lab.yaml](lab.yaml) — structured as `dns`, `networks` (drury / homelab + hosts), `services`, `tailscale`. Each OpenTofu project reads it via `lab_locals.tf`.

Credentials load from each project's `moon.yml` (`TOFU_SECRET_*` / `TOFU_ENV_*`). Sign in first: `op signin`.

## DNS (`infrastructure/dns/`)

Manages GitHub Pages records (imported) and `*.lab.jacobdrury.com` infra A records.

## UniFi (`infrastructure/unifi/`)

**Note:** Homelab uses **`192.168.5.0/24` (VLAN 5)** — the old Work VLAN, now free. UniFi **Teleport** reserves `192.168.6.0/24`; do not use `.6` for Homelab.

**Firewall:** legacy `LAN_IN` rules (no Zone-Based Firewall required). If you later enable ZBF, migrate `firewall.tf` to zone policies.

Creates **Homelab** VLAN 5 (`192.168.5.0/24`). scarif migrated to `192.168.5.10` (2026-08-30).

## Pi-hole (`infrastructure/pihole/`)

Config-only OpenTofu for the LXC at `192.168.1.11` (block lists, domains, upstreams, local `*.homelab.com`, lab zone forward). Edit `*.auto.tfvars` in repo → `moon run pihole:apply`. Details: [pihole/README.md](pihole/README.md).

## Tailscale (`infrastructure/tailscale/`)

Tailnet DNS + subnet route approval in Git. Split DNS sends `lab.jacobdrury.com` → **Cloudflare** (`1.1.1.1`); enables routes on **homelab02** (interim subnet router). One-time device bootstrap: [tailscale/README.md](tailscale/README.md).

## Moon (from repo root)

`apply` runs `plan` → `init` first. `plan` writes `.tofu.plan` (gitignored); `apply` uses that file.

Moon caching: **`init`** is cached (restores `.terraform/` when lock/config unchanged). **`plan`** and **`apply`** are never cached — they talk to live APIs and apply changes. A cached `init` still satisfies the `plan` dep without re-downloading providers.

Run `moon run <project>:init` manually after clone if you skip the full chain. **`init`** creates `lab_locals.tf` automatically when `../lab.yaml` exists (new infrastructure modules).

```bash
op signin
moon run dns:apply
moon run unifi:apply
moon run pihole:apply
moon run tailscale:apply
```

New OpenTofu project: tag `opentofu` and add `env` entries:

```yaml
env:
  TOFU_SECRET_TF_VAR_my_token: 'op://Homelab/Item Name/credential'
  TOFU_ENV_SOME_FLAG: 'true'   # optional, literal
```

Manual `tofu`: `op read 'op://...'` and export the `TF_VAR_*` yourself.

Full setup: [docs/setup/local-tools.md](../docs/setup/local-tools.md)

## Order

1. `dns` apply — Cloudflare records (public + `*.lab`)
2. `unifi` apply — Homelab VLAN + firewall
3. `pihole` apply — Pi-hole policy (lists, local DNS, lab zone forward)
4. ~~Move scarif to VLAN 5 (`192.168.5.10`); update arr NFS fstab~~ **Done (2026-08-30)**
5. Phase 2 — Talos on yavin
