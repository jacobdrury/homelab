# Homelab

GitOps-managed home lab: **Talos** · **Unraid** · **Tailscale** · **Argo CD** · **UniFi VLAN** · agent-operable.

## At a glance

| | Today | Target |
|---|--------|--------|
| Compute | Talos `prd`: **yavin** (CP) + **naboo** (worker on scarif) · Proxmox **homelab02** (HA / Pi-hole / bots) | Expand to **3 BM CPs** (hoth/endor); drain naboo |
| Access | Tailscale + **`https://*.lab`** via Envoy `.21` | Same URLs · k8s Connector replaces homelab02 for Homelab |
| Storage | **scarif** — 24TB UD · **NFS** + **iSCSI** (`scarif-nfs` / `scarif-iscsi`) · naboo on NVMe | Same + optional array/parity |
| pc (black) | Pi-hole + discord-bots · **arr + HA VMs stop when retired** | **Personal gaming** (after Pi-hole cutover) |
| Network | Homelab **VLAN 5** + UniFi **ZBF** · Drury (Pi-hole, Proxmox) | Full lab on VLAN + Tailscale |
| Apps | **Media + Home Assistant on k8s** · Homepage / Authentik / Kuma · Pi-hole still transitional | Pi-hole on k8s |
| Delivery | **Argo CD** · `https://argocd.lab.jacobdrury.com` | Same |
| Secrets | **1Password** → Connect → ESO (`ClusterSecretStore/onepassword`) | Same |

**Next:** Phase **3** — optional Discord bots → **Pi-hole last**.

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
