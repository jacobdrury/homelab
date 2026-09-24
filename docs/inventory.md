# Inventory (current state)

What exists **today**. Target design: [architecture](architecture/overview.md) · [decisions](decisions.md) · [naming](architecture/naming.md) (Star Wars planet hostnames).

## Hosts

| Host | Codename (target) | Node / name (today) | Role today | IP | Notes |
|------|-------------------|---------------------|------------|-----|-------|
| **Mac Mini** | **yavin** | `yavin` | Talos **control-plane** | `192.168.5.11` | Bare-metal Talos 1.12.7 · Cilium · `allowSchedulingOnControlPlanes` |
| **pc (black)** | — | `homelab02` | Proxmox (**sole node**) | `192.168.1.12` | Guests: **arr / HA / discord-bots stopped**; Pi-hole LXC soaking; **leaving lab** → gaming |
| **pc (white)** | **scarif** | `scarif` | **Unraid** | `192.168.5.10` | NAS · Homelab VLAN 5 · 24TB UD + NFS · hosts **naboo** VM |
| **Laptop (Precision)** | — | `KatherinesLaptop` | Idle (Win11) | `192.168.1.175` | Optional / burst only |
| **Laptop (Inspiron)** | — | — | Idle / reinstalling | — | **Out of lab plan** |
| **Mini PC #1** | **hoth** | — | — | `192.168.5.12` | Talos CP #2 — join existing cluster (Phase 4) |
| **Mini PC #2** | **endor** | — | — | `192.168.5.13` | Talos CP #3 — join existing cluster (Phase 4) |
| **naboo** (VM) | **naboo** | `naboo` | Talos **worker** | `192.168.5.14` | Unraid KVM on scarif · 6 vCPU / 20 GB · Ready on `prd` (Sep 2026) |

**Proxmox (legacy):** **homelab02 only** — single-node cluster (`pvecm expected 1`, corosync config v6, Aug 2026). **homelab03** delnode'd (Mac Mini → Talos); **homelab** (pc white) retired → bare-metal **scarif** (Unraid).

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
| Today | **Bare-metal Talos 1.12.7** · CP #1 on `prd` · `192.168.5.11` / `.111` |
| Target | Expand to 3 CPs with **hoth** / **endor** (Phase 4) |
| Boot | Apple `AP0128M` 128 GB NVMe |
| GPU | UHD 630 · Talos extension **`i915`** (+ **`intel-ucode`**) |
| LAN | **Primary:** USB 2.5G → Pro Max **Port 13** (`192.168.5.11`) · **Secondary:** onboard 1G → Pro Max **Port 5** (`192.168.5.111`) — both Homelab VLAN 5 |

**Guests:** none (Proxmox retired Aug 2026).

---

## pc (black) (`homelab02`)

| Item | Value |
|------|-------|
| Board | MSI Z370 Gaming Pro Carbon (MS-7B45) |
| Proxmox | 8.4.0 · kernel 6.8.12-9-pve · **sole cluster node** (expected votes 1 · Aug 2026) |
| Boot | Samsung 970 EVO 250 GB (`S465NB0K579621D`) · `local` + `local-lvm` |
| Extra NVMe | 970 EVO 500 GB (`S466NX0KA18171W`) · passed to VM 101 as `virtio3`; unused in guest |
| GPU | GTX 1080 Ti (`10de:1b06`) |
| LAN | 10G → Aggregation **SFP+ 1** (`98:b7:85:21:cd:70`); onboard also on Pro Max **Port 6** |
| Tailscale | `tailscale0` on host · tailnet **`homelab02`** · exit node **off** (Aug 2026) · **interim** subnet router candidate until k8s operator |

### Guests

| VMID | Type | Name | IP | VLAN | RAM | Notes |
|------|------|------|-----|------|-----|-------|
| 101 | VM | `arr` | `192.168.1.9` | untagged | 22 GB (10 cores) | **Stopped** · `onboot=0` · media configs archived; stack on k8s |
| 105 | VM | `home-assistant` | `192.168.2.8` | **2** | 4 GB | **Stopped** · `onboot=0` · HA on k8s ([home-assistant](architecture/home-assistant.md)) |
| — | LXC | `Pi-Hole` | `192.168.1.11` | untagged | 1 GB / 8 GB | VMID **106** · **cut over to k8s** — stop after DNS soak |
| 103 | VM | `discord-bots` | `192.168.1.18` | untagged | 1 GB / 32 GB | **Stopped** · won't migrate |

**Must migrate or retire all guests before wipe → personal gaming.**

### VM 101 `arr` — stopped (media stack on k8s)

Compose archive: `/home/arr/docker/docker-compose.yml` · config `/home/arr/docker/arr-stack/`.
VM is **powered off** with **onboot disabled**; keep the disk until configs on iSCSI are trusted.

