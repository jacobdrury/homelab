# Homelab

GitOps-managed home lab: **Talos** · **Unraid** · **Tailscale** · **Argo CD** · **UniFi VLAN** · agent-operable.

## At a glance

| | Today | Target |
|---|--------|--------|
| Compute | Proxmox (Mac Mini + Gaming PC #1) | Talos (`prd`; mini PCs; interim VMs on Mac Mini) |
| Storage | 24TB on Gaming PC #1 | Unraid on **PC #2** — **NFS + iSCSI** to cluster |
| Gaming PC #1 | Lab host | **Personal gaming** |
| Network | UniFi (flat-ish) | Homelab **VLAN** + Tailscale |
| Apps | Pi-hole, HA, Jellyfin, *arr, qBit, Prowlarr | Same on k8s + Homepage; HA after media |
| Delivery | Manual guests | Argo CD ← this repo |
| Secrets | Ad hoc | 1Password → Connect → ESO |
| Access | Partial Tailscale | `*.lab.jacobdrury.com` + **AI agents on the tailnet** |

## Docs

Full index: **[docs/README.md](docs/README.md)**

- [Decisions](docs/decisions.md) — locked leans  
- [Inventory](docs/inventory.md) — fill in hosts / VMs  
- [Architecture](docs/architecture/overview.md) — target design  
- [Roadmap](docs/roadmap.md) — phased checklist  

## Tooling (moon + proto)

```bash
bash <(curl -fsSL https://moonrepo.dev/install/proto.sh)
export PATH="$HOME/.proto/bin:$PATH"

proto install                 # or: moon run root:tools-install
moon run root:check
```

Pins: [`.prototools`](.prototools). Renovate planned later for dependency PRs.

## Status

Early planning. Next: inventory Proxmox guests, then Phase 1 (VLAN + Unraid).
