# Argo CD app-of-apps — prd

What Argo on **prd** syncs. Contract: merge to `main` → Applications here reconcile.

| Path | Role |
|------|------|
| `root.yaml` | Bootstrap Application → `clusters/prd/applications` |
| `applications/` | Child `Application` manifests (add one per workload) |

Repo: `https://github.com/jacobdrury/homelab.git` · revision `main`.

Install Argo once: `bash apps/system/argocd/install.sh` (applies `root.yaml`).
