# Inventory (current state)

What exists **today**. Target design: [architecture](architecture/overview.md) · [decisions](decisions.md) · [naming](architecture/naming.md) (Star Wars planet hostnames).

## Hosts

| Host | Codename (target) | Node / name (today) | Role today | IP | Notes |
|------|-------------------|---------------------|------------|-----|-------|
| **Mac Mini** | **yavin** | `homelab03` | Proxmox (idle) → **Talos CP** | `192.168.1.15` | Guests **moved to homelab02**; ready for Phase 2 wipe |
| **pc (black)** | — | `homelab02` | Proxmox | `192.168.1.12` | arr + HA + Pi-hole + discord bots; **leaving lab** → gaming |
| **pc (white)** | **scarif** | `scarif` | **Unraid** | `192.168.5.10` | NAS · Homelab VLAN 5 · 24TB UD + NFS · 10G **eth1** |
| **Laptop (Precision)** | — | `KatherinesLaptop` | Idle (Win11) | `192.168.1.175` | Optional / burst only |
| **Laptop (Inspiron)** | — | — | Idle / reinstalling | — | **Out of lab plan** |
| **Mini PC #1** | **hoth** | — | — | `192.168.5.12` | Talos CP #2 — join existing cluster (Phase 4) |
| **Mini PC #2** | **endor** | — | — | `192.168.5.13` | Talos CP #3 — join existing cluster (Phase 4) |

**Proxmox cluster (legacy):** `homelab02` · `homelab03` — `homelab` (pc white) retired; scarif is bare-metal Unraid.

**Storage today:** **scarif** owns the **24TB** (~**8.7 TB** used) via **Unassigned Devices**; exported **NFSv4** at `/mnt/disks/ZXA0VZBA`. pc (black) **arr** VM mounts it at `/mnt/data`. Array empty (no data/parity disks yet).

### Specs

| Host | CPU / RAM | Boot / system disks | Other disks | GPU |
|------|-----------|---------------------|-------------|-----|
| **Mac Mini** | i3-8100B (4c) / 16 GB | Apple 128 GB NVMe | — | UHD 630 |
| **pc (black)** | i7-8700K (6c/12t) / 32 GB | 970 EVO 250 GB NVMe (LVM) | 970 EVO 500 GB (passthrough → VM 101 `virtio3`; unused in guest) | GTX 1080 Ti |
| **pc (white)** | i7-4770K (4c/8t) / 32 GB | USB flash (Unraid boot) | **24TB** UD; 970 EVO 500 GB NVMe (NTFS UD); 240 GB + 500 GB SATA SSDs (unused) | — (GTX 780 removed) |
| **Laptop (Precision)** | i7-7820HQ (4c/8t) / 16 GB | SM961 512 GB NVMe | — | Quadro M1200 + HD 630 |
| **Laptop (Inspiron)** | Pentium N5000 (4c) / 4 GB | Toshiba 500 GB HDD | — | UHD 605 |

---

## Mac Mini — **yavin** (today: `homelab03`)

| Item | Value |
|------|-------|
| Model | Apple Mac mini 2018 (`Macmini8,1`) · serial `C07Y30G3JYVY` |
| Today | Proxmox 8.4.0 · kernel 6.8.12-9-pve |
| Target | **Bare-metal Talos** CP #1 — single-node `prd` → expand to 3 CPs |
| Boot | Apple `AP0128M` 128 GB NVMe |
| GPU | UHD 630 · Talos extension **`i915`** (+ **`intel-ucode`**) |
| LAN (target) | **Primary:** USB 2.5G `enx6c1ff721c616` (UGREEN UG-USBC-25052 · RTL8156BG) → Pro Max 16 **Port 15** · **Secondary:** onboard 1G `enp4s0` |
| LAN (today) | USB Ethernet active; onboard `enp4s0` down |

**Guests:** none — Pi-hole LXC and `discord-bots` VM **migrated to homelab02** (pc black). Stale LVM from old VM 105 may remain on disk.

---

## pc (black) (`homelab02`)

