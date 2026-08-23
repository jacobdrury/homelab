# Decisions

Locked leans for the lab. Update here when something changes; [roadmap](roadmap.md) and architecture docs should match this table.

| Area | Decision |
|------|----------|
| Compute (steady) | Talos on mini PCs; interim Talos VMs on **Mac Mini** Proxmox |
| Compute (exit) | **Gaming PC #1** → personal gaming (after media/VMs leave) |
| NAS | **Unraid bare metal on Gaming PC #2**; buy license + USB |
| Array start | **24TB data only**, no parity; parity disk **≥24TB** later |
| 2TB HDD | **Out of Unraid plan** for now |
| Appdata | Existing **NVMe/SATA SSDs** on PC #2 |
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
| Media GPU | Pattern B: Jellyfin in k8s; prefer **Mac Mini iGPU** worker first |
| Apps | Jellyfin, *arr, qBit, Prowlarr, Pi-hole, **Homepage**, HA **after media**; monitoring Prometheus/Grafana/Uptime Kuma → Discord |
| Backups | **Decide after Unraid is up** (parity ≠ backup) |
| Tooling | **proto + moon** ([moonrepo](https://moonrepo.dev/)) |
| Dep updates | **Renovate later**; no Dependabot version updates |
| CI | None until there’s something meaningful to check |
| Agents | **First-class**: Tailscale + kubeconfig + lab HTTPS + `op`; GitOps preferred |
