# Home Assistant

Live on Talos `prd` (Container install, not HA OS). Config on **scarif-iscsi**; recorder on CNPG **`home-assistant-pg`**; SSO via Authentik OIDC ([hass-oidc-auth](https://integrations.goauthentik.io/miscellaneous/home-assistant/)).

**URL:** `https://homeassistant.lab.jacobdrury.com` · Authentik: `/auth/oidc/welcome`

## Layout

| File | Role |
|------|------|
| `home-assistant-pg.yaml` | ExternalSecrets + CNPG Cluster |
| `homelab-package.yaml` | GitOps `packages/homelab.yaml` (`http` / `recorder` / `auth_oidc`) |
| `home-assistant.yaml` | PVC, Deployment, Service, HTTPRoute |
| `scripts/` | One-time HA OS → PVC copy + SQLite → Postgres (complete) |

## Auth

Envoy → Service (native HA + OIDC custom component). **Not** Authentik Proxy. Redirect URI: `https://homeassistant.lab.jacobdrury.com/auth/oidc/callback`. Blueprint: `clusters/prd/apps/authentik/blueprints-homeassistant.yaml`.

**SSO ↔ local user:** Linked (HA + Authentik username **`jacob`**). `automatic_user_linking` is off; re-enable only if you need to link another account.

## Secrets

1. Homelab **`prd Home Assistant Postgres`** — CNPG owner (`username` / `password`).
2. Homelab **`prd Home Assistant OIDC`** — OAuth2 client secret in the **password** field.

## Notes

- No USB radios; ClusterIP only — UniFi **Homelab → IoT** (device APIs) and **IoT → Envoy `.21:80/443`** (webhooks).
- Image pinned (`2026.8.3`); bump deliberately (skip `2026.9.1` until listen-addr fix).
- Homepage + Uptime Kuma use `homeassistant.lab.jacobdrury.com`.
- Legacy HA OS VM 105 @ `192.168.2.8` — stop / `onboot=0` after soak.
