# Media stack

qBittorrent (Mullvad **WG sidecar** + bind `wg0`), Sonarr anime/TV, Prowlarr, Jellyfin, Seerr, Cleanuparr, Unmanic, Recyclarr on Talos `prd`.
*arr + Seerr DBs on shared CNPG **`media-pg`**. Download UIs via **Authentik Proxy**; Jellyfin + Seerr via Envoy → Service (native auth).

**arr VM:** Compose jellyfin / *arr / qBit should stay **stopped** after cutover (configs archived on disk).

## Prerequisites

1. **1Password** Homelab item **`prd Mullvad WireGuard`** — full Mullvad WireGuard config in the **password** field (`Table = off` under `[Interface]` preferred; sidecar injects if missing, strips `DNS=`, adds `PersistentKeepalive`). Health for Kuma: Service port **8081**.
2. **1Password** **`prd Media Postgres`** — CNPG owner (`username` / `password`).
3. Scarif media tree owned for NFS squash: `nobody:users` (`99:100`) — see [media.md](../../../docs/architecture/media.md).

Live wiring: download client → `qbittorrent.media.svc.cluster.local:8080`; indexers → `prowlarr.media.svc.cluster.local:9696`; *arr / qBit / Cleanuparr mount the parent NFS share at `/home/data` (subdirs `anime` / `tv` / `downloads`); Jellyfin mounts `/anime` + `/tv` via `subPath`; Cleanuparr orphan scans use `/home/data/downloads`; Unmanic mounts `/library/{anime,tv}` via `subPath` (RW remux).

One parent PV keeps anime, tv, and downloads on a single filesystem so Sonarr can hardlink imports. Root folder paths stay `/home/data/anime` and `/home/data/tv` (no Sonarr DB rewrite).

## Layout

| File | Role |
|------|------|
| `media-pg.yaml` | CNPG Cluster + per-app Databases + postgres/auth config helper |
| `storage.yaml` | Static NFS PV/PVC for parent share `/mnt/disks/ZXA0VZBA/media` |
| `qbittorrent.yaml` | qBit + WG sidecar, iSCSI config |
| `sonarr-*.yaml` / `prowlarr.yaml` | *arr Deployments |
| `jellyfin.yaml` | Jellyfin Deployment + Service + HTTPRoute + iSCSI config |
| `seerr.yaml` | Seerr Deployment + Service + HTTPRoute |
| `cleanuparr.yaml` | Cleanuparr Deployment + Service + iSCSI config PVC (DB on `media-pg`) |
| `cleanuparr-configure.yaml` | PostSync Job: API bootstrap (connections + cleaners + Seeker) |
| `unmanic.yaml` | Unmanic Deployment + Service + iSCSI config/cache PVCs (SQLite; NFS libraries) |
| `unmanic-configure.yaml` | PostSync Job: libraries + keep_stream_by_language plugin via Unmanic API |
| `recyclarr.yaml` | Recyclarr CronJob + PostSync Job: TRaSH CFs/profiles → sonarr-anime + sonarr-tv (no UI) |
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

## Cleanuparr setup

UI: `https://cleanuparr.lab.jacobdrury.com` (Authentik Proxy). App DB on `media-pg`; `/config` PVC is keys/logs only.

**First browser visit:** complete Cleanuparr’s admin wizard once, then **General → Authentication**: Disable Auth for Local Addresses **on**, Trust Forwarded Headers **off** (Authentik already gates the URL).

**Desired app config** is applied by `cleanuparr-configure.yaml` (Argo PostSync Job). It uses ExternalSecret `cleanuparr-bootstrap` (same 1Password fields as Homepage media/qBit) and sets:

| Area | Setting |
|------|---------|
| Connections | qBit + Sonarr Anime + Sonarr TV (in-cluster DNS) |
| General | Internet connectivity check on (`github.com`, `1.1.1.1`); Disable Auth for Local Addresses on (Homepage + configure Job) |
| Queue Cleaner | Failed-import Include patterns for non-upgrades (3 strikes); stalled/slow rules; metadata strikes |
| Malware Blocker | Official Sonarr blacklist; ignore private |
| Download Cleaner | Enabled; orphaned scan `/home/data/downloads` → `/home/data/downloads/orphaned` (24h min age; no auto-purge) |
| Unlinked Downloads | On for qBit; move to category `cleanuparr-unlinked`; categories `sonarr-anime` / `sonarr-tv`; ignore root `/home/data/downloads` |
| Seeding rule | `Unlinked downloads` → category `cleanuparr-unlinked`; delete torrent + source files immediately (`maxSeedTime` 0); privacy Both |
| Seeker | Replacement search on; proactive search **Sonarr Anime only** (15m interval) |

