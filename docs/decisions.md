# Decisions

Locked leans for the lab. Update here when something changes; [roadmap](roadmap.md) and architecture docs should match this table.

| Area | Decision |
|------|----------|
| Sequence | **1)** Unraid owns 24TB → **1.5)** homelab VLAN + OpenTofu → **2)** bare-metal Talos on yavin → **3)** migrate apps (Pi-hole **last**) → **4)** expand to **3 CPs** |
| Compute (bootstrap) | **Bare-metal Talos** on Mac Mini (**yavin**) — single-node `prd`; **`allowSchedulingOnControlPlanes: true`** |
| Compute (steady) | **3 bare-metal Talos control planes**: **yavin** + **hoth** + **endor**; all schedule workloads |
| Cluster scale-out | **Expand in place** (join CPs to existing etcd) when mini PCs arrive — **not** a full cluster rebuild |
| Cluster API endpoint | **`k8s.lab.jacobdrury.com`** — stable DNS from first bootstrap; VIP or DNS update at 3 CPs |
| Homelab VLAN | **Before Talos bootstrap** — UniFi network name **`Homelab`**, VLAN **6**, `192.168.6.0/24` |
| IaC | **OpenTofu first** — `infrastructure/dns/` + `infrastructure/unifi/`; local gitignored state on Mac |
| Infra DNS | `*.lab.jacobdrury.com` in Cloudflare (OpenTofu) — see [networking](architecture/networking.md#infra-dns) |
| yavin networking | **USB 2.5G** (UGREEN RTL8156BG) **primary**; onboard **1G** **secondary**; pin interfaces by MAC in Talos machine config |
| Cluster availability | **No HA** until 3 CPs; single-node downtime acceptable (matches today) |
| Talos extensions (yavin) | `intel-ucode`, `i915`; `realtek-firmware` optional; `iscsi-tools` when block PVCs needed |
| Compute (exit) | **pc (black)** → personal gaming **after** workloads leave; **retain during transition** |
| NAS | **Unraid bare metal on pc (white)**; USB boot + license; GTX 780 **removed** |
| Apps vs NAS | Unraid is **storage only**; apps go to k8s/GitOps (no Unraid Docker as intermediate) |
| Array start | **24TB via Unassigned Devices** (keep filesystem; **no new large drive**); array/parity only when a second large disk or free space exists |
| 2TB HDD | **Out of Unraid plan** for now |
| Appdata | Existing **NVMe/SATA SSDs** on pc (white) |
| k8s storage | **NFS + iSCSI → Unraid** (NFS for media/shared; iSCSI for block/RWO). Not Longhorn/Ceph primary |
| Clusters | **`prd` first**; keep `stg` paths for later; hostnames `*.lab` vs `*.stg.lab` |
| CNI | **Cilium** |
| GitOps | **Argo CD** + this GitHub repo |
| Ingress | **Envoy Gateway** (Gateway API) |
| Secrets | **1Password** + Connect + External Secrets |
| Mesh | **Tailscale operator** + Unraid on tailnet; subnet router only if needed |
| Domain | `lab.jacobdrury.com`; registrar Squarespace → **Cloudflare DNS** (OpenTofu), full Cloudflare transfer later |
| TLS | cert-manager + **Let’s Encrypt DNS-01** via Cloudflare |
| App DNS | Start **always Tailscale** for app hostnames |
| Homelab firewall | **Phase 1.5:** allow **all** Drury (VLAN 1) → Homelab; deny Homelab → IoT/guest/camera; tighten later (Tailscale / allowlist) |
| Unraid IP | **Static on Unraid** outside DHCP pool (e.g. `.10`) |
| UniFi IaC | OpenTofu under `infrastructure/unifi/` — **required before Talos** (with homelab VLAN) |
| DNS app | **Pi-hole** in k8s — migrate **last** from pc (black) LXC; keeps `.11` until cutover |
| Media GPU | Jellyfin in k8s; **GPU/QSV optional** (720/1080 direct play today). Mini iGPU later if needed |
| Apps (migrate order) | *arr + qBit → Jellyfin → Homepage → HA → **Pi-hole last** |
| qBittorrent VPN | Peers via **Mullvad WG**; UI at **`qbittorrent.lab.jacobdrury.com`** (normal Envoy lab exposure) |
| Power | Prefer fewer always-on watts when cheap (strip white GPU; black off when gaming-only); **not** a reason to defer k8s/GitOps |
| Laptops | Precision optional NVENC/burst; Inspiron **out of lab plan** |
| Backups | **Decide after Unraid is up** (parity ≠ backup; UD has no parity) |
| Tooling | **proto + moon** ([moonrepo](https://moonrepo.dev/)) |
| Dep updates | **Renovate later**; no Dependabot version updates |
| CI | None until there’s something meaningful to check |
| Agents | **First-class**: Tailscale + kubeconfig + lab HTTPS + `op`; GitOps preferred |
| Host naming | **Star Wars planets** for physical hosts + Talos nodes; Unraid NAS = **`scarif`** — [naming](architecture/naming.md) |
