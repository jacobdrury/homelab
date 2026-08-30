# Naming (Star Wars planets)

Host and infrastructure naming for the lab. Locked decision — see [decisions](../decisions.md).

## Theme

**Star Wars planets** for physical machines and Talos nodes. Match name to role where it helps; keep names **lowercase**, **no spaces**, **≤15 characters** (Unraid, SMB, mDNS, Tailscale MagicDNS).

**App URLs stay functional:** `*.lab.jacobdrury.com` / `*.stg.lab.jacobdrury.com` — not planet names. Planets are for **hosts**, **Tailscale**, **NFS/iSCSI targets**, and **Kubernetes node names**.

## Host map

| Codename | Hardware | Role | Status | IP (today) | Legacy name |
|----------|----------|------|--------|------------|-------------|
| **scarif** | pc (white) | Unraid NAS — NFS + iSCSI | **Active** (Phase 1 done) | `192.168.1.10` | `homelab` |
| **yavin** | Mac Mini | Bare-metal Talos CP #1 (single-node → 3 CP) | Phase 2 | `192.168.1.15` | `homelab03` (Proxmox today) |
| **dantooine** | Mini PC #1 | Talos CP #2 (bare metal) | Planned (Phase 4) | TBD | — |
| **lothal** | Mini PC #2 | Talos CP #3 (bare metal) | Planned (Phase 4) | TBD | — |

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
| **dantooine** | Remote rebel outpost — second control plane |
| **lothal** | Growing rebel cell — third control plane |

## Usage by layer

| Layer | Convention | Example |
|-------|------------|---------|
| Unraid hostname | Planet | `scarif` |
| Tailscale machine name | Same as hostname | `scarif` |
| Talos / Kubernetes node name | Same as hostname | `yavin`, `dantooine`, `lothal` |
| NFS server | Hostname or static IP | `scarif` or `192.168.1.10` |
| SMB / mDNS | Hostname | `scarif.local` |
| App ingress (Envoy) | Functional subdomain | `jellyfin.lab.jacobdrury.com` |
| GitOps paths | Environment, not planet | `clusters/prd/`, `infrastructure/prd/` |
| Kubernetes Services | Functional | `pihole`, `jellyfin`, not `jedha` |

## Migration from legacy names

Replace Proxmox-era hostnames as each machine is rebuilt or re-rolled:

1. **scarif** — set at Unraid USB creation (Phase 1); retires `homelab` on pc (white).
2. **yavin** — set at bare-metal Talos install on the Mac Mini (Phase 2); retires `homelab03`.
3. **dantooine** / **lothal** — set at first Talos boot on each mini PC (Phase 4).

Update [inventory](../inventory.md) when a rename is done. Prefer DNS/Tailscale names over bare IPs in docs and manifests once stable.

## Optional extensions (not required)

If the lab grows and you want a second naming layer:

- **Starships** — long-lived VMs or special guests outside the Talos cluster
- **Droids** — disposable dev containers or test namespaces

Do not adopt these until there is a concrete need; planets cover the steady-state design.

## Related

- [Decisions](../decisions.md) · [Inventory](../inventory.md) · [Overview](overview.md) · [Platform](platform.md) · [Agents](agents.md)