Create `/home/data/downloads/orphaned` on the NFS share if missing (`nobody:users`). Other seeding-ratio rules stay unset.

After the parent NFS hardlink cutover, Unlinked Downloads moves finished torrents with `nlink` 1 (pre-cutover copies, or anything Sonarr no longer hardlinks) into `cleanuparr-unlinked`, and the seeding rule removes them. New hardlinked imports (`nlink` ≥ 2) stay in `sonarr-anime` / `sonarr-tv`.

### DNS and Kuma

On merge to `main`, GitHub Actions `moon ci :apply` updates Cloudflare app hosts from `lab.yaml` and Uptime Kuma monitors. Mac `moon run cloudflare:apply` / `uptime-kuma:apply` is break-glass only — [opentofu-ci](../../../docs/setup/opentofu-ci.md).

## Hardlink cutover (sibling PVs → parent PV)

Git replace `media-anime` / `media-tv` / `media-downloads` with one `media` PV/PVC. Live apply needs a short *arr / qBit / Cleanuparr / Jellyfin / Unmanic downtime while mounts swap. Data on scarif is unchanged; only the Kubernetes mount path changes.

1. Scale down or pause consumers that mount the old claims (Sonarr ×2, qBit, Cleanuparr, Jellyfin, Unmanic).
2. Delete the three old PVCs, then the three old PVs. Reclaim policy is `Retain`, so Unraid files stay. Clear leftover `claimRef` on Released PVs if you recreated names, or use the new `media` names from Git.
3. Apply `storage.yaml` so PV `media` + PVC `media` bind (`claimRef` + `volumeName` already pair them).
4. Roll the Deployments that mount `claimName: media` (parent at `/home/data`, or Jellyfin/Unmanic `subPath`).
5. Smoke paths in a Sonarr pod: `ls /home/data/{anime,tv,downloads}` and confirm root folders still point at `/home/data/anime` and `/home/data/tv`.
6. Grab a new episode (or import one already in downloads). In the Sonarr pod, `stat` the library file and the download path; both should show the same inode and `Links` ≥ 2. Older library files imported under sibling mounts remain separate copies (nlink 1); only new imports hardlink. Reclaiming that double space means re-importing later, which this cutover does not do.

Details: [media.md](../../../docs/architecture/media.md).

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

## Recyclarr

No UI. Daily CronJob (`15 5 * * *`, America/Chicago) plus Argo PostSync Job run `recyclarr sync` against **sonarr-anime** and **sonarr-tv**. API keys from Homelab **`prd Homepage media API keys`** fields `sonarr-anime` / `sonarr-tv` (same item as Homepage / Cleanuparr bootstrap).

### sonarr-anime

TRaSH anime Remux-1080p (`trash_id` `20e0fc959f1f1704bed501f23bdae76f`, Sonarr name `Remux-1080p - Anime`):

| Override | Value |
|----------|-------|
| Uncensored CF score | `101` (not template default `0`) |
| Upgrade until quality | `Bluray 1080p` group; **not** 2160p |
| Upgrade until score | `10000` |
| Min format score | `100` |
| 2160p WEB/Remux | Allowed **above** the cutoff |

### sonarr-tv

TRaSH WEB-1080p (`trash_id` `72dae194fc92bf828f32cde7744e51a1`, Sonarr name `TV`):

| Override | Value |
|----------|-------|
| Upgrade until quality | `WEB 1080p`; **not** 2160p |
| Upgrade until score | `10000` |
| Min format score | `0` |
| 2160p WEB/Remux | Allowed **above** the cutoff (guide disables these) |
| Lower qualities / Bluray 1080p | Disallowed (guide stock) |

Edit the ConfigMap in `recyclarr.yaml` to change policy. No Homepage, Kuma, Authentik, or DNS for this app.
