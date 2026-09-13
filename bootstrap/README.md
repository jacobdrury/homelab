# Bootstrap (one-time / DR)

Chicken-and-egg installs before GitOps can own them. After first install, **Argo**
owns all platform charts via [`clusters/prd/platform/`](../clusters/prd/platform/).

| Step | Path |
|------|------|
| Cilium (+ L2 LB) | `clusters/prd/platform/cilium/install.sh` |
| NFS CSI | `clusters/prd/platform/nfs-csi/install.sh` |
| iSCSI CSI | `clusters/prd/platform/iscsi-csi/install.sh` |
| 1Password Connect | `clusters/prd/platform/onepassword-connect/install.sh` |
| ESO | `clusters/prd/platform/external-secrets/install.sh` |
| Argo CD | `clusters/prd/platform/argocd/install.sh` |
| cert-manager | `clusters/prd/platform/cert-manager/install.sh` |
| Envoy Gateway | `clusters/prd/platform/envoy-gateway/install.sh` |

Bootstrap Secrets (never commit): `op-credentials`, `onepassword-connect-token`,
and (until ESO owns it) the iSCSI driver-config Secret — scripts annotate
`Prune=false`. Re-run the matching `install.sh` if lost.

New workloads live under `apps/` and get an `Application` under
`clusters/prd/apps/` when that tree is used.
