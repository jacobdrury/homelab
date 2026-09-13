# Argo CD app-of-apps — prd

What Argo on **prd** syncs. Contract: merge to `main` → Applications here reconcile.

| Application | Chart / path |
|-------------|--------------|
| `root` | This directory (app-of-apps) |
| `onepassword-connect` | Connect 2.4.1 |
| `external-secrets` | ESO 2.10.0 + ClusterSecretStore |
| `cert-manager` | cert-manager v1.21.2 + issuer |
| `nfs-csi` | csi-driver-nfs 4.13.4 + StorageClass |

**Not in Argo yet:** Cilium, Argo CD itself, iSCSI CSI, **Envoy Gateway** (Helm + Gateway YAMLs via `install.sh` — Argo prune/finalizer risk; OCI chart pull broken).


Install Argo once: `bash apps/system/argocd/install.sh` (applies `root.yaml`).
