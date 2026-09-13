# Storage (Unraid)

Unraid on **scarif** (pc white, bare metal) is the storage plane. The cluster talks to it with **two protocols**:

| Protocol | Best for | Access mode |
|----------|----------|-------------|
| **NFS** | Media, downloads, shared app config | File / often **RWX** |
| **iSCSI** | Databases and chatty RWO disks | Block / typically **RWO** |

Still **not** using Longhorn/Ceph as the primary store — Unraid owns the disks.

Why Unraid over TrueNAS: **mixed drive sizes** over time. Parity must be **≥ largest data disk**.

**Unraid note:** NFS/SMB are first-class. **Unassigned Devices** mounts non-array disks and can **Share** them over NFS (enable **Settings → NFS**, **UD → Enable NFS export**, **Share** on disk). **iSCSI target** is a community plugin — workable and in-plan. Prefer SSD/pool-backed LUNs for DB-ish volumes; keep bulk media on NFS.

## Current state (Aug 2026)

| Item | Value |
|------|-------|
| Host | **scarif** · `192.168.5.10` · Homelab VLAN 5 · 10G **eth1** to Aggregation SFP+ 2 |
| 24TB | UD mount `/mnt/disks/ZXA0VZBA` · XFS · **8.7 TB** used |
| NFS export | `/mnt/disks/ZXA0VZBA` · NFSv4 |
| Array | Started · **no data/parity disks** |
| Consumer | pc (black) VM 101 `arr` → `/mnt/data` via `scarif.lab.jacobdrury.com` (fstab · `_netdev,nofail`) |
| 500 GB NVMe | UD · XFS `/mnt/disks/naboo-ssd` · naboo VM + libvirt (Sep 2026) |

## Disks

