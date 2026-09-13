# Bootstrap (one-time)

Chicken-and-egg installs before GitOps can own them. After first install, **Argo** owns most charts via `clusters/prd/applications/`.

| Step | Path | Argo? |
|------|------|-------|
| Cilium (+ L2 LB) | `apps/system/cilium/` | **No** — leave Helm/`install.sh` |
| NFS CSI | `apps/system/nfs-csi/` | **Yes** — `nfs-csi` |
| iSCSI CSI | `apps/system/iscsi-csi/` | **Not yet** — SSH key still bootstrap |
| 1Password Connect | `apps/system/onepassword-connect/` | **Yes** — Secret `op-credentials` seeded once |
| ESO | `apps/system/external-secrets/` | **Yes** — token Secret seeded once |
| **Argo CD** | `apps/system/argocd/install.sh` | **No** — chicken-egg |
| cert-manager | `apps/system/cert-manager/` | **Yes** |
| Envoy Gateway | `apps/system/envoy-gateway/` | **Yes** |

Bootstrap Secrets (never commit): `op-credentials`, `onepassword-connect-token` — annotated `Prune=false`. Re-seed with the app `install.sh` if lost.

New workloads: `apps/` + `Application` under `clusters/prd/applications/`.
