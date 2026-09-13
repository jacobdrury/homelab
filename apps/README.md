# Apps

GitOps: Argo Applications and environment-specific values live in
[`clusters/prd/platform/`](../clusters/prd/platform/). `install.sh` remains for
bootstrap and disaster recovery — [bootstrap](../bootstrap/README.md).

| Path | Role | Owner |
|------|------|-------|
| `system/cilium/` | CNI + L2 LB VIP `.21` | Argo |
| `system/nfs-csi/` | `scarif-nfs` | Argo `nfs-csi` |
| `system/iscsi-csi/` | `scarif-iscsi` | Argo (ESO SSH config) |
| `system/onepassword-connect/` | Connect API | Argo (+ seeded Secret) |
| `system/external-secrets/` | ESO + `ClusterSecretStore/onepassword` | Argo (+ seeded token) |
| `system/argocd/` | Argo CD | Argo self-managed |
| `system/cert-manager/` | LE DNS-01 | Argo |
| `system/envoy-gateway/` | Gateway VIP `.21` · `*.lab` TLS | Argo |
| `system/` (next) | Tailscale operator | — |
| `media/`, `home/`, `games/`, `network/` | Workloads (Phase 3+) | Argo when added |

App-of-apps: `clusters/prd/` (root → `platform/**/application.yaml`).