| Item | Value |
|------|-------|
| Board | MSI Z370 Gaming Pro Carbon (MS-7B45) |
| Proxmox | 8.4.0 · kernel 6.8.12-9-pve |
| Boot | Samsung 970 EVO 250 GB (`S465NB0K579621D`) · `local` + `local-lvm` |
| Extra NVMe | 970 EVO 500 GB (`S466NX0KA18171W`) · passed to VM 101 as `virtio3`; unused in guest |
| GPU | GTX 1080 Ti (`10de:1b06`) |
| LAN | 10G → Aggregation **SFP+ 1** (`98:b7:85:21:cd:70`); onboard also on Pro Max **Port 6** |
| Tailscale | `tailscale0` on host |

### Guests

| VMID | Type | Name | IP | VLAN | RAM | Notes |
|------|------|------|-----|------|-----|-------|
| 101 | VM | `arr` | `192.168.1.9` | untagged | 22 GB (10 cores) | Full media stack · library via **NFS → scarif** |
| 105 | VM | `home-assistant` | `192.168.2.8` | **2** | 4 GB | HA OS · no USB radios |
| — | LXC | `Pi-Hole` | `192.168.1.11` | untagged | 1 GB / 8 GB | VMID **106** · ex homelab03 · k8s cutover **last** |
| 103 | VM | `discord-bots` | `192.168.1.18` | untagged | 1 GB / 32 GB | **Migrated from homelab03** |

**Must migrate or retire all guests before wipe → personal gaming.**

### VM 101 `arr` — media stack

Compose: `/home/arr/docker/docker-compose.yml` · config `/home/arr/docker/arr-stack/`.

| Container | Image | Network | Ports (on `192.168.1.9`) |
|-----------|-------|---------|--------------------------|
| `jellyfin` | `jellyfin/jellyfin:10.11.11` | default | `8096`, `8920`, `1900/udp`, `7359/udp` |
| `gluetun` | `qmcgaw/gluetun:v3.41.1` | default | `8085`, `8989–8990`, `9696`, `6767`, `6881` |
| `sonarr-tv` | `linuxserver/sonarr:4.0.19` | `service:gluetun` | via Gluetun (`:8989`) |
| `sonarr-anime` | `linuxserver/sonarr:4.0.19` | `service:gluetun` | via Gluetun (`:8990`) |
| `prowlarr` | `linuxserver/prowlarr:2.4.0` | `service:gluetun` | via Gluetun (`:9696`) |
| `qbittorrent` | `linuxserver/qbittorrent:5.2.3` | `service:gluetun` | via Gluetun (`:8085`) |

Gluetun: **Mullvad WireGuard** · port forwarding off. Jellyfin is off-VPN.

| Path | Size | Used by |
|------|------|---------|
| `/mnt/data` | NFSv4 | `scarif.lab.jacobdrury.com:/mnt/disks/ZXA0VZBA` (fstab · `_netdev,nofail` — boot mount, not automount) |
| `/mnt/data/media/anime` | 6.9 TB | Jellyfin, Sonarr |
| `/mnt/data/media/tv` | 608 GB | Jellyfin, Sonarr |
| `/mnt/data/media/downloads` | ~27 GB | qBittorrent |
| `/home/arr/docker/arr-stack/*` | on 32 GB root | app config |

**VM notes:** `scsi1` (24TB passthrough) removed Aug 2025. Old XFS UUID fstab entry commented out; NFS mount in `/etc/fstab`. Needs `nfs-common` in guest.

---

## pc (white) — **scarif**

| Item | Value |
|------|-------|
| Board | MSI Z87-GD65 Gaming (MS-7845) |
| OS | **Unraid** · hostname **`scarif`** |
| Boot | Samsung USB flash 128 GB (`sda`) |
| GPU | — (GTX 780 removed Aug 2025) |
| LAN | **eth1** Intel 82599 **10G DAC** → Aggregation **SFP+ 2** (**Homelab** VLAN 5) · `192.168.5.10` static · DNS `192.168.1.11` · bonding/bridging **off** · **eth0** (1G) unused |
| Array | **Started** · no data or parity disks assigned |
| Plugins | **Unassigned Devices** (mount + NFS share) |

### Disks

| Device | ID | Role today | Notes |
|--------|-----|------------|-------|
| Seagate 24TB | `sdb` / `ZXA0VZBA` | **UD** · media | XFS UUID `0a63c59e-eb76-4c76-b559-ce379e340311` · **8.7 TB** used · Automount + Share |
| Samsung 970 EVO 500 GB | `nvme0n1` | UD · idle | NTFS leftover · candidate **cache pool** |
| Seagate 240 GB + WD 500 GB SATA | — | unused | optional array member or pool expand |
| USB flash | `sda` | Unraid boot | |

