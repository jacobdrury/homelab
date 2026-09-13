# Talos `prd` — **yavin** (CP) + **naboo** (worker)

Control plane on Mac Mini; interim worker VM on scarif. CNI/kube-proxy disabled for **Cilium**. Talos **v1.12.7** (Mac Mini Apple EFI — do not use 1.13+ on yavin yet).

## Layout

| Path | Commit? | Role |
|------|---------|------|
| `schematic.yaml` / `schematic.id` | yes | Image Factory extensions (`intel-ucode`, `i915`, `realtek-firmware`, `iscsi-tools`) |
| `patches/` | yes | Cluster + yavin (CP) + naboo (worker) — no secrets |
| `gen.sh` | yes | Regenerate `generated/` from secrets + patches |
| `secrets.yaml` | **no** | Cluster PKI — generate once; store a copy in 1Password |
| `generated/` | **no** | `controlplane.yaml` + `worker.yaml` + `talosconfig` |

## One-time secrets

```bash
cd infrastructure/talos/prd
talosctl gen secrets -o secrets.yaml   # already done if file exists
# Save secrets.yaml to 1Password Homelab vault (cluster join needs this later)
./gen.sh
```

Installer image:

`factory.talos.dev/metal-installer/b61bec70ff5223641d986c88a927920b3f8676cacd22a9bf50522f13a8775eb6:v1.12.7`

Previous (no iSCSI): `611c46fd514a0cbc412c3945e3a9b1c8ff49f3408a9ada6c170e936ad97cbe6d`

## Apply (wipes `nvme0n1` / Proxmox)

Mini must be in **maintenance** on Homelab (`192.168.5.x` on USB NIC). Then:

```bash
cd infrastructure/talos/prd
./gen.sh                          # endpoint defaults to 192.168.5.128
# or: TALOS_ENDPOINT=192.168.5.128 ./gen.sh

talosctl apply-config --insecure \
  -n 192.168.5.128 \
  -f generated/controlplane.yaml
```

Node installs, reboots to `192.168.5.11`. Then:

```bash
talosctl --talosconfig generated/talosconfig config endpoint 192.168.5.11
talosctl --talosconfig generated/talosconfig bootstrap -n 192.168.5.11
# Client configs for daily use (repo root):
moon run connect:sync
cd connect/prd && direnv allow   # or: source connect/env.sh
kubectl get nodes
```

DNS `k8s.lab.jacobdrury.com` / `yavin.lab.jacobdrury.com` → `192.168.5.11` is already in `infrastructure/dns/` via `lab.yaml`.

## Join **naboo** (Unraid VM on scarif) — **done** Sep 2026

Worker is **Ready** on `prd` at `192.168.5.14` (6 vCPU / 20 GB; disk on scarif NVMe). Re-join / rebuild notes:

1. Unraid: bridge Homelab NIC (`br0`); VM `naboo` — VirtIO disk on `/mnt/disks/naboo-ssd`, VirtIO NIC on `br0`.
2. Boot factory ISO (`metal-amd64.iso` for schematic + **v1.12.7**) into maintenance mode. Use **talosctl 1.12.7** (pin in `.prototools`) — newer clients emit docs 1.12 nodes reject.
3. From repo:

```bash
cd infrastructure/talos/prd
./gen.sh
talosctl apply-config --insecure \
  -n <naboo-maintenance-ip> \
  -f generated/worker.yaml
```

4. After reboot → `192.168.5.14`; eject ISO; `kubectl get nodes` shows **naboo** Ready (ROLE `<none>` is normal for workers).

DNS `naboo.lab.jacobdrury.com` → `192.168.5.14` is in `lab.yaml` / Cloudflare.

## Networking (yavin)

| NIC | MAC | Switch | Address |
|-----|-----|--------|---------|
| USB 2.5G `enp8s0u2` | `6c:1f:f7:21:c6:16` | Pro Max **Port 13** | static `192.168.5.11/24` (primary, metric 100) |
| Onboard 1G `enp4s0` | `68:fe:f7:10:39:b9` | Pro Max **Port 5** | static `192.168.5.111/24` (fallback, metric 200) |

Both on Homelab VLAN 5. Kubelet `nodeIP.validSubnets` is `192.168.5.11/32` so NodeInternalIP stays on the USB address.
