# Media stack

qBittorrent (Mullvad **WG sidecar** + bind `wg0`), Sonarr anime/TV, Prowlarr, Jellyfin, Seerr, Cleanuparr, Unmanic on Talos `prd`.
*arr + Seerr DBs on shared CNPG **`media-pg`**. Download UIs via **Authentik Proxy**; Jellyfin + Seerr via Envoy → Service (native auth).

**arr VM:** Compose jellyfin / *arr / qBit should stay **stopped** after cutover (configs archived on disk).

## Prerequisites

1. **1Password** Homelab item **`prd Mullvad WireGuard`** — full Mullvad WireGuard config in the **password** field (`Table = off` under `[Interface]` preferred; sidecar injects if missing, strips `DNS=`, adds `PersistentKeepalive`). Health for Kuma: Service port **8081**.
2. **1Password** **`prd Media Postgres`** — CNPG owner (`username` / `password`).
3. Scarif media tree owned for NFS squash: `nobody:users` (`99:100`) — see [media.md](../../../docs/architecture/media.md).

Live wiring: download client → `qbittorrent.media.svc.cluster.local:8080`; indexers → `prowlarr.media.svc.cluster.local:9696`; *arr mounts `/home/data/{anime,tv,downloads}`; Jellyfin mounts `/anime` + `/tv`; Cleanuparr mounts the same downloads path for orphan scans; Unmanic mounts `/library/{anime,tv}` (RW remux).

## Layout

| File | Role |
|------|------|
| `media-pg.yaml` | CNPG Cluster + per-app Databases + postgres/auth config helper |
| `storage.yaml` | Static NFS PVs for `media/{anime,tv,downloads}` |
| `qbittorrent.yaml` | qBit + WG sidecar, iSCSI config |
| `sonarr-*.yaml` / `prowlarr.yaml` | *arr Deployments |
| `jellyfin.yaml` | Jellyfin Deployment + Service + HTTPRoute + iSCSI config |
| `seerr.yaml` | Seerr Deployment + Service + HTTPRoute |
| `cleanuparr.yaml` | Cleanuparr Deployment + Service + iSCSI config PVC (DB on `media-pg`) |
| `unmanic.yaml` | Unmanic Deployment + Service + iSCSI config/cache PVCs (SQLite; NFS libraries) |
| `unmanic-configure.yaml` | PostSync Job: libraries + keep_stream_by_language plugin via Unmanic API |
| `httproutes.yaml` | Stub — *arr/qBit/Cleanuparr/Unmanic URLs owned by Authentik (`resources-media-routes.yaml`) |

## Auth

- **Download stack:** Envoy → Authentik embedded outpost → media Services. `/api` (+ Sonarr `/feed`) skipped for Homepage API keys; Cleanuparr `/health` and Unmanic `/unmanic/api/v2/version/read` skipped for Kuma. *arr use `AuthenticationMethod=External`; qBit bypasses auth for private CIDRs (Authentik → backend).
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

## Cleanuparr setup (post-deploy)

Config lives in the Cleanuparr UI (SQLite on the config PVC). Open `https://cleanuparr.lab.jacobdrury.com` after Argo sync and CI OpenTofu apply (DNS + Kuma).

### Connections

| Integration | Host | Notes |
|-------------|------|-------|
| qBittorrent | `http://qbittorrent.media.svc.cluster.local:8080` | Same WebUI user/pass as Homelab **`qBittorrent`** |
| Sonarr Anime | `http://sonarr-anime.media.svc.cluster.local:8989` | API key from Sonarr General |
| Sonarr TV | `http://sonarr-tv.media.svc.cluster.local:8990` | API key from Sonarr General |

In **General**, enable **Disable Auth for Local Addresses** so Authentik Proxy → Cleanuparr is not double-gated (private CIDRs include the outpost). Keep Internet Connectivity Check on so queue strikes pause during an outage.

### Queue Cleaner

1. Enable Queue Cleaner (basic interval, e.g. every 5 minutes).
2. **Failed imports:** Max Strikes `3`, Pattern Mode **Include**, patterns:
   - `Not an upgrade for existing episode file`
   - `Not a Custom Format upgrade`
3. Stalled / slow / metadata: Max Strikes `3` (or higher), reset strikes on real progress. Prefer **Ignore Private** / careful **Delete Private** if you care about H&R.
4. Leave messages like `manual import required`, TBA title, and title mismatch out of the Include list so those stay for hand review.

### Malware Blocker

Enable with the official list `https://cleanuparr.pages.dev/static/blacklist`. Ignore private torrents if you want to avoid touching private-tracker packs.

### Seeker

- Replacement search stays on for both Sonarrs (fires when Queue Cleaner removes something).
- **Proactive search:** enable only on **Sonarr Anime**. Leave Sonarr TV proactive off.
- Prefer a moderate interval (10–15+ minutes), round-robin if you later add more instances, and an active download limit so it does not pile onto a busy qBit.

### Download Cleaner + orphaned files

Orphaned scanning runs inside the Download Cleaner job. Enable Download Cleaner, then under qBittorrent → Orphaned Files:

| Setting | Value |
|---------|-------|
| Scan directories | `/home/data/downloads` |
| Orphaned directory | `/home/data/downloads/orphaned` |
| Min file age | `24` hours (start conservative) |
| Exclude patterns | incomplete dir / `.!qB` / `*.parts` as needed for your qBit layout |
| Purge orphaned after | leave empty until you trust the moves |

Create `/home/data/downloads/orphaned` once (same NFS share; `nobody:users`). Skip aggressive seeding-ratio rules until qBit’s own limits are understood; orphans do not require them.

### DNS and Kuma

On merge to `main`, GitHub Actions `moon ci :apply` updates Cloudflare app hosts from `lab.yaml` and Uptime Kuma monitors. Mac `moon run cloudflare:apply` / `uptime-kuma:apply` is break-glass only — [opentofu-ci](../../../docs/setup/opentofu-ci.md).

## Unmanic

UI: `https://unmanic.lab.jacobdrury.com` (Authentik Proxy). Config/SQLite on iSCSI; remux cache on iSCSI; libraries on scarif NFS.

**Desired remux config** is applied by `unmanic-configure.yaml` (Argo PostSync Job). No UI setup for libraries/plugins. It sets:

| Area | Setting |
|------|---------|
| Libraries | Anime → `/library/anime`, TV → `/library/tv` (scanner + inotify on; free tier = 2) |
| Plugin | `keep_stream_by_language` from yajrendrag repo |
| Anime keep | audio `jpn,eng` (JP default via reorder); subs `eng`; fail-safe + keep undefined |
| TV keep | audio `eng,jpn` (EN default); subs `eng` |
| Workers | 2 |
| Not configured | video transcode / H.265 (leave off) |

`reorder_kept` sets the file’s default **audio** disposition from the first listed language. English is usually the only remaining subtitle. For reliable auto-subs in Jellyfin, set the user preferred subtitle language to English as well. Edit `ANIME_PLUGIN_SETTINGS` / `TV_PLUGIN_SETTINGS` in the configure ConfigMap to change policy.

### DNS and Kuma

On merge to `main`, CI also adds `unmanic.lab` and the Kuma probe on `/unmanic/api/v2/version/read`.
