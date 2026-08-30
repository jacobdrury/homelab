# Homelab

GitOps-managed home lab: **Talos** · **Unraid** · **Tailscale** · **Argo CD** · **UniFi VLAN** · agent-operable.

## At a glance

| | Today | Target |
|---|--------|--------|
| Compute | Proxmox (Mini + pc black) · **scarif = Unraid** | Talos `prd`: **bare-metal yavin** → **expand to 3 BM CPs** |
| Storage | **scarif** — 24TB UD · **NFS** (~8.7 TB used) | Same + optional array/parity · iSCSI when k8s needs it |
| pc (black) | arr + HA (media via NFS) | **Personal gaming** (after cutover) |
| Network | UniFi (flat-ish) | Homelab **VLAN** (OpenTofu) + Tailscale |
| Apps | Pi-hole, HA, Jellyfin, *arr, qBit, Prowlarr | Same on k8s + Homepage; HA after media |
| Delivery | Manual guests | Argo CD ← this repo |
| Secrets | Ad hoc | 1Password → Connect → ESO |
| Access | Partial Tailscale | `*.lab.jacobdrury.com` + **AI agents on the tailnet** |

**Next:** Phase **1.5** — homelab VLAN + OpenTofu (Cloudflare + UniFi). Then bare-metal Talos on **yavin**.

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

Pins: [`.prototools`](.prototools). Install: [docs/setup/local-tools.md](docs/setup/local-tools.md).

## Status

Inventory done. Phase 1 storage **done**. Executing [roadmap](docs/roadmap.md): **Talos `prd` → migrate apps → mini PCs / free black PC**.
