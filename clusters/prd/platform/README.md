# Platform (prd) — GitOps + bootstrap

Single tree for cluster platform components. Argo owns them via
`application.yaml`; `install.sh` is for first install and disaster recovery only.

| Component | Dir | Bootstrap |
|-----------|-----|-----------|
| Cilium (+ L2 LB) | `cilium/` | `./cilium/install.sh` |
| NFS CSI | `nfs-csi/` | `./nfs-csi/install.sh` |
| iSCSI CSI | `iscsi-csi/` | `./iscsi-csi/install.sh` |
| 1Password Connect | `onepassword-connect/` | `./onepassword-connect/install.sh` |
| External Secrets | `external-secrets/` | `./external-secrets/install.sh` |
| Argo CD | `argocd/` | `./argocd/install.sh` (also applies `../root.yaml`) |
| cert-manager | `cert-manager/` | `./cert-manager/install.sh` |
| Envoy Gateway | `envoy-gateway/` | `./envoy-gateway/install.sh` |

Each directory holds co-located `values.yaml`, optional `resources.yaml`, and the
Argo `application.yaml`. Chart versions are pinned in `application.yaml` and
mirrored as defaults in `install.sh`.

Suggested DR order matches the table top → bottom (CNI → storage → secrets →
Argo → TLS → gateway).
