# Naming (Star Wars planets)

Host and infrastructure naming for the lab. Locked decision — see [decisions](../decisions.md).

## Theme

**Star Wars planets** for physical machines and Talos nodes. Match name to role where it helps; keep names **lowercase**, **no spaces**, **≤15 characters** (Unraid, SMB, mDNS, Tailscale MagicDNS).

**App URLs stay functional:** `*.lab.jacobdrury.com` / `*.stg.lab.jacobdrury.com` — not planet names. Planets are for **hosts**, **Tailscale**, **NFS/iSCSI targets**, and **Kubernetes node names**.

## Host map

| Codename | Hardware | Role | Status | IP (today) | Legacy name |
|----------|----------|------|--------|------------|-------------|
| **scarif** | pc (white) | Unraid NAS — NFS + iSCSI | **Active** | `192.168.5.10` | `homelab` |
| **yavin** | Mac Mini | Bare-metal Talos CP #1 | **Active** (`prd`) | `192.168.5.11` | `homelab03` (Proxmox · retired) |
| **naboo** | Unraid VM on **scarif** | Talos **worker** (interim) | **Active** (`prd`, Sep 2026) | `192.168.5.14` | — |
| **hoth** | Mini PC #1 | Talos CP #2 (bare metal) | Planned (Phase 4) | `192.168.5.12` | — |
| **endor** | Mini PC #2 | Talos CP #3 (bare metal) | Planned (Phase 4) | `192.168.5.13` | — |

**Out of theme**

| Machine | Notes |
|---------|--------|
| pc (black) | Leaving lab → personal gaming; keep its own name, not part of the planet scheme |
| Laptops | Out of lab plan or optional burst; no assigned codename |

### Why these names

| Codename | Rationale |
|----------|-----------|
| **scarif** | Imperial data archive — central storage for the lab |
| **yavin** | Rebel base / command — primary cluster node and GitOps anchor |
| **naboo** | Peaceful world with spare capacity — interim worker on scarif until dedicated CPs arrive |
| **hoth** | Remote rebel base — second control plane |
| **endor** | Forest moon outpost — third control plane |

## Usage by layer

| Layer | Convention | Example |
|-------|------------|---------|
| Unraid hostname | Planet | `scarif` |
| Tailscale machine name | Same as hostname | `scarif` |
| Talos / Kubernetes node name | Same as hostname | `yavin`, `naboo`, `hoth`, `endor` |
| NFS / iSCSI server | Storage DNS (not UI) | `scarif-nfs.lab.jacobdrury.com` → Unraid; `scarif.lab` is HTTPS UI via Envoy |
| SMB / mDNS | Hostname | `scarif.local` |
| App ingress (Envoy) | Functional subdomain | `jellyfin.lab.jacobdrury.com` |
| GitOps paths | Environment, not planet | `clusters/prd/`, `infrastructure/talos/prd/` |
| Kubernetes Services | Functional | `pihole`, `jellyfin`, not `jedha` |

## Migration from legacy names

Replace Proxmox-era hostnames as each machine is rebuilt or re-rolled:

1. **scarif** — set at Unraid USB creation (Phase 1); retires `homelab` on pc (white).
2. **yavin** — set at bare-metal Talos install on the Mac Mini (Phase 2); retires `homelab03`.
3. **naboo** — Unraid KVM guest on scarif; Talos **worker** live on `prd` (Sep 2026); drain + remove when **hoth**/**endor** take load (Phase 4).
4. **hoth** / **endor** — set at first Talos boot on each mini PC (Phase 4).

Update [inventory](../inventory.md) when a rename is done. Prefer DNS/Tailscale names over bare IPs in docs and manifests once stable.

## Optional extensions (not required)

If the lab grows and you want a second naming layer:

- **Starships** — long-lived VMs or special guests outside the Talos cluster
- **Droids** — disposable dev containers or test namespaces

Do not adopt these until there is a concrete need; planets cover the steady-state design.

## Related

- [Decisions](../decisions.md) · [Inventory](../inventory.md) · [Overview](overview.md) · [Platform](platform.md) · [Agents](agents.md)
