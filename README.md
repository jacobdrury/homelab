# Homelab

GitOps-managed home lab: **Talos** · **Unraid** · **Tailscale** · **Argo CD** · **UniFi VLAN** · agent-operable.

## At a glance

| | Today | Target |
|---|--------|--------|
| Compute | Proxmox (Mini + pc black + pc white) | Talos `prd`: interim Mini VM → **3 BM CPs** (Mini + 2 mini PCs) |
| Storage | 24TB on pc (black) | Unraid on **pc (white)** — UD 24TB → **NFS + iSCSI** |
| pc (black) | Media + HA | **Personal gaming** (after cutover) |
| Network | UniFi (flat-ish) | Homelab **VLAN** + Tailscale |
| Apps | Pi-hole, HA, Jellyfin, *arr, qBit, Prowlarr | Same on k8s + Homepage; HA after media |
| Delivery | Manual guests | Argo CD ← this repo |
| Secrets | Ad hoc | 1Password → Connect → ESO |
| Access | Partial Tailscale | `*.lab.jacobdrury.com` + **AI agents on the tailnet** |

**Next:** Phase 1 — Unraid on white, expose 24TB (USB stick ordered). Then Talos on Mini, then migrate.

## Docs

Full index: **[docs/README.md](docs/README.md)**

- [Decisions](docs/decisions.md) — locked leans  
- [Naming](docs/architecture/naming.md) — Star Wars planet hostnames (`scarif`, `yavin`, …)  
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

Inventory done. Executing [roadmap](docs/roadmap.md): **Unraid NAS → Talos `prd` → migrate apps → mini PCs / free black PC**.
