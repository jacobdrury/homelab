# Argo CD app-of-apps — prd

What Argo on **prd** syncs. Contract: merge to `main` → Applications here reconcile.

`root.yaml` recursively discovers only `platform/**/application.yaml`. Each component
keeps its environment values and supporting manifests in that same directory; the
flat `applications/` tree has been retired.

Install Argo once: `bash apps/system/argocd/install.sh` (applies `root.yaml`).
