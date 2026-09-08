# Talos

Machine configs and Image Factory schematics per cluster env.

| Path | Cluster |
|------|---------|
| [`prd/`](prd/) | Production — bootstrap on **yavin** |
| `stg/` | Reserved |

Kubernetes app manifests stay under `clusters/<env>/` (Argo); this tree is the **node OS** side only.
