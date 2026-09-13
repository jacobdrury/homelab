# Homelab agent instructions

## Homelab naming

Physical hosts and Talos/k8s **node names** use **Star Wars planets** (lowercase, no spaces).

| Codename | Machine | Role |
|----------|---------|------|
| **scarif** | pc (white) | Unraid NAS — **use this name now** |
| **yavin** | Mac Mini | Talos CP #1 (bare metal; expand to 3) |
| **naboo** | VM on scarif | Talos **worker** (interim until hoth/endor) |
| **hoth** | Mini PC #1 | Talos CP #2 |
| **endor** | Mini PC #2 | Talos CP #3 |

- App URLs stay `*.lab.jacobdrury.com` — not planet-themed.
- pc (black) is leaving the lab; no planet name.
- Full map and migration notes: `docs/architecture/naming.md`

## Cluster CLI access

Use in-repo **`connect/<cluster>/`** — not `~/.kube/homelab-prd.yaml`.

**Preferred:** `cd connect/prd` (direnv sets `KUBECONFIG` / `TALOSCONFIG`). For staging later: `cd connect/stg`.

```bash
moon run connect:sync              # refresh prd (default)
CONNECT_CLUSTER=stg moon run connect:sync

cd connect/prd                     # direnv allow once per clone
kubectl get nodes
k9s

# without direnv / from another cwd:
source connect/env.sh              # default prd
```

| Cluster | Dir |
|---------|-----|
| prd | `connect/prd/` |
| stg | `connect/stg/` (future) |

Details: `connect/README.md`

## GitOps / bootstrap

**Leave `install.sh` only for what must be installed before Argo exists** (CNI, CSI, Connect/`op` seeding, ESO, Argo + root). Anything Argo can own entirely from Git must never get an install script. Details: `docs/architecture/agents.md` (§ Bootstrap scripts).

