# Homelab docs

Planning and architecture docs for the GitOps homelab. **OpenTofu** modules live under `infrastructure/` (DNS, UniFi, Pi-hole); **Helm/Argo** under `apps/` and `clusters/` starting Phase 2.

| Doc | What it is |
|-----|------------|
| [Inventory](inventory.md) | What exists **today** |
| [Architecture overview](architecture/overview.md) | Goals, topology, hardware end state, non-goals |
| [Naming (Star Wars planets)](architecture/naming.md) | Host codenames (`scarif`, `yavin`, …) for agents and operators |
| [Kubernetes platform](architecture/platform.md) | Talos stack, apps, repo layout |
| [Storage (Unraid)](architecture/storage.md) | Disks, NFS + iSCSI, shares |
| [Networking](architecture/networking.md) | UniFi VLAN, DNS/TLS, Tailscale, domains |
| [IaC](architecture/iac.md) | OpenTofu vs Helm/Argo; what lives in Git; manual exceptions |
| [GPU](architecture/gpu.md) | Jellyfin encode (optional; direct play OK) |
| [Media / VPN](architecture/media.md) | *arr + qBittorrent; Mullvad for peers, UI off-VPN |
| [Secrets](architecture/secrets.md) | 1Password → cluster |
| [Agent access](architecture/agents.md) | Cursor / AI operators on the tailnet |
| [Roadmap](roadmap.md) | Phased migration checklists |
| [Decisions](decisions.md) | Locked leans (single source of truth) |

| Start with [overview](architecture/overview.md) + [decisions](decisions.md), then use [roadmap](roadmap.md) as the working checklist.

## Setup

| Doc | What it is |
|-----|------------|
| [Infrastructure README](../infrastructure/README.md) | OpenTofu apply order (`dns/`, `unifi/`, `pihole/`) |
| [Local tools](setup/local-tools.md) | Homebrew, 1Password CLI, proto/moon, OpenTofu env |
| [Phase 1.5 preflight](setup/phase-1.5-preflight.md) | Locked VLAN + DNS answers (**complete** · Aug 2026) |
