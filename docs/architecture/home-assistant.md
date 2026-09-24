# Home Assistant

Live on Talos `prd` (Phase 3). Leans: [decisions](../decisions.md) · app: [apps/home-assistant](../../clusters/prd/apps/home-assistant/).

## Placement

| Piece | Choice |
|-------|--------|
| Runtime | Official **Container** image (`ghcr.io/home-assistant/home-assistant:**2026.8.3**`) — not HA OS / Supervisor. Skip `2026.9.1` until listen-addr regression is fixed |
| Namespace | `home-assistant` |
| Config | RWO PVC on **`scarif-iscsi`** (`/config`) |
| Recorder DB | CNPG Cluster **`home-assistant-pg`** (dedicated; not `media-pg`) |
| Ingress | Envoy HTTPRoute → Service `:8123` — `https://homeassistant.lab.jacobdrury.com` |
| Auth | Authentik **OIDC** ([hass-oidc-auth](https://integrations.goauthentik.io/miscellaneous/home-assistant/)). Not Authentik Proxy |
| HTTP / proxy | UI (**Settings → System → Network**) / `.storage/http` — **no YAML `http:`** (ignored after 2026.8). Trusted proxies: `10.0.0.0/8`, `192.168.5.0/24` |
| Radios | None — no USB passthrough |
| Network | **`hostNetwork`** + `dnsPolicy: ClusterFirstWithHostNet` so zeroconf hears Homelab mDNS (HomeKit Device / ESPHome discovery). UI still **Envoy → Service `:8123`** — `https://homeassistant.lab.jacobdrury.com` unchanged. Namespace PSA **privileged** (required for hostNetwork). |
| IoT | UniFi **Homelab → IoT** allow + return; **IoT → Homelab Envoy `.21:80/443`** for webhooks; **mDNS** on Homelab + IoT — [networking](networking.md) |

## Auth (SSO)

| Piece | Detail |
|-------|--------|
| Blueprint | `clusters/prd/apps/authentik/blueprints-homeassistant.yaml` — app slug **`homeassistant`** |
| Groups claim | Custom Authentik ScopeMapping **Home Assistant groups** (authentik 2026.8 has no built-in `scope-groups`) |
| Admin mapping | Authentik group **`authentik Admins`** → HA `system-admin` / owner (`roles.admin` in package) |
| Local user | **`jacob`** (break-glass password). Linked to SSO; `automatic_user_linking: false` |
| Redirect | `https://homeassistant.lab.jacobdrury.com/auth/oidc/callback` |

Without the groups claim + `authentik Admins` mapping, SSO logins demote the linked user to `system-users`.

## GitOps package

`homelab-package.yaml` → `/config/packages/homelab.yaml`: **recorder** + **auth_oidc** only. Do not re-add `http:`.

## Ops notes

- **Companion app:** one URL — `https://homeassistant.lab.jacobdrury.com` (LAN + Tailscale). No `192.168.2.8`.
- **HACS / custom components:** live on the PVC under `custom_components/` (not Git). Image bumps may need HACS + integration updates (e.g. HACS **2.0.5** for 2026.8).
- **DNS:** HA Deployment sets `dnsConfig.ndots: "2"`. Cluster CoreDNS should reach Cloudflare quickly — Homelab→Pi-hole UDP/53 is unreliable; see [networking](networking.md).

## Legacy VM

Proxmox VM 105 (`192.168.2.8`, VLAN 2) was the HA OS source. Config + SQLite→Postgres cutover done. **Stopped** / `onboot=0`; keep disk until trusted.

## Related

- [platform](platform.md) · [networking](networking.md) · [secrets](secrets.md)
- [media](media.md) (prior Phase 3 pattern: CNPG + Envoy)
