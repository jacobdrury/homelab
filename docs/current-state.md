# Current state

Snapshot of what exists today. Update this as things change.

## Hardware

| Host | Role today | Notes |
|------|------------|-------|
| Intel Mac Mini | Proxmox host | Primary active host |
| Gaming PC #1 | Proxmox host | Active; holds **24TB HDD** with Jellyfin libraries — **scheduled to leave the lab** |
| Gaming PC #2 | Available | Not in use; **target Unraid / lab GPU host** |
| Laptop #1 | Available | Not currently in use |
| Laptop #2 | Available | Not currently in use |

One laptop has an **NVIDIA Quadro** (note which in the inventory table when known) — optional NVENC worker if docked 24/7.

**Storage today:** no dedicated NAS. Media lives on the **24TB HDD** in Gaming PC #1 (must move to Unraid on PC #2 before PC #1 retires).

**Compute pattern today:** Proxmox VMs/LXCs (exact guests TBD — fill in as we inventory them).

### Host inventory gaps (fill in when known)

| Host | CPU / RAM | Boot disk | Data disks | GPU | Notes |
|------|-----------|-----------|------------|-----|-------|
| Mac Mini | | | | | |
| Gaming PC #1 | | | **24TB HDD** (media) | gaming GPU | Exit lab → personal gaming |
| Gaming PC #2 | | | (receives **24TB** from PC #1); has NVMe/SATA SSDs | gaming GPU | Keep in lab; Unraid + optional GPU |
| Laptop #1 | | | | Quadro? / iGPU? | Mark which laptop has Quadro |
| Laptop #2 | | | | | |

## Services

| Service | Purpose | Where it runs (approx) | Data / deps |
|---------|---------|------------------------|-------------|
| Pi-hole | DNS / ad blocking | TBD | DNS for LAN |
| Home Assistant | Home automation | TBD | Likely USB/Zigbee/Z-Wave stick |
| Jellyfin | Media streaming | TBD | Libraries on 24TB HDD |
| Sonarr (anime) | Anime acquisition | TBD | |
| Sonarr (TV) | TV acquisition | TBD | |
| qBittorrent | Downloads | TBD | Download path on disk |
| Prowlarr | Indexer manager | TBD | Talks to both Sonarrs |

### Service inventory gaps

- Exact host / VM / LXC for each service
- Ports, reverse proxy (if any), and how you reach them remotely today
- Whether Home Assistant has a dedicated USB radio (matters for migration)

## Networking & access (today)

| Concern | Current approach |
|---------|------------------|
| Remote access | Tailscale account exists (free); not fully wired into lab yet |
| LAN DNS | Pi-hole (keep) |
| Ingress / TLS | Target: Envoy + LE via DNS API (see architecture — not Squarespace DNS) |
| Backups | TBD |

## Pain points / constraints

Capture why you want to change — edit freely:

- No dedicated NAS; storage tied to Gaming PC #1
- **Gaming PC #1 must leave the homelab** and go back to being a gaming PC
- Mix of Proxmox hosts; want a managed k8s control plane long-term
- Want GitOps (declare desired state in Git) instead of snowflake VMs
- Want consistent remote access via Tailscale
