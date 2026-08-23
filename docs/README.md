# Homelab docs

Planning docs for the GitOps homelab. Implementation code will live under `infrastructure/`, `apps/`, and `clusters/` later.

| Doc | What it is |
|-----|------------|
| [Inventory](inventory.md) | What exists **today** |
| [Architecture overview](architecture/overview.md) | Goals, topology, hardware end state, non-goals |
| [Kubernetes platform](architecture/platform.md) | Talos stack, apps, repo layout |
| [Storage (Unraid)](architecture/storage.md) | Disks, NFS + iSCSI, shares |
| [Networking](architecture/networking.md) | UniFi VLAN, DNS/TLS, Tailscale, domains |
| [GPU](architecture/gpu.md) | Jellyfin encode (optional; direct play OK) |
| [Media / VPN](architecture/media.md) | *arr + qBittorrent; Mullvad for peers, UI off-VPN |
| [Secrets](architecture/secrets.md) | 1Password → cluster |
| [Agent access](architecture/agents.md) | Cursor / AI operators on the tailnet |
| [Roadmap](roadmap.md) | Phased migration checklists |
| [Decisions](decisions.md) | Locked leans (single source of truth) |

Start with [overview](architecture/overview.md) + [decisions](decisions.md), then use [roadmap](roadmap.md) as the working checklist.
