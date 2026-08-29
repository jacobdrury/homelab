# Storage (Unraid)

Unraid on **scarif** (pc white, bare metal) is the storage plane. The cluster talks to it with **two protocols**:

| Protocol | Best for | Access mode |
|----------|----------|-------------|
| **NFS** | Media, downloads, shared app config | File / often **RWX** |
| **iSCSI** | Databases and chatty RWO disks | Block / typically **RWO** |

Still **not** using Longhorn/Ceph as the primary store — Unraid owns the disks.

Why Unraid over TrueNAS: **mixed drive sizes** over time. Parity must be **≥ largest data disk**.

**Unraid note:** NFS/SMB are first-class. **iSCSI target** is a community plugin (targetcli-based) — workable and in-plan, but expect more manual LUN/target setup than TrueNAS. Prefer SSD/pool-backed LUNs for DB-ish volumes; keep bulk media on NFS.

## Disks

| Disk | Role | Notes |
|------|------|--------|
| 24TB HDD | Media library | **Do not format into the array first** — see [Migrating the 24TB](#migrating-the-24tb-no-spare-disk) |
| NVMe / SATA SSD(s) | Pool / cache | `appdata` + **iSCSI LUNs**; may also hold a small array member if Unraid requires one |
| USB flash | Boot + **license** (buy) | Required |
| ≥24TB (future) | Parity and/or array data | Buy when affordable — enables real array + parity |
| 2TB HDD | — | **Out of plan** for now |

## Migrating the 24TB (no spare disk)

Assigning a disk to the Unraid **array** normally **clears/formats** it. With no second large drive, **do not** assign the 24TB as an array data disk until the library lives somewhere else (or you accept wipe).

**Plan: keep the existing filesystem; mount with Unassigned Devices.**

1. Move the 24TB from PC #1 into PC #2 (or attach it) **without** adding it to the array.  
2. Install Unraid; use SSD pool for `appdata` / system.  
3. Install **Unassigned Devices** (+ UD Plus if useful); mount the 24TB **read/write** with its current filesystem.  
4. Share that mount over **NFS/SMB** (same paths Jellyfin expects, or update Jellyfin once).  
5. Validate playback for a while.  
6. **Later** (when you have space or another large disk): copy library onto an array/share, then optionally wipe/add the old disk as array/parity.

Until then the library is as “safe” as today (single disk, no Unraid parity) — but you get Unraid + NFS/iSCSI for the rest of the lab **without buying a second 24TB**.

If Unraid insists on at least one array disk, use a **small spare SSD/HDD** as a throwaway/nearly-empty array member — **not** the 24TB.

## Standup

1. Install Unraid on PC #2 on the [homelab VLAN](networking.md#unifi-homelab-vlan).  
2. SSD pool for `appdata` (and small array disk only if required).  
3. Mount **24TB via Unassigned Devices** — do **not** format into the array.  
4. NFS/SMB export the UD mount for Jellyfin / later CSI.  
5. Enable **iSCSI target** plugin; LUNs on SSD/pool.  
6. When affordable: second large disk or free space → copy into array → optional parity ≥ largest data disk.  

## NFS → cluster

| Share / export | Use |
|----------------|-----|
| UD `media/` (or similar) | Jellyfin libraries (initially) |
| `downloads/` | qBittorrent (pool or UD as you prefer) |
| `appdata/` | *arr and most app config (SSD pool) |
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