### NFS export

| Export | Clients | Path in share |
|--------|---------|---------------|
| `/mnt/disks/ZXA0VZBA` | `*` (LAN) | `media/{anime,tv,downloads}` |

Enable: **Settings → NFS** + **UD → Enable NFS export** + **Share** on disk. Linux clients: `mount -t nfs4 scarif.lab.jacobdrury.com:/mnt/disks/ZXA0VZBA /mnt/data` (or `192.168.5.10`).

### Not yet

- Cache pool / `appdata` share (500 GB NVMe available anytime — no array required)
- Tailscale on Unraid
- iSCSI target
- Phase 1b: buy **~12 TB** data drive → copy library → repurpose 24TB as **parity** ([storage](architecture/storage.md#phase-1b--array--parity))

---

## Laptop (Precision)

| Item | Value |
|------|-------|
| Model | Dell Precision 5520 |
| OS | Windows 11 Pro (build 22631) |
| CPU / RAM | i7-7820HQ / 16 GB |
| Disk | Samsung SM961 512 GB NVMe |
| GPU | Quadro M1200 (4 GB, driver 528.79, CUDA 12.0) + HD 630 |
| LAN | `192.168.1.175` |

## Laptop (Inspiron)

| Item | Value |
|------|-------|
| Model | Dell Inspiron 3582 (15 3000) · serial `G2CWCX2` |
| CPU / RAM | Pentium Silver N5000 / 4 GB |
| Disk | Toshiba MQ01ABF050 500 GB HDD |
| GPU | UHD 605 (no discrete) |
| Wi‑Fi | QCA9377 |
| Status | Fresh OS reinstall in progress (was Zorin) |

---

## Services

| Service | Where | Reach | Data / notes |
|---------|-------|-------|--------------|
| Pi-hole | pc (black) LXC **106** | `192.168.1.11` · `:53`/admin UI | LAN DNS · config in **`infrastructure/pihole/`** (OpenTofu) · `*.lab` → Cloudflare forward |
| Home Assistant | pc (black) VM 105 | `192.168.2.8` (VLAN 2) | No Z-Wave/Zigbee radios |
| **NFS (media)** | **scarif** | `scarif.lab.jacobdrury.com:/mnt/disks/ZXA0VZBA` (`192.168.5.10`) | ~8.7 TB library |
| Jellyfin | pc (black) VM 101 | `192.168.1.9:8096` | `/mnt/data/media/{anime,tv}` via NFS |
| Sonarr (TV / anime) | VM 101 via Gluetun | `:8989` / `:8990` | `/mnt/data/media` via NFS |
| qBittorrent | VM 101 via Gluetun | `:8085` | downloads · Mullvad WG |
| Prowlarr | VM 101 via Gluetun | `:9696` | config on VM root |
| Discord bots | pc (black) VM **103** | `192.168.1.18` | outbound only · ex homelab03 |

---

## Networking

| Concern | Today |
|---------|--------|
| Gateway | UDM Pro · `192.168.1.1` · AT&T |
| LAN DNS | Pi-hole · `192.168.1.11` |
| Networks | `192.168.1.0/24` (Drury) · `192.168.2.0/24` (IoT) · `192.168.5.0/24` (**Homelab** · VLAN 5 · **scarif live**) · `192.168.6.0/24` (Teleport) |
| Public / lab DNS | Cloudflare — **`infrastructure/dns/`** · LAN via Pi-hole forward for `*.lab` |
| Remote | Tailscale (free); host client on pc (black) |
| Ingress / TLS | Not yet (target: Envoy + `lab.jacobdrury.com`) |
| Backups | None formal — decide after Unraid |

### IP map (Drury · VLAN 1)

| IP | Device |
|----|--------|
| `.1` | UDM Pro |
| `.9` | `arr` VM (pc black) |
| `.11` | Pi-hole |
| `.12` | pc (black) / `homelab02` |
| `.13` | USW Aggregation |
| `.15` | **yavin** (Mac Mini) · today `homelab03` |
| `.18` | discord-bots VM |
| `.70` | USP PDU Pro |
| `.82` | U6 Pro (Hallway) |
| `.107` | Bedroom client |
| `.109` | USW Flex 2.5G 8 PoE |
| `.143` | U6 LR (Living Room) |
| `.175` | Laptop (Precision) |
| `.197` | USW Pro Max 16 PoE |
| `.225` | USW Flex Mini |
| `.2.8` | Home Assistant (VLAN 2) |
| `.2.171` | Lutron bridge (IoT) |
| `.2.211` | IoT device |

### IP map (Homelab · VLAN 5)

| IP | Device |
|----|--------|
| `.10` | **scarif** (pc white) · Unraid NAS |
| `.11` | **yavin** (target · Talos Phase 2) |
| `.12` | **hoth** (target · Phase 4) |
| `.13` | **endor** (target · Phase 4) |
| `.20` | API VIP (optional · Phase 4) |

### Topology

```
AT&T → UDM Pro (.1)
         └─ 10G ─ USW Aggregation (.13)
                    ├─ SFP+ 1 ─ pc black (.12) 10G
                    ├─ SFP+ 2 ─ pc white / **scarif** (`.5.10`) 10G NAS · **Homelab VLAN 5**
                    ├─ SFP+ 3 ─ Flex 2.5G (.109) ─ APs, Bedroom, Flex Mini
                    ├─ SFP+ 5 ─ Pro Max 16 (.197)
                    │              ├─ Port 13 ─ Pi-hole (.11)
                    │              ├─ Port 15 ─ Mac Mini (.15)
                    │              └─ Ports 1–3, … ─ PDU, IoT, clients
                    └─ SFP+ 7 ─ UDM Pro
```

### UniFi gear

| Device | IP | Status | Notes |
|--------|-----|--------|-------|
| UDM Pro | `.1` | Online | Gateway |
| USW Aggregation | `.13` | Online | 10G core |
| USW Flex 2.5G 8 PoE | `.109` | Online | APs + Flex Mini |
| USW Pro Max 16 PoE | `.197` | Online | Homelab GbE + IoT |
| USP PDU Pro | `.70` | Online | Pro Max Port 1 |
| U6 LR / U6 Pro | `.143` / `.82` | Online | Living room / hallway |
| USW Flex Mini | `.225` | Online | Flex 2.5G Port 8 |
| USW Flex 1 / Flex 2 / Pro 24 PoE | `.235` / `.118` / `.211` | Offline | Spare / retired |

#### Aggregation SFP+

| Port | Connected |
|------|-----------|
| 1 | pc (black) 10G · `.12` |
| 2 | pc (white) / **scarif** 10G · `.5.10` · **Homelab VLAN 5** |
| 3 | Flex 2.5G · `.109` |
| 4, 6 | Empty |
| 5 | Pro Max 16 · `.197` |
| 7 | UDM Pro · `.1` |
| 8 | Unknown MAC `0c:ee:99:98:c9:90` · no traffic |

#### Pro Max 16 PoE

| Port | Connected |
|------|-----------|
| 1 | PDU Pro · `.70` |
| 2–3 | IoT (`.2.211`, Lutron `.2.171`) |
| 4 | Empty (was pc white 1G mgmt) |
| 5 | `mathboi` (MAC matches discord-bots — TBD) |
| 6 | pc (black) onboard GbE |
| 7, 10, 11 | Unknown · same MAC `04:92:26:c1:6c:51` |
| 8–9 | Empty |
| 12 | Living-Room client |
| 13 | Pi-hole · `.11` (2.5G) |
| 14, 16 | Pulsar-MBP |
| 15 | Mac Mini · `.15` |
| SFP+ 1 | Unknown MAC `70:a7:41:7c:9c:69` |
| SFP+ 2 | Aggregation uplink |

#### Flex 2.5G 8 PoE

| Port | Connected |
|------|-----------|
| 1–2 | U6 LR · U6 Pro |
| 3–6, 9 | Empty |
| 7 | Bedroom · `.107` |
| 8 | Flex Mini · `.225` |
| 10 | Aggregation uplink |

---

## Why change

- ~~No dedicated NAS~~ → **scarif** live; media on NFS; Phase 1 storage **done**
- Prefer Talos + GitOps — bare-metal **yavin** → **expand to 3 CPs**; migrate apps **once**
- **pc (black)** retained until k8s cutover, then personal gaming
- ~~Homelab VLAN + OpenTofu before Talos~~ → Phase **1.5 done**; scarif on `.5.10`
