# Apps

GitOps: Argo Applications in [`clusters/prd/applications/`](../clusters/prd/applications/). Chicken-egg pieces stay on `install.sh` — [bootstrap](../bootstrap/README.md).

| Path | Role | Owner |
|------|------|-------|
| `system/cilium/` | CNI + L2 LB VIP `.21` | `install.sh` |
| `system/nfs-csi/` | `scarif-nfs` | Argo `nfs-csi` |
| `system/iscsi-csi/` | `scarif-iscsi` | `install.sh` (SSH key) |
| `system/onepassword-connect/` | Connect API | Argo (+ seeded Secret) |
| `system/external-secrets/` | ESO + `ClusterSecretStore/onepassword` | Argo (+ seeded token) |
| `system/argocd/` | Argo CD | `install.sh` |
| `system/cert-manager/` | LE DNS-01 | Argo |
| `system/envoy-gateway/` | Gateway VIP `.21` · `*.lab` TLS | `install.sh` |
| `system/` (next) | Tailscale operator | — |
| `media/`, `home/`, `games/`, `network/` | Workloads (Phase 3+) | Argo when added |

App-of-apps: `clusters/prd/` (root → `applications/`).
