# Storage (Unraid)

Unraid on **Gaming PC #2** (bare metal) is the storage plane. The cluster talks to it with **two protocols**:

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
| 24TB HDD | Array **data** (only data disk at first) | Jellyfin `media/` via NFS |
| NVMe / SATA SSD(s) | Cache / pool | `appdata` + **iSCSI LUNs** when possible |
| USB flash | Boot + **license** (buy) | Required |
| ≥24TB (future) | **Parity** | Easy to add later |
| 2TB HDD | — | **Out of plan** for now |

## Standup

1. Install Unraid on PC #2 on the [homelab VLAN](networking.md#unifi-homelab-vlan).  
2. 24TB as sole data disk; no parity yet.  
3. SSD pool; NFS shares: `media`, `downloads`, `appdata` (SSD), `backups`.  
4. Copy libraries from PC #1 → `media`; point Jellyfin at Unraid.  
5. Enable **iSCSI target** plugin; create LUNs on SSD/pool for block consumers.  
6. Later: assign parity ≥24TB; sync in background.  

**Initially:** ~24TB usable, **no** parity protection (same ballpark as today).

## NFS → cluster

| Share | Use |
|-------|-----|
| `media/` | Jellyfin libraries |
| `downloads/` | qBittorrent |
| `appdata/` / `apps/` | *arr and most app config |
| `backups/` | App dumps / future backup tooling |

Cluster: **NFS CSI** (ReadWriteMany where needed).

## iSCSI → cluster

| Use | Notes |
|-----|--------|
| Postgres / other DBs | Prefer over NFS if latency becomes an issue |
| Single-writer app disks | Classic RWO block PVC |

Cluster: **iSCSI CSI** (or in-tree/iscsi tooling compatible with Talos — enable initiator support on workers). One node attaches a given LUN at a time unless you add a clustered filesystem (out of scope).

**Don’t** put the Jellyfin library on iSCSI — keep large shared libraries on NFS.

## Backups

Parity ≠ backup. Choose tooling **after** Unraid is stable ([roadmap Phase 1c](../roadmap.md#phase-1c--backups)).
