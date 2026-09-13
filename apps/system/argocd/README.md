# Argo CD

GitOps controller for `prd`. Root Application watches `clusters/prd/applications/`.

| | |
|--|--|
| Chart | `argo/argo-cd` **10.9.0** (app v3.5.2) |
| Namespace | `argocd` |
| UI (later) | `https://argocd.lab.jacobdrury.com` (Envoy) |
| Repo | `https://github.com/jacobdrury/homelab.git` (public) |

## Install (pre-GitOps chicken-egg)

```bash
cd connect/prd
bash apps/system/argocd/install.sh
```

## UI (until Envoy)

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:80
# https://localhost:8080  (or http — server.insecure)
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
```

## Adding apps

1. Manifests under `apps/<category>/<name>/`
2. `Application` YAML under `clusters/prd/applications/`
3. Merge to `main` → root app syncs the new Application → Argo syncs the workload

Already-bootstrapped platform (Cilium, CSI, Connect, ESO) stays Helm/`install.sh` until optionally adopted later.
