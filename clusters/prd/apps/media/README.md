# Media download stack (Phase 3)

qBittorrent (Mullvad **WG sidecar** + bind `wg0`), Sonarr anime/TV, Prowlarr.
Jellyfin remains on the arr VM via transitional routes.

## Prerequisites

1. **1Password** Homelab item **`prd Mullvad WireGuard`** with field **`wg0.conf`** (full Mullvad WireGuard config). Prefer adding `Table = off` under `[Interface]` (the sidecar also injects this if missing) so the tunnel does not steal the pod default route.
2. Scarif media tree owned for NFS squash: `nobody:users` (`99:100`) — see [media.md](../../../docs/architecture/media.md).

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
| qBittorrent | Options → Advanced → Network interface = **`wg0`** |
| Sonarr ×2 | Download client host `localhost` → **`qbittorrent.media.svc.cluster.local`** port **8080** |
| Paths | Mounts are `/anime`, `/tv`, `/downloads` — align root folders if Compose used different paths |

## Cutover (HTTPRoutes)

1. Smoke via port-forward.
2. Add `httproutes.yaml` to `application.yaml` `include`.
3. Remove `qbittorrent` / `sonarr` / `sonarr-tv` / `prowlarr` Backend+HTTPRoute from `apps/transitional/resources.yaml`.
4. Keep those Compose services stopped on arr.

## Layout

| File | Role |
|------|------|
| `storage.yaml` | Static NFS PVs for `media/{anime,tv,downloads}` |
| `qbittorrent.yaml` | qBit + WG sidecar, iSCSI config |
| `sonarr-*.yaml` / `prowlarr.yaml` | *arr Deployments |
| `httproutes.yaml` | Lab URLs — enabled at cutover only |
| `scripts/copy-configs-from-arr.sh` | VM → PVC migration |
