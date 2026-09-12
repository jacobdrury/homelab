# Homelab

GitOps-managed home lab: **Talos** · **Unraid** · **Tailscale** · **Argo CD** · **UniFi VLAN** · agent-operable.

## At a glance

| | Today | Target |
|---|--------|--------|
| Compute | Talos `prd`: **yavin** (CP) + **naboo** (worker on scarif) · Proxmox **homelab02** (legacy apps) | Expand to **3 BM CPs** (hoth/endor); drain naboo |
| Access | Tailscale IaC live; **`http://scarif.lab`** home + away; homelab02 interim router | Same URLs · **`https://`** via Envoy (Phase 2) · operator replaces homelab02 |
| Storage | **scarif** — 24TB UD · **NFS** (~8.7 TB used) · 500 GB NVMe hosts naboo | Same + optional array/parity · iSCSI when k8s needs it |
| pc (black) | arr + HA (media via NFS) | **Personal gaming** (after cutover) |
| Network | Homelab **VLAN 5** + UniFi **ZBF** · Drury (arr, Pi-hole) | Full lab on VLAN + Tailscale |
| Apps | Pi-hole, HA, Jellyfin, *arr, qBit, Prowlarr | Same on k8s + Homepage; HA after media |
| Delivery | Manual guests | Argo CD ← this repo |
| Secrets | Ad hoc | 1Password → Connect → ESO |

**Next:** Phase **2** housekeeping (SSH + **NFS/iSCSI CSI**) → secrets → Argo → Envoy → **transitional `*.lab` proxies** → **Homepage** (first app).

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

Pins: [`.prototools`](.prototools). Install: [docs/setup/local-tools.md](docs/setup/local-tools.md). Cluster CLIs: [`connect/`](connect/README.md) (`moon run connect:sync`).

## Status

Inventory done. Phase 1 storage **done**. Phase **1.5** (VLAN + IaC + scarif move) **done**. **yavin** + **naboo** on Talos `prd` (Cilium + `connect/`). UniFi **ZBF** live. Executing [roadmap](docs/roadmap.md): **CSI → ESO → Argo → apps**.
