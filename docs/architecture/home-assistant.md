# Home Assistant

Phase 3 workload on Talos `prd`. Leans: [decisions](../decisions.md) · cutover checklist: [roadmap](../roadmap.md).

## Placement

| Piece | Choice |
|-------|--------|
| Runtime | Official **Container** image (`ghcr.io/home-assistant/home-assistant`) — not HA OS / Supervisor |
| Namespace | `home-assistant` — [apps/home-assistant](../../clusters/prd/apps/home-assistant/) |
| Config | RWO PVC on **`scarif-iscsi`** (`/config`) |
| Recorder DB | CNPG Cluster **`home-assistant-pg`** (dedicated; not `media-pg`) |
| Ingress | Envoy HTTPRoute → Service `:8123` — `https://homeassistant.lab.jacobdrury.com` |
| Auth | Authentik **OIDC** via [hass-oidc-auth](https://integrations.goauthentik.io/miscellaneous/home-assistant/) (custom component). Not Authentik Proxy |
| Radios | None today — no USB passthrough; ClusterIP only |

## Auth detail

Authentik blueprint (`blueprints-homeassistant.yaml`) creates OAuth2 provider + app slug **`homeassistant`**. HA package sets `auth_oidc` discovery URL and client id/secret. Redirect: `/auth/oidc/callback`. Keep a local HA admin until SSO is verified.

## Cutover source

Proxmox VM 105 on pc (black) — HA OS @ `192.168.2.8` (VLAN 2). Scripts copy `/config` and migrate `home-assistant_v2.db` → Postgres (pgloader). URL unchanged at cutover.

## Related

- [platform](platform.md) · [networking](networking.md) · [secrets](secrets.md)
- [media](media.md) (prior Phase 3 pattern: CNPG + Envoy)