| Disk | Role | Notes |
|------|------|--------|
| 24TB HDD | Media library (UD today) | **On scarif via UD** — see [Phase 1b](#phase-1b--array--parity) for array/parity |
| NVMe / SATA SSD(s) | Pool / cache | `appdata` + **iSCSI LUNs**; may also hold a small array member if Unraid requires one |
| USB flash | Boot + **license** (buy) | Required |
| ≥24TB (future) | Parity and/or array data | Buy when affordable — enables real array + parity |
| 2TB HDD | — | **Out of plan** for now |

## Migrating the 24TB (no spare disk)

**Status: steps 1–5 done** (Aug 2025). Library on scarif UD; arr VM on NFS.

Assigning a disk to the Unraid **array** normally **clears/formats** it. With no second large drive, **do not** assign the 24TB as an array data disk until the library lives somewhere else (or you accept wipe).

**Plan used: keep the existing filesystem; mount with Unassigned Devices.**

1. ~~Move the 24TB from pc (black) into pc (white)~~  
2. ~~Install Unraid; hostname `scarif`~~  
3. ~~**Unassigned Devices** — mount 24TB read/write (XFS preserved)~~  
4. ~~**Share** + NFS export~~  
5. ~~Validate from arr VM~~  
6. **Later:** copy library onto array data disk(s), then assign 24TB as **parity** (wipes disk).

Until Phase 1b completes, the library has **no Unraid parity** — same risk profile as before, but NFS serves the rest of the lab.

If Unraid insists on at least one array disk, use a **small spare SSD/HDD** as a throwaway/nearly-empty array member — **not** the 24TB.

## Phase 1b — Array / parity

Target: buy **data** capacity first; repurpose the 24TB as **parity** after the library is copied off UD.

| Question | Answer |
|----------|--------|
| How much **used** today? | **~8.7 TB** (not compressed) |
| Data drive to buy? | **~12 TB** one disk is comfortable (minimum ~9 TB raw) |
| Does Unraid compress on copy? | **No** — byte-for-byte; media stays ~same size |
| 24TB role after? | **Parity** (must be ≥ largest data disk) |
| Need a second 24TB for parity? | **No** — the existing drive becomes parity |

Steps: add data disk(s) to array → copy UD → validate → remove UD assignment → add 24TB as parity → parity sync.

## Standup

1. ~~Install Unraid on pc (white); static IP `.10`~~  
2. SSD pool for `appdata` (500 GB NVMe — **can do now**, no array disks required).  
3. ~~Mount **24TB via Unassigned Devices**~~  
4. ~~NFS export for arr / later CSI~~  
5. Enable **iSCSI target** plugin when cluster needs block PVCs.  
6. Phase 1b when affordable: data disk → copy → 24TB parity.  

## NFS permissions (UID / squash)

Unraid NFSv4 for this export **squashes client UIDs** to Unraid **`nobody:users` (`99:100`)**. The client may still *show* files as `1000:1000` (inode owners), but writes run as `99`. If dirs are `drwxrwxr-x` owned by `1000:1000`, squashed clients (and even `root` on the client, after root_squash) get **Permission denied**.

Symptoms seen on VM 101 `arr` (Sep 2026):

- qBittorrent: `file_open ... error: Permission denied` under `/home/data/downloads`
- Sonarr: `UnauthorizedAccessException` / `Permission denied` when moving into `media/anime/...` or `media/tv/...`
- Host check: `touch /mnt/data/media/downloads/.write-test` fails for both `arr` and `sudo`

**On-disk model (scarif):** keep the media tree owned by the squash identity:

```bash
# on scarif
chown -R nobody:users /mnt/disks/ZXA0VZBA/media
chmod -R ug+rwX,o+rX /mnt/disks/ZXA0VZBA/media
```

**App identity:** every writer (Docker **or** k8s) must run as **`uid=99` `gid=100`**, not host user `1000`. Short-term `chmod a+rwX` works but new files recreated as `1000:1000` break again. Step-by-step for today’s Compose stack: [media](media.md#nfs-uid-fix-vm-101-arr).

This is **not Docker-specific** — it is Unraid NFS + matching process UID/GID.

## NFS → cluster

| Export (today) | Use |
|----------------|-----|
| `/mnt/disks/ZXA0VZBA` | Jellyfin / *arr libraries via `media/` |
| `downloads/` | qBittorrent (pool or UD as you prefer) |
| `backups/` | App dumps / future backup tooling |

Cluster: **NFS CSI** live — StorageClass **`scarif-nfs`** (`clusters/prd/platform/nfs-csi/`). Dynamic PVCs land under `${namespace}/${pvc}` on the export. Shared media tree (existing `media/`) can use a static PV later if apps need the root layout. **Not** for Sonarr/Postgres SQLite — use iSCSI.

**k8s must use the same UID model** as above — CSI mounts the export; it does not remap Unraid squash. For media Pods / charts:

| Setting | Value |
|---------|--------|
| `runAsUser` / linuxserver `PUID` | `99` |
| `runAsGroup` / `fsGroup` / `PGID` | `100` |
| scarif tree | `nobody:users` + group-writable (`ug+rwX`) |

Validated (Sep 2026): throwaway Pod mounted `scarif-nfs` and `touch`ed as `99:100`. Re-run via `clusters/prd/platform/nfs-csi/smoke-test.yaml` before *arr cutover if unsure.

## iSCSI → cluster

| Use | Notes |
|-----|--------|
| *arr / Prowlarr **config** (SQLite) | RWO on SSD pool — **not** NFS |
| Postgres / other DBs | One RWO PVC **per** replica (StatefulSet / CNPG) |
| Pi-hole (multi-replica) | One RWO PVC **per** pod — not one shared volume |
| Single-writer app disks | Classic RWO block PVC |

Cluster: **iSCSI CSI** live — StorageClass **`scarif-iscsi`** (`clusters/prd/platform/iscsi-csi/`); Talos **`iscsi-tools`**; backend ZFS pool **`scarif-ssd`** on scarif. One node attaches a given LUN at a time; pods **can reschedule** (detach/attach). Do not share one LUN across replicas.

**Don’t** put the Jellyfin library on iSCSI — keep large shared libraries on NFS (UD or array).

Validated (Sep 2026): smoke Pod RWO write/delete. NFS + iSCSI CSI both in housekeeping — [roadmap](../roadmap.md#phase-2-housekeeping--storage-csi).

## Backups

Parity ≠ backup. UD also has no parity. Choose tooling **after** Unraid is stable ([roadmap Phase 1c](../roadmap.md#phase-1c--backups)).
