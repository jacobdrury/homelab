# Media download stack

qBittorrent (Mullvad **WG sidecar** + bind `wg0`), Sonarr anime/TV, Prowlarr on Talos `prd`.
*arr DBs on shared CNPG **`media-pg`**. Public UIs via **Authentik Proxy** (not direct HTTPRoutes).

**Still on arr VM (transitional):** Jellyfin only.

## Prerequisites

1. **1Password** Homelab item **`prd Mullvad WireGuard`** — full Mullvad WireGuard config in the **password** field (`Table = off` under `[Interface]` preferred; sidecar injects if missing).
2. **1Password** **`prd Media Postgres`** — CNPG owner (`username` / `password`).
3. Scarif media tree owned for NFS squash: `nobody:users` (`99:100`) — see [media.md](../../../docs/architecture/media.md).

## Rebuild / migration scripts

Configs originally came from the Proxmox arr VM (not a fresh install):

```bash
./clusters/prd/apps/media/scripts/copy-configs-from-arr.sh
./clusters/prd/apps/media/scripts/migrate-arr-to-postgres.sh   # after media-pg Ready
```

Live wiring: download client → `qbittorrent.media.svc.cluster.local:8080`; indexers → `prowlarr.media.svc.cluster.local:9696`; mounts `/home/data/{anime,tv,downloads}`.

## Layout

| File | Role |
|------|------|
| `media-pg.yaml` | CNPG Cluster + per-app Databases + postgres/auth config helper |
| `storage.yaml` | Static NFS PVs for `media/{anime,tv,downloads}` |
| `qbittorrent.yaml` | qBit + WG sidecar, iSCSI config |
| `sonarr-*.yaml` / `prowlarr.yaml` | *arr Deployments |
| `httproutes.yaml` | Stub — public URLs owned by Authentik (`resources-media-routes.yaml`) |
| `scripts/` | One-shot VM → PVC and SQLite → Postgres |

## Auth

Browser: Envoy → Authentik embedded outpost → media Services. `/api` (+ Sonarr `/feed`) skipped for Homepage API keys. *arr use `AuthenticationMethod=External`; qBit bypasses auth for private CIDRs (Authentik → backend).
