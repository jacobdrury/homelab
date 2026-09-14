# Home Assistant

Live on Talos `prd` (Container install, not HA OS). Config on **scarif-iscsi**; recorder on CNPG **`home-assistant-pg`**; SSO via Authentik OIDC ([hass-oidc-auth](https://integrations.goauthentik.io/miscellaneous/home-assistant/)).

**URL:** `https://homeassistant.lab.jacobdrury.com` · Authentik: `/auth/oidc/welcome`  
**Arch:** [docs/architecture/home-assistant.md](../../../../docs/architecture/home-assistant.md)

## Layout

| File | Role |
|------|------|
| `home-assistant-pg.yaml` | ExternalSecrets + CNPG Cluster |
| `homelab-package.yaml` | GitOps `packages/homelab.yaml` (`recorder` / `auth_oidc` only — **no `http:`**) |
| `home-assistant.yaml` | PVC, Deployment (`dnsConfig.ndots: "2"`), Service, HTTPRoute |
| `scripts/` | One-time HA OS → PVC copy + SQLite → Postgres (complete; sequence reset included) |

## Auth

Envoy → Service (native HA + OIDC). **Not** Authentik Proxy. Blueprint: `../authentik/blueprints-homeassistant.yaml` (includes custom **Home Assistant groups** scope mapping).

**SSO ↔ local user:** **`jacob`** + Authentik group **`authentik Admins`** → HA owner. `automatic_user_linking: false`.

**HTTP / reverse proxy:** UI (**Settings → System → Network**) / `.storage/http`. Trusted proxies: `10.0.0.0/8`, `192.168.5.0/24`.

## Secrets

1. Homelab **`prd Home Assistant Postgres`** — CNPG owner (`username` / `password`).
2. Homelab **`prd Home Assistant OIDC`** — OAuth2 client secret in the **password** field.

## Notes

- Image pinned **`2026.8.3`** (skip `2026.9.1` listen-addr regression).
- IoT: UniFi Homelab→IoT + IoT→Envoy `.21:80/443`.
- Homepage + Uptime Kuma: `homeassistant.lab.jacobdrury.com`.
- Custom components (HACS, etc.) live on the PVC — bump with Core upgrades as needed.
- Legacy HA OS VM 105 @ `192.168.2.8` — stop / `onboot=0` after soak.
