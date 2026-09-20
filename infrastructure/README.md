# Shared lab constants — see ../lab.yaml (zone, subnets, hosts, Cloudflare DNS, Pi-hole, Tailscale).

**Steady apply:** GitHub Actions `moon ci` on `main`. Mac `moon run …:apply` is break-glass. **State** in Cloudflare R2 (`homelab-tofu-state`); credentials from 1Password **Homelab R2 tofu state**. Setup: [docs/setup/opentofu-ci.md](../docs/setup/opentofu-ci.md).

**IaC policy:** Git is source of truth for everything here; see [docs/architecture/iac.md](../docs/architecture/iac.md).

**Shared constants:** [lab.yaml](lab.yaml) — structured as `dns`, `networks` (drury / homelab + hosts), `services`, `tailscale`. Each OpenTofu project reads it via `lab_locals.tf`.

Local break-glass: credentials from each project's `moon.yml` (`TOFU_SECRET_*` / `TOFU_ENV_*`). Sign in first: `op signin`.

## Cloudflare (`infrastructure/cloudflare/`)

Manages GitHub Pages records (imported), `*.lab.jacobdrury.com` infra A records, and the **R2** bucket `homelab-tofu-state` (OpenTofu remote state).

API token needs **Zone DNS Edit** on `jacobdrury.com` plus **Account Workers R2 Storage Write**.

## UniFi (`infrastructure/unifi/`)

**Note:** Homelab uses **`192.168.5.0/24` (VLAN 5)** — the old Work VLAN, now free. UniFi **Teleport** reserves `192.168.6.0/24`; do not use `.6` for Homelab.

**Firewall:** legacy `LAN_IN` rules (no Zone-Based Firewall required). If you later enable ZBF, migrate `firewall.tf` to zone policies.

Creates **Homelab** VLAN 5 (`192.168.5.0/24`). scarif migrated to `192.168.5.10` (2026-08-30).

**Switch ports** (`devices.tf`): Pro Max 16 **Ports 13 + 5** → Homelab (**yavin** USB 2.5G + onboard 1G). Existing IoT/Drury overrides on that switch are declared too (provider replaces the full override array).

**Networks:** Drury / Homelab / IoT / Guest / Camera are managed resources; DHCP DNS → Pi-hole VIP `.22`.

CI reaches the gateway via Tailscale `--accept-routes`.

## Tailscale (`infrastructure/tailscale/`)

Tailnet DNS, ACL, HTTPS, and route approval in Git. Split DNS sends `lab.jacobdrury.com` → **Cloudflare**; Homelab routes on **k8s Connector** (homelab02 Homelab advertise off). Details: [tailscale/README.md](tailscale/README.md).

## Uptime Kuma (`infrastructure/uptime-kuma/`)

HTTP monitors + public **Lab** status page (`/status/default`). API via Tailscale **L7 Ingress** (`https://uptime-kuma.…ts.net`) — no port-forward. Details: [uptime-kuma/README.md](uptime-kuma/README.md).

```bash
moon run uptime-kuma:apply
```

## Talos (`infrastructure/talos/`)

Bare-metal bootstrap under **`talos/prd/`** (future: `talos/stg/`). Patches + Image Factory schematic in Git; `secrets.yaml` / `generated/` gitignored. See [talos/prd/README.md](talos/prd/README.md).

```bash
cd infrastructure/talos/prd && ./gen.sh
# then apply-config when ready to wipe the Mini
```

## Moon (from repo root)

`apply` runs `plan` → `init` first. `plan` writes `.tofu.plan` (gitignored); `apply` uses that file.

Moon caching: **`init`** is cached (restores `.terraform/` when lock/config unchanged). **`plan`** and **`apply`** are never cached — they talk to live APIs and apply changes. A cached `init` still satisfies the `plan` dep without re-downloading providers.

Run `moon run <project>:init` manually after clone if you skip the full chain. **`init`** creates `lab_locals.tf` automatically when `../lab.yaml` exists (new infrastructure modules).

```bash
op signin
moon run cloudflare:apply
moon run unifi:apply
moon run tailscale:apply
moon run uptime-kuma:apply
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

Moon `dependsOn` + each tofu task’s `^:<task>` so `moon ci` / `moon run` respect this order:

1. `cloudflare` — DNS records + R2 state bucket
2. `unifi` and `tailscale` (parallel; both depend on `cloudflare`)
3. `uptime-kuma` (depends on `tailscale`)

Bootstrap notes: ~~Move scarif to VLAN 5 (`192.168.5.10`); update arr NFS fstab~~ **Done (2026-08-30)**. Phase 2 — Talos on yavin.
