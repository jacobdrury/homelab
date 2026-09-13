# Argo CD app-of-apps — prd

What Argo on **prd** syncs. Contract: merge to `main` → Applications here reconcile.

`root` is **self-managed**: it syncs `clusters/prd/root.yaml` plus nested apps under
`platform/*/application.yaml` and `apps/*/application.yaml`. Edit `root.yaml` in
Git; no further `kubectl apply` after the first bootstrap.

Bootstrap once: `bash clusters/prd/platform/argocd/install.sh` (applies `root.yaml`).
