# Apps

Workload charts and manifests (media, home, games, network) land here when
added. **Platform** (CNI, CSI, secrets, Argo, cert-manager, Envoy) lives only
under [`clusters/prd/platform/`](../clusters/prd/platform/) — no duplicates.

| Path | Role | Owner |
|------|------|-------|
| `media/`, `home/`, `games/`, `network/` | Workloads (Phase 3+) | Argo when added |
| (future) Tailscale operator, external-dns, ARC | Platform add-ons | `clusters/prd/platform/` |

App-of-apps: `clusters/prd/` (root → `platform/**/application.yaml`).
Bootstrap / DR: [bootstrap](../bootstrap/README.md) and per-component
`clusters/prd/platform/*/install.sh`.