**On k8s** (`clusters/prd/apps/media/`): Sonarr anime/TV, Prowlarr, qBittorrent (+ Mullvad WG sidecar), Jellyfin (`10.11.11`).

| Path (on disk when VM is on) | Used by |
|------|---------|
| `/mnt/data/media/{anime,tv,downloads}` | NFS → scarif (k8s mounts directly now) |
| `/home/arr/docker/arr-stack/*` | archived configs (copied to iSCSI PVCs) |

---

## pc (white) — **scarif**

| Item | Value |
|------|-------|
| Board | MSI Z87-GD65 Gaming (MS-7845) |
| OS | **Unraid** · hostname **`scarif`** |
| Boot | Samsung USB flash 128 GB (`sda`) |
| GPU | — (GTX 780 removed Aug 2025) |
| LAN | **bond0** (`eth0`+`eth1`) + **br0** · Homelab VLAN 5 · `192.168.5.10` static · DNS `192.168.1.11` · UI: `http://scarif.lab.jacobdrury.com` (HTTP only) |
| Array | **Started** · no data or parity disks assigned |
| Plugins | **Unassigned Devices** (mount + NFS share) |
| VMs | **naboo** — Talos worker · libvirt + domains on `/mnt/disks/naboo-ssd/` (array `/mnt/user` empty) |

### Disks

| Device | ID | Role today | Notes |
|--------|-----|------------|-------|
| Seagate 24TB | `sdb` / `ZXA0VZBA` | **UD** · media | XFS · **8.7 TB** used · Automount + NFS Share |
| Samsung 970 EVO 500 GB | `nvme0n1` | **UD** · naboo | XFS at `/mnt/disks/naboo-ssd` — libvirt, domains, Talos ISO |
| Seagate 240 GB + WD 500 GB SATA | — | unused | optional array member or pool expand |
| USB flash | `sda` | Unraid boot | |

### NFS export

| Export | Clients | Path in share |
|--------|---------|---------------|
| `/mnt/disks/ZXA0VZBA` | `*` (LAN) | `media/{anime,tv,downloads}` |

Enable: **Settings → NFS** + **UD → Enable NFS export** + **Share** on disk. Linux clients: `mount -t nfs4 scarif.lab.jacobdrury.com:/mnt/disks/ZXA0VZBA /mnt/data` (or `192.168.5.10`).

### Not yet

