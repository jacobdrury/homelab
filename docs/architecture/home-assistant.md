# Home Assistant

Live on Talos `prd` (Phase 3). Leans: [decisions](../decisions.md).

## Placement

| Piece | Choice |
|-------|--------|
| Runtime | Official **Container** image (`ghcr.io/home-assistant/home-assistant`) — not HA OS / Supervisor |
| Namespace | `home-assistant` — [apps/home-assistant](../../clusters/prd/apps/home-assistant/) |
| Config | RWO PVC on **`scarif-iscsi`** (`/config`) |
| Recorder DB | CNPG Cluster **`home-assistant-pg`** (dedicated; not `media-pg`) |
| Ingress | Envoy HTTPRoute → Service `:8123` — `https://homeassistant.lab.jacobdrury.com` |
| Auth | Authentik **OIDC** via [hass-oidc-auth](https://integrations.goauthentik.io/miscellaneous/home-assistant/) (custom component). Not Authentik Proxy. Local user **`jacob`** linked to Authentik; `automatic_user_linking` off |
| Radios | None today — no USB passthrough; ClusterIP only |
| IoT reachability | UniFi **Homelab → IoT** allow + return; **IoT → Homelab Envoy `.21:80/443`** for device webhooks — [networking](networking.md) |

## Auth detail

Authentik blueprint (`blueprints-homeassistant.yaml`) creates OAuth2 provider + app slug **`homeassistant`**. HA package sets `auth_oidc` discovery URL and client id/secret. Redirect: `/auth/oidc/callback`. Keep a local HA admin as break-glass.

## Legacy VM

Proxmox VM 105 (`192.168.2.8`, VLAN 2) was the HA OS source. Config + recorder migrated; stop / `onboot=0` when soak is done. Scripts remain under `apps/home-assistant/scripts/` for reference only.

## Related

- [platform](platform.md) · [networking](networking.md) · [secrets](secrets.md)
- [media](media.md) (prior Phase 3 pattern: CNPG + Envoy)
