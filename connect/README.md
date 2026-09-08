# Cluster CLI access

Per-cluster dirs hold **kubeconfig** + **talosconfig** (gitignored — repo is public). **direnv** loads env when you `cd` into a cluster directory.

## Layout

```text
connect/
  env.sh          # scripts/agents without direnv (CONNECT_CLUSTER=…)
  sync.sh         # fetch configs from Talos
  check.sh
  moon.yml
  prd/            # production (yavin)
    .envrc        # committed — sets KUBECONFIG/TALOSCONFIG
    kubeconfig    # gitignored
    talosconfig   # gitignored
  stg/            # staging (future) — same shape
```

## One-time setup

```bash
proto install                 # kubectl, talosctl, k9s via .prototools
brew install direnv
echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc   # once

moon run connect:sync         # default CONNECT_CLUSTER=prd
cd connect/prd
direnv allow                  # once per cluster dir
kubectl get nodes
```

## Daily use

| Goal | Command |
|------|---------|
| Use **prd** | `cd connect/prd` → kubectl / talosctl / k9s |
| Use **stg** (later) | `cd connect/stg` after `CONNECT_CLUSTER=stg moon run connect:sync` |
| Leave cluster | `cd` elsewhere → direnv unloads |
| Refresh configs | `moon run connect:sync` (or `CONNECT_CLUSTER=stg …`) |
| Verify | `moon run connect:check` |
| k9s via moon | `moon run connect:k9s` (uses `CONNECT_CLUSTER`, default `prd`) |

Moon/tasks don’t require you to be in the cluster dir — they load via `connect/env.sh`.

## Agents

Prefer working in `connect/prd` (or export via `source connect/env.sh`). Do not use `~/.kube/homelab-prd.yaml`.

```bash
cd connect/prd    # direnv, if allowed
# or from anywhere:
source connect/env.sh
```

## Endpoints (prd)

| Tool | Target |
|------|--------|
| kubectl | `https://k8s.lab.jacobdrury.com:6443` |
| talosctl | `192.168.5.11` (USB); sync falls back to `192.168.5.111` |

Override: `TALOS_NODE=… TALOS_NODE_FALLBACK=… moon run connect:sync`.

Talos machine secrets stay under `infrastructure/talos/<cluster>/` (also gitignored). This tree is **client** configs only.
