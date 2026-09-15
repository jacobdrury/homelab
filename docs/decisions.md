# Decisions

Locked leans for the lab. Update here when something changes; [roadmap](roadmap.md) and architecture docs should match this table.

| Area | Decision |
|------|----------|
| Sequence | **1)** Unraid owns 24TB → **1.5)** homelab VLAN + OpenTofu → **2)** bare-metal Talos on yavin → **3)** migrate apps (Pi-hole **last**) → **4)** expand to **3 CPs** |
| Compute (bootstrap) | **Bare-metal Talos** on Mac Mini (**yavin**) — single-node `prd`; **`allowSchedulingOnControlPlanes: true`** |
| Compute (interim worker) | **naboo** — Talos **worker** VM on **scarif** (Unraid KVM); Homelab `.14`; SSD-backed; **not** a CP; drain when hoth/endor arrive |
| Compute (steady) | **3 bare-metal Talos control planes**: **yavin** + **hoth** + **endor**; all schedule workloads |
| Cluster scale-out | **Expand in place** (join CPs to existing etcd) when mini PCs arrive — **not** a full cluster rebuild |
| Cluster API endpoint | **`k8s.lab.jacobdrury.com`** — stable DNS from first bootstrap; VIP or DNS update at 3 CPs |
| Homelab VLAN | **Before Talos bootstrap** — UniFi network name **`Homelab`**, VLAN **5**, `192.168.5.0/24` (reuses former Work VLAN; Teleport holds `.6`) |
| IaC | **GitOps first** (Helm/Argo/blueprints/ConfigMaps); **OpenTofu only** when no GitOps-native path (DNS, UniFi, Tailscale, Talos; Pi-hole LXC until cutover); secrets via 1Password — [iac](architecture/iac.md) · [agents](architecture/agents.md#gitops-first-opentofu-when-needed) |
| Infra DNS | `*.lab.jacobdrury.com` in Cloudflare (OpenTofu) — see [networking](architecture/networking.md#infra-dns) |
| yavin networking | **USB 2.5G** (UGREEN RTL8156BG) **primary**; onboard **1G** **secondary**; pin interfaces by MAC in Talos machine config |
| Cluster availability | **No HA** until 3 CPs; single-node downtime acceptable (matches today) |
| Talos extensions (yavin) | `intel-ucode`, `i915`; `realtek-firmware` optional; `iscsi-tools` when block PVCs needed |
| Compute (exit) | **pc (black)** → personal gaming **after** workloads leave; **retain during transition** |
| NAS | **Unraid bare metal on pc (white)**; USB boot + license; GTX 780 **removed** |
| Apps vs NAS | Unraid is **storage only** for apps (no Unraid Docker). **Exception:** interim Talos worker VM **naboo** on scarif for k8s compute headroom |
| Array start | **24TB via Unassigned Devices** (keep filesystem; **no new large drive**); array/parity only when a second large disk or free space exists |
| 2TB HDD | **Out of Unraid plan** for now |
| Appdata | Existing **NVMe/SATA SSDs** on pc (white) |
| k8s storage | **NFS + iSCSI → Unraid** (both CSI in Phase 2 housekeeping). **NFS RWX** = media/shared; **iSCSI RWO** = config/SQLite/DBs (**one PVC per replica**). No node-local app data; pods stay movable. Not Longhorn/Ceph primary |
| Clusters | **`prd` first**; keep `stg` paths for later; hostnames `*.lab` vs `*.stg.lab` |
| CNI | **Cilium** |
| GitOps | **Argo CD** + this GitHub repo |
| Ingress | **Envoy Gateway** (Gateway API) |
| Secrets | **1Password** + Connect + External Secrets |
| Identity / SSO | **Authentik** at `auth.lab.jacobdrury.com` — OIDC-first; directory config via **blueprints** in Git (not OpenTofu); forward auth later for legacy UIs |
| Postgres (apps) | **CloudNativePG** on `scarif-iscsi`. **Shared multi-DB:** `media-pg` (*arr). **Target:** collapse remaining app Clusters (e.g. Authentik) into one lab Postgres when convenient. Chart-bundled Postgres only for demos |
| MariaDB (apps) | **Shared MariaDB** (`platform/mariadb/`) — one instance, many databases; Uptime Kuma first consumer. Prefer over SQLite when the app supports MariaDB/MySQL |
| SQLite | Only when the app cannot use Postgres or MariaDB — RWO PVC on `scarif-iscsi` |
| Host SSH / sudo | **1Password** + **SSH keys** (1Password agent); Host aliases (scarif, homelab02, arr archive, HA, pihole, …); **shared lab admin sudo password** in 1P; no private keys in Git; Talos = **talosctl** |
| Mesh | **Tailscale operator** on `prd` advertises **`192.168.5.0/24`** (steady subnet router); **homelab02 interim** until pc (black) leaves; tailnet DNS in **`infrastructure/tailscale/`** |
| Domain | `lab.jacobdrury.com`; registrar Squarespace → **Cloudflare DNS** (OpenTofu), full Cloudflare transfer later |
| TLS | cert-manager + **Let’s Encrypt DNS-01** via Cloudflare; wildcard **`*.lab.jacobdrury.com`** on Envoy; **scarif** HTTPS via Envoy proxy to Unraid HTTP |
| Remote `*.lab` URLs | **Same names** home and away: Cloudflare RFC1918 A records; LAN via Pi-hole forward; Tailscale **split DNS → Cloudflare** + **subnet router** — [networking](architecture/networking.md#same-urls-at-home-and-away) |
| Homelab firewall | **Zone-Based Firewall** (UniFi OS 9+): Drury → Homelab allow all; **Homelab → IoT allow**; **IoT → Homelab Envoy `.21:80/443`**; Homelab → Guest/Camera deny; **IoT/Isolated → Pi-hole DNS `.22`**; Homelab → Drury = transitional Proxmox only — [networking](architecture/networking.md) |
| Unraid IP | **Static on Unraid** outside DHCP pool (e.g. `.10`) |
| UniFi IaC | OpenTofu under `infrastructure/unifi/` — **required before Talos** (with homelab VLAN) |
| DNS app | **Pi-hole** in k8s — **Deployment ×2**, ConfigMaps SoT, Cilium L2 VIP `.22`; migrate **last** from LXC; Authentik Proxy for UI |
| Pi-hole IaC | **k8s:** ConfigMaps in GitOps. **LXC OpenTofu** (`services.pihole.lxc`) until LXC stopped, then retire |
| Legacy DNS | **`*.homelab.com`** Pi-hole local records — **transitional**; retire as apps move to `*.lab` (`arr.homelab.com` retired Sep 2026) |
| Media GPU | Jellyfin in k8s; **GPU/QSV optional** (720/1080 direct play today). Mini iGPU later if needed |
| Apps (migrate order) | ~~*arr + qBit → Jellyfin → HA~~ **done** → **Pi-hole last**. **URLs first:** Envoy transitional routes; swap backends at cutover. **Homepage** = first GitOps app after Envoy |
| Observability timing | Bootstrap: **`connect/`** + k9s + talosctl. **Homepage** first after Envoy (Uptime Kuma with/after it). **metrics-server** early (Metrics API / Homepage / HPA — not the full stack). **Prometheus/Grafana** Phase 5 |
| Transitional ingress | Envoy `*.lab` → in-cluster Services after cutover (media + HA); remaining Pi-hole / scarif / proxmox still transitional — **no DNS/URL change** at cutover |
| Games (ATM10) | **Phase 6** — after core platform stable; **itzg/minecraft-server** on k8s; iSCSI block PVC; pin to beefiest node — [games](architecture/games.md) |
| Friend remote access | **Tailscale per-service expose** (`*.ts.net`); `group:friends` → `tag:shared` only (Jellyfin + Minecraft); **no** subnet routes for friends — [games](architecture/games.md#friend-access--tailscale) |
| Friend Jellyfin HTTPS | **Tailscale L7 Ingress** (`ingressClassName: tailscale`) — LE cert on `https://jellyfin.<tailnet>.ts.net`; not L3 Service expose (self-signed) |
| Friend Minecraft | **Tailscale L3 Service expose** — TCP `:25565`; no HTTPS on game port |
| MagicDNS tailnet suffix | Rename once in **admin console** (word list); **not** OpenTofu; hostname prefixes in k8s GitOps |
| qBittorrent VPN | Peers via **Mullvad WireGuard sidecar** + qBit **bind to `wg0`**; UI at **`qbittorrent.lab.jacobdrury.com`** (not Gluetun on k8s) |
| Media UI auth | **Authentik Proxy** for Sonarr ×2 / Prowlarr / qBit; Jellyfin = Envoy → Service (native accounts); **Home Assistant = Envoy → Service + Authentik OIDC** (`authentik Admins` → HA owner; HTTP settings in UI after 2026.8) — [home-assistant](architecture/home-assistant.md) · [media](architecture/media.md) |
| Power | Prefer fewer always-on watts when cheap (strip white GPU; black off when gaming-only); **not** a reason to defer k8s/GitOps |
| Laptops | Precision optional NVENC/burst; Inspiron **out of lab plan** |
| Backups | **Decide after Unraid is up** (parity ≠ backup; UD has no parity) |
| Tooling | **proto + moon** ([moonrepo](https://moonrepo.dev/)) |
| Dep updates | **Renovate later**; no Dependabot version updates |
| CI / OpenTofu | **Manual apply** (`moon` on Mac) until Phase 2b; then **GitHub Actions** — cloud runners for `dns/`, **ARC runners in `prd`** for `unifi/` + `pihole/`; public repo → no fork PRs with secrets — [roadmap Phase 2b](roadmap.md#phase-2b--opentofu-ci-github-actions) |
| Agents | **First-class**: Tailscale + kubeconfig + lab HTTPS + `op`; GitOps preferred |
| Host naming | **Star Wars planets** for physical hosts + Talos nodes; Unraid = **`scarif`**; interim worker = **`naboo`** — [naming](architecture/naming.md) |
