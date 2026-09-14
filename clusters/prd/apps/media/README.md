# Media stack

qBittorrent (Mullvad **WG sidecar** + bind `wg0`), Sonarr anime/TV, Prowlarr, Jellyfin on Talos `prd`.
*arr DBs on shared CNPG **`media-pg`**. Download UIs via **Authentik Proxy**; Jellyfin via Envoy → Service (native auth, SQLite on config PVC).

**arr VM:** Compose jellyfin / *arr / qBit should stay **stopped** after cutover (configs archived on disk).

## Prerequisites

1. **1Password** Homelab item **`prd Mullvad WireGuard`** — full Mullvad WireGuard config in the **password** field (`Table = off` under `[Interface]` preferred; sidecar injects if missing).
2. **1Password** **`prd Media Postgres`** — CNPG owner (`username` / `password`).
3. Scarif media tree owned for NFS squash: `nobody:users` (`99:100`) — see [media.md](../../../docs/architecture/media.md).

## Rebuild / migration scripts

Configs originally came from the Proxmox arr VM (not a fresh install):

```bash
./clusters/prd/apps/media/scripts/copy-configs-from-arr.sh
./clusters/prd/apps/media/scripts/migrate-arr-to-postgres.sh   # after media-pg Ready
./clusters/prd/apps/media/scripts/copy-jellyfin-from-arr.sh    # Jellyfin config only (~2.7G)
```

Live wiring: download client → `qbittorrent.media.svc.cluster.local:8080`; indexers → `prowlarr.media.svc.cluster.local:9696`; *arr mounts `/home/data/{anime,tv,downloads}`; Jellyfin mounts `/anime` + `/tv`.

## Layout

| File | Role |
|------|------|
| `media-pg.yaml` | CNPG Cluster + per-app Databases + postgres/auth config helper |
| `storage.yaml` | Static NFS PVs for `media/{anime,tv,downloads}` |
| `qbittorrent.yaml` | qBit + WG sidecar, iSCSI config |
| `sonarr-*.yaml` / `prowlarr.yaml` | *arr Deployments |
| `jellyfin.yaml` | Jellyfin Deployment + Service + HTTPRoute + iSCSI config |
| `httproutes.yaml` | Stub — *arr/qBit URLs owned by Authentik (`resources-media-routes.yaml`) |
| `scripts/` | One-shot VM → PVC and SQLite → Postgres (*arr) |

## Auth

- **Download stack:** Envoy → Authentik embedded outpost → media Services. `/api` (+ Sonarr `/feed`) skipped for Homepage API keys. *arr use `AuthenticationMethod=External`; qBit bypasses auth for private CIDRs (Authentik → backend).
- **Jellyfin:** Envoy → Service; Jellyfin’s own user accounts (no Authentik). Friend Tailscale L7 is Phase 6.
