# Homelab

GitOps-managed home lab: **Talos** · **Unraid** · **Tailscale** · **Argo CD** · **UniFi VLAN** · agent-operable.

## At a glance

| | Today | Target |
|---|--------|--------|
| Compute | Talos `prd`: **yavin** (CP) + **naboo** (worker on scarif) · Proxmox **homelab02** (leftover guests soaking) | Expand to **3 BM CPs** (hoth/endor); drain naboo |
| Access | Tailscale + **`https://*.lab`** via Envoy `.21` · Homelab via k8s Connector | Same URLs · Drury still via homelab02 until black retires |
| Storage | **scarif** — 24TB UD · **NFS** + **iSCSI** (`scarif-nfs` / `scarif-iscsi`) · naboo on NVMe | Same + optional array/parity |
| pc (black) | Stop Pi-hole LXC after DNS soak (arr / HA / discord-bots already stopped) | **Personal gaming** (Phase 4) |
| Network | Homelab **VLAN 5** + UniFi **ZBF** · DHCP DNS → Pi-hole VIP `.22` | Full lab on VLAN + Tailscale |
| Apps | **Media + HA + Pi-hole on k8s** · Homepage / Authentik / Kuma | Same + Phase 5/6 |
| Delivery | **Argo CD** · `https://argocd.lab.jacobdrury.com` | Same |
| Secrets | **1Password** → Connect → ESO (`ClusterSecretStore/onepassword`) | Same |

**Next:** Stop Pi-hole LXC after DNS soak → Phase **4** expand to 3 CPs / free pc (black).

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

Inventory done. Phase 1 storage **done**. Phase **1.5** **done**. **yavin** + **naboo** on Talos `prd` (Cilium L2 + CSI + Connect/ESO + Argo + Envoy). UniFi **ZBF** live. Media + **Home Assistant** on GitOps; remaining transitional: Pi-hole / scarif / proxmox UI.
