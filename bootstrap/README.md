# Bootstrap (one-time)

Chicken-and-egg installs before GitOps can own them. After first install, **Argo**
owns all platform charts via `clusters/prd/platform/`.

| Step | Path | Argo? |
|------|------|-------|
| Cilium (+ L2 LB) | `apps/system/cilium/` | **Yes** |
| NFS CSI | `apps/system/nfs-csi/` | **Yes** — `nfs-csi` |
| iSCSI CSI | `apps/system/iscsi-csi/` | **Yes** — SSH config Secret via ESO |
| 1Password Connect | `apps/system/onepassword-connect/` | **Yes** — Secret `op-credentials` seeded once |
| ESO | `apps/system/external-secrets/` | **Yes** — token Secret seeded once |
| **Argo CD** | `apps/system/argocd/install.sh` | **Yes** — self-managed after bootstrap |
| cert-manager | `apps/system/cert-manager/` | **Yes** |
| Envoy Gateway | `apps/system/envoy-gateway/` | **Yes** — local chart wrapper |

Bootstrap Secrets (never commit): `op-credentials`, `onepassword-connect-token` — annotated `Prune=false`. Re-seed with the app `install.sh` if lost.

The scripts remain for initial bootstrap and disaster recovery. New workloads live
in `apps/` and get an `Application` under `clusters/prd/apps/`.
