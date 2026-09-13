# Apps

New workloads: add manifests under `apps/` + an Argo `Application` in `clusters/prd/applications/`. Platform chicken-egg pieces still use `install.sh` (Cilium, CSI, Connect, ESO, Argo itself) — see [bootstrap](../bootstrap/README.md).

| Path | Role |
|------|------|
| `system/cilium/` | CNI + kube-proxy replacement |
| `system/nfs-csi/` | RWX media on scarif NFS (`scarif-nfs`) |
| `system/iscsi-csi/` | RWO block on scarif ZFS/iSCSI (`scarif-iscsi`) |
| `system/onepassword-connect/` | 1Password Connect API |
| `system/external-secrets/` | ESO + `ClusterSecretStore/onepassword` |
| `system/argocd/` | Argo CD |
| `system/` (next) | cert-manager, Envoy Gateway, Tailscale operator |
| `media/`, `home/`, `games/`, `network/` | Workloads (Phase 3+) |

App-of-apps: `clusters/prd/` (root → `applications/`).
