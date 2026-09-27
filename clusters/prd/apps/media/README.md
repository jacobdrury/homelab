# Media stack

qBittorrent (Mullvad **WG sidecar** + bind `wg0`), Sonarr anime/TV, Prowlarr, Jellyfin, Seerr on Talos `prd`.
*arr + Seerr DBs on shared CNPG **`media-pg`**. Download UIs via **Authentik Proxy**; Jellyfin + Seerr via Envoy → Service (native auth).

**arr VM:** Compose jellyfin / *arr / qBit should stay **stopped** after cutover (configs archived on disk).

## Prerequisites

1. **1Password** Homelab item **`prd Mullvad WireGuard`** — full Mullvad WireGuard config in the **password** field (`Table = off` under `[Interface]` preferred; sidecar injects if missing).
2. **1Password** **`prd Media Postgres`** — CNPG owner (`username` / `password`).
3. Scarif media tree owned for NFS squash: `nobody:users` (`99:100`) — see [media.md](../../../docs/architecture/media.md).

Live wiring: download client → `qbittorrent.media.svc.cluster.local:8080`; indexers → `prowlarr.media.svc.cluster.local:9696`; *arr mounts `/home/data/{anime,tv,downloads}`; Jellyfin mounts `/anime` + `/tv`.

## Layout

| File | Role |
|------|------|
| `media-pg.yaml` | CNPG Cluster + per-app Databases + postgres/auth config helper |
| `storage.yaml` | Static NFS PVs for `media/{anime,tv,downloads}` |
| `qbittorrent.yaml` | qBit + WG sidecar, iSCSI config |
| `sonarr-*.yaml` / `prowlarr.yaml` | *arr Deployments |
| `jellyfin.yaml` | Jellyfin Deployment + Service + HTTPRoute + iSCSI config |
| `seerr.yaml` | Seerr Deployment + Service + HTTPRoute |
| `httproutes.yaml` | Stub — *arr/qBit URLs owned by Authentik (`resources-media-routes.yaml`) |

## Auth

- **Download stack:** Envoy → Authentik embedded outpost → media Services. `/api` (+ Sonarr `/feed`) skipped for Homepage API keys. *arr use `AuthenticationMethod=External`; qBit bypasses auth for private CIDRs (Authentik → backend).
- **Jellyfin / Seerr:** Envoy → Service; Jellyfin user accounts (Seerr signs in via Jellyfin).

## Seerr setup (post-deploy)

1. Open `https://seerr.lab.jacobdrury.com` and complete the wizard with **Jellyfin** as the media server.
2. **Settings → Services** — use **in-cluster** hosts (public *arr URLs hit Authentik Proxy):

| Service | Hostname | Port | External URL |
|---------|----------|------|--------------|
| Jellyfin | `jellyfin.media.svc.cluster.local` | `8096` | `https://jellyfin.lab.jacobdrury.com` |
| Sonarr Anime | `sonarr-anime.media.svc.cluster.local` | `8989` | `https://sonarr.lab.jacobdrury.com` |
| Sonarr TV | `sonarr-tv.media.svc.cluster.local` | `8990` | `https://sonarr-tv.lab.jacobdrury.com` |

   API keys: Sonarr **Settings → General**; Jellyfin API key from dashboard. Mark one Sonarr as default for TV; use the other for anime (tags/root folders as you prefer). There is **no Radarr** in this lab yet. Seerr does **not** talk to Prowlarr — indexers stay on Sonarr via Prowlarr.

3. Paste Seerr’s API key (**Settings → General**) into Homelab **`prd Homepage media API keys`** field `seerr` (placeholder until then).
