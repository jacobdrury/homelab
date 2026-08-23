# Inventory (current state)

What exists **today**. Fill gaps as you inventory Proxmox guests and hardware. Target design: [architecture](architecture/overview.md) · [decisions](decisions.md).

## Hardware

| Host | Role today | Notes |
|------|------------|-------|
| Intel Mac Mini | Proxmox host | Primary active host |
| Gaming PC #1 | Proxmox host | Active; **24TB HDD** (Jellyfin libs); **leaving the lab** |
| Gaming PC #2 | Idle | Target **Unraid** + optional lab GPU |
| Laptop #1 | Idle | |
| Laptop #2 | Idle | |

One laptop has an **NVIDIA Quadro** (note which below) — optional NVENC worker if docked 24/7.

**Storage:** no NAS yet. Media on the 24TB in Gaming PC #1 → must move to Unraid on PC #2 before PC #1 is wiped.

**Compute:** Proxmox VMs/LXCs (guest map TBD).

### Specs (fill in)

| Host | CPU / RAM | Boot disk | Data disks | GPU | Notes |
|------|-----------|-----------|------------|-----|-------|
| Mac Mini | | | | Intel iGPU | Interim Talos VMs |
| Gaming PC #1 | | | **24TB** (media) | gaming GPU | → personal gaming |
| Gaming PC #2 | | NVMe/SATA SSDs | receives **24TB** | gaming GPU | Unraid |
| Laptop #1 | | | | Quadro? / iGPU? | Mark Quadro here |
| Laptop #2 | | | | | |

## Services

| Service | Purpose | Host / VM / LXC | Data / deps |
|---------|---------|-----------------|-------------|
| Pi-hole | DNS / ad blocking | TBD | LAN DNS |
| Home Assistant | Home automation | TBD | USB radio? |
| Jellyfin | Media | TBD | 24TB libraries |
| Sonarr (anime) | Acquisition | TBD | |
| Sonarr (TV) | Acquisition | TBD | |
| qBittorrent | Downloads | TBD | |
| Prowlarr | Indexers | TBD | Both Sonarrs |

**Still need:** exact guest placement, ports / how you reach things today, HA USB radio yes/no.

## Networking & access (today)

| Concern | Today |
|---------|--------|
| Remote access | Tailscale account (free); not fully wired |
| LAN DNS | Pi-hole (keeping) |
| LAN | UniFi; homelab VLAN **planned** |
| Ingress / TLS | Not the target stack yet |
| Backups | None formal — decide after Unraid |

## Why change

- No dedicated NAS; storage stuck on Gaming PC #1  
- PC #1 must return to gaming  
- Want Talos k8s + GitOps instead of snowflake Proxmox guests  
- Tailscale + agent-operable lab; UniFi VLAN isolation  
