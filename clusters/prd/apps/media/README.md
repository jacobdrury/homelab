# Media download stack (Phase 3)

qBittorrent (Mullvad **WG sidecar** + bind `wg0`), Sonarr anime/TV, Prowlarr.
Jellyfin remains on the arr VM via transitional routes. *arr DBs on shared CNPG **`media-pg`**.

## Prerequisites

1. **1Password** Homelab item **`prd Mullvad WireGuard`** — paste the full Mullvad WireGuard config into the **password** field. Prefer adding `Table = off` under `[Interface]` (the sidecar also injects this if missing).
2. **1Password** **`prd Media Postgres`** — CNPG owner (`username` / `password`).
3. Scarif media tree owned for NFS squash: `nobody:users` (`99:100`) — see [media.md](../../../docs/architecture/media.md).

## Config copy (not a fresh install)

Live settings come from the Proxmox arr VM. After Argo creates empty iSCSI PVCs:

```bash
# From a host that can SSH to arr + use kubectl (connect/prd):
./clusters/prd/apps/media/scripts/copy-configs-from-arr.sh
```

The script: stops Compose for the four apps → tar configs → untar into PVCs via a helper pod → `chown 99:100` → leaves Jellyfin running.

**Post-copy fixes** (in the UIs or config files):

| App | Fix |
|-----|-----|
| qBittorrent | Network interface = **`wg0`**; WebUI **8080** |
| Sonarr ×2 | Download client → **`qbittorrent.media.svc.cluster.local:8080`**; indexers → **`prowlarr.media.svc.cluster.local:9696`** |
| Prowlarr | Apps → in-cluster Sonarr Services |
| Paths | Keep Compose mounts: `/home/data/{anime,tv,downloads}` |
| Postgres | `./clusters/prd/apps/media/scripts/migrate-arr-to-postgres.sh` after `media-pg` is Ready |

## Cutover (HTTPRoutes)

Done when `httproutes.yaml` is in the Argo include and transitional Backends for those four apps are removed. Jellyfin stays transitional.

## Layout

| File | Role |
|------|------|
| `media-pg.yaml` | CNPG Cluster + per-app Databases + postgres config helper |
| `storage.yaml` | Static NFS PVs for `media/{anime,tv,downloads}` |
| `qbittorrent.yaml` | qBit + WG sidecar, iSCSI config |
| `sonarr-*.yaml` / `prowlarr.yaml` | *arr Deployments |
| `httproutes.yaml` | Lab URLs |
| `scripts/copy-configs-from-arr.sh` | VM → PVC migration |
| `scripts/migrate-arr-to-postgres.sh` | SQLite → media-pg |
