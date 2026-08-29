# Storage (Unraid)

Unraid on **scarif** (pc white, bare metal) is the storage plane. The cluster talks to it with **two protocols**:

| Protocol | Best for | Access mode |
|----------|----------|-------------|
| **NFS** | Media, downloads, shared app config | File / often **RWX** |
| **iSCSI** | Databases and chatty RWO disks | Block / typically **RWO** |

Still **not** using Longhorn/Ceph as the primary store — Unraid owns the disks.

Why Unraid over TrueNAS: **mixed drive sizes** over time. Parity must be **≥ largest data disk**.

**Unraid note:** NFS/SMB are first-class. **Unassigned Devices** mounts non-array disks and can **Share** them over NFS (enable **Settings → NFS**, **UD → Enable NFS export**, **Share** on disk). **iSCSI target** is a community plugin — workable and in-plan. Prefer SSD/pool-backed LUNs for DB-ish volumes; keep bulk media on NFS.

## Current state (Aug 2025)

| Item | Value |
|------|-------|
| Host | **scarif** · `192.168.1.10` · 10G to Aggregation |
| 24TB | UD mount `/mnt/disks/ZXA0VZBA` · XFS · **8.7 TB** used |
| NFS export | `/mnt/disks/ZXA0VZBA` · NFSv4 |
| Array | Started · **no data/parity disks** |
| Consumer | pc (black) VM 101 `arr` → `/mnt/data` (fstab) |
| 500 GB NVMe | UD · NTFS leftover · can become **cache pool** anytime |

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

## NFS → cluster

| Export (today) | Use |
|----------------|-----|
| `/mnt/disks/ZXA0VZBA` | Jellyfin / *arr libraries via `media/` |
| `appdata/` (future) | *arr config on SSD pool |
| `downloads/` | qBittorrent (pool or UD as you prefer) |
| `backups/` | App dumps / future backup tooling |

Cluster: **NFS CSI** (ReadWriteMany where needed). Point CSI at whatever export serves media (UD path is fine initially).

## iSCSI → cluster

| Use | Notes |
|-----|--------|
| Postgres / other DBs | Prefer over NFS if latency becomes an issue |
| Single-writer app disks | Classic RWO block PVC |

Cluster: **iSCSI CSI** (Talos workers need initiator support). One node per LUN unless you add a clustered filesystem (out of scope).

**Don’t** put the Jellyfin library on iSCSI — keep large shared libraries on NFS (UD or array).

## Backups

Parity ≠ backup. UD also has no parity. Choose tooling **after** Unraid is stable ([roadmap Phase 1c](../roadmap.md#phase-1c--backups)).