- Tailscale on Unraid
- Phase 1b: buy **~12 TB** data drive → copy library → repurpose 24TB as **parity** ([storage](architecture/storage.md#phase-1b--array--parity))

**Done (Sep 2026):** iSCSI Target plugin · ZFS **`scarif-ssd`** · CSI classes **`scarif-nfs`** / **`scarif-iscsi`** (naboo still on NVMe vdisk `/mnt/disks/naboo-ssd`).

### naboo (Talos worker VM)

| Item | Value |
|------|--------|
| Host | scarif Unraid KVM |
| Node | `naboo` · Ready worker on `prd` (Sep 2026) |
| IP | `192.168.5.14` |
| Specs | 6 vCPU (unpinned) · 20 GB RAM · 32 GB VirtIO disk |
| Disk path | `/mnt/disks/naboo-ssd/domains/naboo/vdisk1.img` |
| Autostart | On |
| Role | Interim compute until **hoth** / **endor** (Phase 4) — never a control plane |

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
| Pi-hole | k8s `pihole` (GitOps) | VIP `192.168.5.22` · `:53`; UI `pihole.lab` → Authentik | ConfigMaps SoT · LXC **106** @ `.11` stop after soak |
| Home Assistant | k8s `home-assistant` (GitOps; **2026.8.3**) | `homeassistant.lab` → Envoy → pod + Authentik OIDC (`authentik Admins` → owner) | Migrated from VM 105; HTTP settings in UI; no USB radios |
| **NFS (media)** | **scarif** | `scarif.lab.jacobdrury.com:/mnt/disks/ZXA0VZBA` (`192.168.5.10`) | ~8.7 TB library |
| Jellyfin | k8s `media` | `jellyfin.lab` → Envoy → pod `:8096` | NFS `media/{anime,tv}` RO; SQLite on iSCSI config |
| Sonarr (anime / TV) | k8s `media` | `sonarr` / `sonarr-tv`.lab → Authentik → pods | NFS libraries; Postgres `media-pg` |
| qBittorrent | k8s `media` | `qbittorrent.lab` → Authentik → pod | downloads on NFS · Mullvad WG sidecar |
| Prowlarr | k8s `media` | `prowlarr.lab` → Authentik → pod | Postgres `media-pg` |
| Discord bots | pc (black) VM **103** | `192.168.1.18` | **Won't migrate** — stop/delete; outbound-only legacy |

---

## Networking

| Concern | Today |
|---------|--------|
| Gateway | UDM Pro · `192.168.1.1` · AT&T |
| LAN DNS | Pi-hole k8s VIP · `192.168.5.22` |
| Networks | `192.168.1.0/24` (Drury) · `192.168.2.0/24` (IoT) · `192.168.5.0/24` (**Homelab** · VLAN 5 · **scarif live**) · `192.168.6.0/24` (Teleport) |
| Public / lab DNS | Cloudflare — **`infrastructure/cloudflare/`** · LAN via Pi-hole forward for `*.lab` |
| Remote | Tailscale IaC (`infrastructure/tailscale/`): split DNS → Cloudflare; **homelab02** interim subnet router — `http://scarif.lab` verified away (Aug 2026) |
| Ingress / TLS | **HTTP** on scarif via tailnet/LAN; target: Envoy + cert-manager → `https://*.lab` (Phase 2) |
| Backups | None formal — decide after Unraid |

### IP map (Drury · VLAN 1)

| IP | Device |
|----|--------|
| `.1` | UDM Pro |
| `.9` | `arr` VM (**stopped**, onboot off) |
| `.11` | Pi-hole LXC **106** (stop after soak; LAN DNS is `.5.22`) |
| `.12` | pc (black) / `homelab02` |
| `.13` | USW Aggregation |
| `.15` | **yavin** (Mac Mini) · today `homelab03` |
| `.18` | discord-bots VM **103** (**stopped**; won't migrate) |
| `.70` | USP PDU Pro |
| `.82` | U6 Pro (Hallway) |
| `.107` | Bedroom client |
| `.109` | USW Flex 2.5G 8 PoE |
| `.143` | U6 LR (Living Room) |
| `.175` | Laptop (Precision) |
| `.197` | USW Pro Max 16 PoE |
| `.225` | USW Flex Mini |
| `.2.8` | HA OS VM 105 (VLAN 2) — **stopped** / `onboot=0` |
| `.2.171` | Lutron bridge (IoT) |
| `.2.211` | IoT device |

### IP map (Homelab · VLAN 5)

| IP | Device |
|----|--------|
| `.10` | **scarif** (pc white) · Unraid NAS |
| `.11` | **yavin** (Talos CP #1) |
| `.12` | **hoth** (target · Phase 4) |
| `.13` | **endor** (target · Phase 4) |
| `.14` | **naboo** (Talos worker · Ready on `prd`) |
| `.20` | API VIP (optional · Phase 4) |
| `.111` | **yavin** onboard 1G fallback |

### Topology

```
AT&T → UDM Pro (.1)
         └─ 10G ─ USW Aggregation (.13)
                    ├─ SFP+ 1 ─ pc black (.12) 10G
                    ├─ SFP+ 2 ─ pc white / **scarif** (`.5.10`) 10G NAS · **Homelab VLAN 5**
                    ├─ SFP+ 3 ─ Flex 2.5G (.109) ─ APs, Bedroom, Flex Mini
                    ├─ SFP+ 5 ─ Pro Max 16 (.197)
                    │              ├─ Port 5 ─ yavin onboard 1G → Homelab VLAN 5
                    │              ├─ Port 13 ─ yavin USB 2.5G → Homelab VLAN 5
                    │              └─ Ports 1–3, … ─ PDU, IoT, clients · LAN DNS → Homelab `.22`
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
| 5 | **yavin** onboard 1G · Homelab VLAN 5 (`192.168.5.111`) |
| 6 | pc (black) onboard GbE |
| 7, 10, 11 | Unknown · same MAC `04:92:26:c1:6c:51` |
| 8–9 | Empty |
| 12 | Living-Room client |
| 13 | **yavin** USB 2.5G · Homelab VLAN 5 |
| 14, 16 | Pulsar-MBP |
| 15 | Empty / TBD |
| SFP+ 1 | Unknown MAC `70:a7:41:7c:9c:69` |
| SFP+ 2 | Aggregation uplink |

#### Flex 2.5G 8 PoE

Managed in `infrastructure/unifi/devices.tf` (`unifi_device.flex_2_5g_8`).

| Port | Connected |
|------|-----------|
| 1–2 | U6 LR · U6 Pro |
| 3 | **kohler-gen** · IoT VLAN 2 (standby generator) |
| 4–6, 9 | Empty |
| 7 | Bedroom · `.107` |
| 8 | Flex Mini · `.225` |
| 10 | Aggregation uplink |

---

## Why change

- ~~No dedicated NAS~~ → **scarif** live; media on NFS; Phase 1 storage **done**
- Prefer Talos + GitOps — bare-metal **yavin** → **expand to 3 CPs**; migrate apps **once**
- **pc (black)** retained until leftover guests stopped, then personal gaming
- ~~Homelab VLAN + OpenTofu before Talos~~ → Phase **1.5 done**; scarif on `.5.10`
- ~~3-node Proxmox cluster~~ → **homelab02** standalone (Aug 2026); Mini off cluster, ready for Talos
