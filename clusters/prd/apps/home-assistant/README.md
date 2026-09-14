# Home Assistant

Talos `prd` Container install (not HA OS). Config on **scarif-iscsi**; recorder on CNPG **`home-assistant-pg`**; SSO via Authentik OIDC ([hass-oidc-auth](https://integrations.goauthentik.io/miscellaneous/home-assistant/)).

**Source:** Proxmox VM 105 `home-assistant` @ `192.168.2.8` (HA OS) — stop / `onboot=0` after cutover.

## Prerequisites

1. **1Password** Homelab **`prd Home Assistant Postgres`** — CNPG owner (`username` / `password`).
2. **1Password** Homelab **`prd Home Assistant OIDC`** — OAuth2 client secret in the **password** field (same value Authentik blueprint + HA `secrets.yaml` use). Generate a strong random secret before first sync.
3. SSH to HA OS (`HA_HOST`, default `root@192.168.2.8`) with access to `/config` (SSH addon or console).

## Cutover

```bash
source connect/env.sh

# After Argo has created the ns / PVC / CNPG (and 1Password items exist):
./clusters/prd/apps/home-assistant/scripts/copy-config-from-haos.sh
./clusters/prd/apps/home-assistant/scripts/migrate-recorder-to-postgres.sh
```

Then confirm `https://homeassistant.lab.jacobdrury.com` (UI + websocket) and Authentik login (`/auth/oidc/welcome`). Keep a local HA admin as break-glass until SSO is proven.

If the migrated `configuration.yaml` already defines top-level `http:`, `recorder:`, or `auth_oidc:`, remove those blocks so the GitOps package (`packages/homelab.yaml`) owns them.

## Layout

| File | Role |
|------|------|
| `home-assistant-pg.yaml` | ExternalSecrets + CNPG Cluster |
| `homelab-package.yaml` | GitOps `packages/homelab.yaml` (`http` / `recorder` / `auth_oidc`) |
| `home-assistant.yaml` | PVC, Deployment, Service, HTTPRoute |
| `scripts/` | HA OS → PVC copy + SQLite → Postgres |

## Auth

Envoy → Service (native HA + OIDC custom component). **Not** Authentik Proxy. Redirect URI: `https://homeassistant.lab.jacobdrury.com/auth/oidc/callback`. Blueprint: `clusters/prd/apps/authentik/blueprints-homeassistant.yaml`.

## Notes

- No USB radios (inventory); ClusterIP only — revisit `hostNetwork` if mDNS/SSDP discovery is required.
- Image pinned to `2026.9.2` (+ digest); bump deliberately.
- Homepage tile and Uptime Kuma monitor already use `homeassistant.lab.jacobdrury.com`.
