# Bootstrap (one-time)

Chicken-and-egg installs before GitOps can own them.

| Step | Path |
|------|------|
| Cilium | `apps/system/cilium/install.sh` |
| NFS / iSCSI CSI | `apps/system/nfs-csi/`, `iscsi-csi/` |
| 1Password Connect + ESO | `apps/system/onepassword-connect/`, `external-secrets/` |
| **Argo CD** | `apps/system/argocd/install.sh` → applies `clusters/prd/root.yaml` |

After Argo is up, new workloads go in `apps/` + an `Application` under `clusters/prd/applications/`. Platform charts above can stay out of Argo until you choose to adopt them.
