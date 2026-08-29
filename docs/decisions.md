# Decisions

Locked leans for the lab. Update here when something changes; [roadmap](roadmap.md) and architecture docs should match this table.

| Area | Decision |
|------|----------|
| Sequence | **1)** Unraid owns 24TB → **2)** Talos `prd` on Mini VMs → **3)** migrate apps once stable → **4)** 3-node BM cluster + free pc (black) |
| Compute (interim) | Talos **VM(s) on Mac Mini Proxmox** — single-node `prd` OK (`allowSchedulingOnControlPlanes`) |
| Compute (steady) | **3 bare-metal Talos control planes**: Mac Mini + **2 mini PCs**; all schedule workloads |
| Cluster scale-out | Prefer **GitOps rebuild** (fresh 3-CP + Argo sync) over live 1→3 etcd expansion when mini PCs arrive |
| Compute (exit) | **pc (black)** → personal gaming **after** workloads leave; **retain during transition** |
| NAS | **Unraid bare metal on pc (white)**; USB boot (ordered) + license; **remove GTX 780** |
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
| LAN | UniFi **homelab VLAN** + selective firewall |
| Unraid IP | **Static on Unraid** outside DHCP pool (e.g. `.10`) |
| UniFi IaC | OpenTofu under `infrastructure/unifi/` (UI OK to unblock) |
| DNS app | Keep **Pi-hole** |
| Media GPU | Jellyfin in k8s; **GPU/QSV optional** (720/1080 direct play today). Mini iGPU later if needed |
| Apps | Jellyfin, *arr, qBit, Prowlarr, Pi-hole, **Homepage**, HA after media; monitoring → Discord |
| qBittorrent VPN | Peers via **Mullvad WG**; UI at **`qbittorrent.lab.jacobdrury.com`** (normal Envoy lab exposure) |
| Power | Prefer fewer always-on watts when cheap (strip white GPU; black off when gaming-only); **not** a reason to defer k8s/GitOps |
| Laptops | Precision optional NVENC/burst; Inspiron **out of lab plan** |
| Backups | **Decide after Unraid is up** (parity ≠ backup; UD has no parity) |
| Tooling | **proto + moon** ([moonrepo](https://moonrepo.dev/)) |
| Dep updates | **Renovate later**; no Dependabot version updates |
| CI | None until there’s something meaningful to check |
| Agents | **First-class**: Tailscale + kubeconfig + lab HTTPS + `op`; GitOps preferred |
| Host naming | **Star Wars planets** for physical hosts + Talos nodes; Unraid NAS = **`scarif`** — [naming](architecture/naming.md) |
