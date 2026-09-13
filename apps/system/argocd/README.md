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

## UI

```bash
open https://argocd.lab.jacobdrury.com
# admin password:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
```

(Port-forward still works as break-glass: `kubectl -n argocd port-forward svc/argocd-server 8080:80`.)

## Adding apps

1. Manifests under `apps/<category>/<name>/`
2. `Application` YAML under `clusters/prd/applications/`
3. Merge to `main` → root app syncs the new Application → Argo syncs the workload

**Argo-managed platform today:** Connect, ESO, cert-manager, NFS CSI.  
**Still bootstrap `install.sh`:** Cilium, Argo itself, iSCSI CSI, Envoy Gateway.
