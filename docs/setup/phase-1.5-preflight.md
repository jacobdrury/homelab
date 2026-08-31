# Phase 1.5 preflight (locked)

Answers captured before OpenTofu work. Source of truth for operators; leans also in [decisions](../decisions.md).

**Status: complete (2026-08-30).** scarif on Homelab VLAN; arr NFS validated. Phase 2 (Talos on yavin) unblocked.

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
| GitHub Pages | **Must keep working** at apex + `www` — codified in `infrastructure/dns/` |
| API token | **1Password:** `Cloudflare Zone DNS API Token` |
| UniFi API | **1Password:** `Unifi API Key (opentofu-homelab)` · item id `bqbnkqxcyyg6h72orwebvozdjm` for `op read` |
| GitHub Pages (preserve in Tofu) | Apex `jacobdrury.com` → A `185.199.108.153`, `.109`, `.110`, `.111` · `www` → CNAME `jacobdrury.github.io` (DNS only) |

## UniFi

| Item | Decision |
|------|----------|
| Controller | `https://192.168.1.1` (local + cloud UI) |
| Network version | **10.5.67** |
| Homelab network in UI | **Created** — OpenTofu `infrastructure/unifi/` (applied 2026-08-29) |
| API auth | **Local API key** → 1Password **`Unifi API Key (opentofu-homelab)`** (`op://Homelab/bqbnkqxcyyg6h72orwebvozdjm/credential`) |
| Apply from Mac | `https://192.168.1.1` — use **local** key, not Site Manager key |
| Port map | Aggregation **SFP+ 2** → **Homelab** VLAN 5 (applied 2026-08-30) |

Homelab uses **VLAN 5 / `192.168.5.0/24`** because UniFi Teleport already reserves **`192.168.6.0/24`**.

## Pi-hole

| Item | Decision |
|------|----------|
| Instance | LXC **106** on pc (black) · `192.168.1.11` |
| Config IaC | **`infrastructure/pihole/`** — OpenTofu via Pi-hole v6 API |
| API auth | **1Password:** `Pi-hole API` (app password) |
| Write access | **`webserver.api.app_sudo`** = true (All settings) |
| `*.lab.jacobdrury.com` | **Forward** to Cloudflare (`1.1.1.1`, `1.0.0.1`) — records live in `infrastructure/dns/` only |
| `*.homelab.com` | **Local** A records in `local_dns.auto.tfvars` — **transitional**; retire when apps use `*.lab` on k8s |
| Migrate to k8s | Phase 3 **last** — same OpenTofu module, new `pihole_url` |

## OpenTofu

| Item | Decision |
|------|----------|
| Apply from | **This Mac only** |
| State | **Local** `*.tfstate` on Mac, **gitignored** — Git tracks `.tf` config only |
| Remote state | Optional later (OpenTofu Cloud / Terraform Cloud); not Phase 1.5 |
| Moon projects | `dns`, `unifi`, `pihole` — tag `opentofu` |
| IaC policy | [architecture/iac.md](../architecture/iac.md) |

## homelab02 guests (migrated from Mini)

| Name | VMID |
|------|------|
| Pi-hole LXC | **106** |
| discord-bots VM | **103** |

## Deferred

| Item | When |
|------|------|
| Tailscale on scarif | Optional — **`https://scarif.lab`** via Envoy proxy; Unraid plugin not required |
| Tailscale split DNS + routes | **`infrastructure/tailscale/`** — `moon run tailscale:apply` · [README](../../infrastructure/tailscale/README.md) |
| Switch port VLAN breakdown | **Done** — Aggregation SFP+ 2 |
| `webserver.api.max_sessions` in OpenTofu | Optional — raise in UI if bulk import hits 429 |

## Exit checklist

- [x] `infrastructure/dns/` — GitHub Pages + `*.lab.jacobdrury.com` infra records (applied 2026-08-29)
- [x] `infrastructure/unifi/` — **Homelab** VLAN 5 + firewall (applied 2026-08-29)
- [x] `infrastructure/pihole/` — full config in Git; zone forward + local `*.homelab.com` (applied 2026-08-29)
- [x] `dig @192.168.1.11 k8s.lab.jacobdrury.com` → `192.168.5.11` (Cloudflare via forward)
- [x] `dig @192.168.1.11 scarif.lab.jacobdrury.com` → `192.168.5.10` (Cloudflare via forward)
- [x] Switch port: scarif on **Homelab** VLAN 5 (Aggregation SFP+ 2)
- [x] scarif **live** on `192.168.5.10` (**eth1** 10G; bonding/bridging off; migrated 2026-08-30)
- [x] arr VM NFS fstab → `scarif.lab.jacobdrury.com`; Jellyfin playback over `.5` OK

**Phase 1.5 done.** Start Phase 2 (Talos on yavin).
