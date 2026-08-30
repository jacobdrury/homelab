# Phase 1.5 preflight (locked)

Answers captured before OpenTofu work. Source of truth for operators; leans also in [decisions](../decisions.md).

## Network

| Item | Decision |
|------|----------|
| Homelab VLAN name | **`Homelab`** |
| VLAN ID | **5** (reuses former Work VLAN) |
| Subnet | `192.168.5.0/24` |
| VLAN 6 | Reserved by UniFi **Teleport VPN** — not used for Homelab |
| pc (black) / arr / Pi-hole | Stay on **VLAN 1** (`192.168.1.0/24`) until app migration |
| Phase 1.5 host moves | **scarif** → `192.168.5.10`; **yavin** at Talos install → `192.168.5.11` |
| scarif 10G port | Same physical port after VLAN change |

### Static IPs (Homelab VLAN)

| Host | IP |
|------|-----|
| scarif | `192.168.5.10` |
| yavin | `192.168.5.11` |
| hoth | `192.168.5.12` |
| endor | `192.168.5.13` |
| API VIP (later) | `192.168.5.20` |
| DHCP | `.6–.254` (same as other VLANs) |

### Firewall (intent)

- **Homelab is isolated from IoT / Guest / Camera** — deny homelab → those VLANs by default.
- **Drury (VLAN 1) → Homelab:** **allow all** for now (simple; no per-client or static IP rules).
- **arr VM** (`192.168.1.9`) → scarif NFS works via the above; no separate NFS rule required unless we tighten later.
- **Homelab → internet:** allow (updates, image pulls).
- **Tighten later:** client allowlist or Tailscale-only admin once homelab is stable.

## Cloudflare

| Item | Decision |
|------|----------|
| Zone status | **Active** — NS on Cloudflare (`poppy` / `skip`) |
| Registrar | Transfer in progress |
| GitHub Pages | **Must keep working** at apex + `www` — codify in `infrastructure/dns/` |
| API token | **1Password:** `Cloudflare Zone DNS API Token` |
| UniFi API | **1Password:** `Unifi API Key (opentofu-homelab)` · item id `bqbnkqxcyyg6h72orwebvozdjm` for `op read` |
| GitHub Pages (preserve in Tofu) | Apex `jacobdrury.com` → A `185.199.108.153`, `.109`, `.110`, `.111` · `www` → CNAME `jacobdrury.github.io` (DNS only) |

## UniFi

| Item | Decision |
|------|----------|
| Controller | `https://192.168.1.1` (local + cloud UI) |
| Network version | **10.5.67** |
| Homelab network in UI | **Not created yet** — OpenTofu owns creation |
| API auth | **Local API key** → 1Password **`Unifi API Key (opentofu-homelab)`** (`op://Homelab/bqbnkqxcyyg6h72orwebvozdjm/credential`) |
| Apply from Mac | `https://192.168.1.1` — use **local** key, not Site Manager key |
| Port map | TBD at apply time |

Homelab uses **VLAN 5 / `192.168.5.0/24`** because UniFi Teleport already reserves **`192.168.6.0/24`**.

## OpenTofu

| Item | Decision |
|------|----------|
| Apply from | **This Mac only** |
| State | **Local** `*.tfstate` on Mac, **gitignored** — Git tracks `.tf` config only |
| Remote state | Optional later (OpenTofu Cloud / Terraform Cloud); not Phase 1.5 |

## homelab02 guests (migrated from Mini)

| Name | VMID |
|------|------|
| Pi-hole LXC | **106** |
| discord-bots VM | **103** |

## Deferred

| Item | When |
|------|------|
| Tailscale on scarif | Phase 2 or when cluster path is up |
| Switch port VLAN breakdown | Before UniFi `tofu apply` |

## Exit checklist

- [x] `infrastructure/dns/` — GitHub Pages + `*.lab.jacobdrury.com` infra records (applied 2026-08-29; IPs updated to `.5` subnet)
- [x] `infrastructure/unifi/` — **Homelab** VLAN 5 + firewall (applied 2026-08-29)
- [ ] scarif on `192.168.5.10`; arr NFS fstab updated  
- [ ] `dig k8s.lab.jacobdrury.com` → `192.168.5.11` (after yavin / or placeholder until Phase 2)  
- [ ] `dig scarif.lab.jacobdrury.com` → `192.168.5.10`  
