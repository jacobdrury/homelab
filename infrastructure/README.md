# Infrastructure (OpenTofu)

Apply from your Mac on the LAN. State files stay **local** (gitignored).

Credentials load from each project's `moon.yml` (`TOFU_SECRET_*` / `TOFU_ENV_*`). Sign in first: `op signin`.

## DNS (`infrastructure/dns/`)

Manages GitHub Pages records (imported) and `*.lab.jacobdrury.com` infra A records.

## UniFi (`infrastructure/unifi/`)

**Note:** Homelab uses **`192.168.5.0/24` (VLAN 5)** — the old Work VLAN, now free. UniFi **Teleport** reserves `192.168.6.0/24`; do not use `.6` for Homelab.

**Firewall:** legacy `LAN_IN` rules (no Zone-Based Firewall required). If you later enable ZBF, migrate `firewall.tf` to zone policies.

## Moon (from repo root)

`apply` runs `plan` → `init` first. `plan` writes `.tofu.plan` (gitignored); `apply` uses that file.

Moon caching: **`init`** is cached (restores `.terraform/` when lock/config unchanged). **`plan`** and **`apply`** are never cached — they talk to live APIs and apply changes. A cached `init` still satisfies the `plan` dep without re-downloading providers.

Run `moon run <project>:init` manually after clone if you skip the full chain.

```bash
op signin
moon run dns:apply
moon run unifi:apply
```

New OpenTofu project: tag `opentofu` and add `env` entries:

```yaml
env:
  TOFU_SECRET_TF_VAR_my_token: 'op://Homelab/Item Name/credential'
  TOFU_ENV_SOME_FLAG: 'true'   # optional, literal
```

Manual `tofu`: `op read 'op://...'` and export the `TF_VAR_*` yourself.

Full setup: [docs/setup/local-tools.md](../docs/setup/local-tools.md)

Creates **Homelab** VLAN 5 (`192.168.5.0/24`), then migrate scarif to `192.168.5.10` manually.

## Order

1. `dns` apply — names resolve (public DNS)
2. `unifi` apply — VLAN exists
3. Move scarif to VLAN 5; update arr NFS fstab
4. Phase 2 — Talos on yavin
