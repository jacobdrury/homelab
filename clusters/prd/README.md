# Argo CD app-of-apps — prd

What Argo on **prd** syncs. Contract: merge to `main` → Applications here reconcile.

`root.yaml` discovers `platform/*/application.yaml` and `apps/*/application.yaml`.
Each component keeps values and supporting manifests in that same directory.

Install Argo once: `bash clusters/prd/platform/argocd/install.sh` (applies `root.yaml`).
