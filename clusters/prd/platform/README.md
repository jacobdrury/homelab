# Platform (prd) — GitOps + bootstrap

Single tree for cluster platform components. **Argo owns them** via
`application.yaml` once the app-of-apps root is applied.

`install.sh` is **only** for fresh-cluster / total-DR steps that must run
**before Argo can take over** (CNI, secret seeding with `op`, Argo itself).
Not a day-to-day deploy path — see
[agents — bootstrap vs Argo](../../../docs/architecture/agents.md#bootstrap-scripts-installsh-vs-argo).

| Component | Dir | `install.sh`? |
|-----------|-----|---------------|
| Cilium (+ L2 LB) | `cilium/` | Yes — CNI |
| NFS CSI | `nfs-csi/` | Yes — optional before first PVCs |
| iSCSI CSI | `iscsi-csi/` | Yes — seeds driver Secret from `op` |
| 1Password Connect | `onepassword-connect/` | Yes — seeds credentials from `op` |
| External Secrets | `external-secrets/` | Yes — needs Connect token |
| Argo CD | `argocd/` | Yes — installs Argo + applies `../root.yaml` (**handoff**) |
| cert-manager | `cert-manager/` | No — Git / Argo only |
| Envoy Gateway | `envoy-gateway/` | No — Git / Argo only |
| CloudNativePG | `cloudnative-pg/` | No — Git / Argo only; `Cluster` CRs with apps |

Each directory: `application.yaml` + `values.yaml` / optional `resources.yaml`.
Chart versions are pinned in `application.yaml` (and mirrored in remaining
bootstrap scripts).

**Handoff:** after `./argocd/install.sh`, merge to `main`; Argo reconciles
`clusters/prd/**/application.yaml` (platform + apps).

Fresh-cluster order: CNI → storage (if needed) → Connect → ESO → Argo → Git.
