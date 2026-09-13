# Bootstrap (one-time / DR)

Chicken-and-egg installs **before Argo can take over**. After
`argocd/install.sh` applies the app-of-apps root, **stop** — everything else
comes from Git via Argo. Policy: [agents — bootstrap vs Argo](../docs/architecture/agents.md#bootstrap-scripts-installsh-vs-argo).

| Step | Path |
|------|------|
| Cilium (+ L2 LB) | `clusters/prd/platform/cilium/install.sh` |
| NFS CSI | `clusters/prd/platform/nfs-csi/install.sh` |
| iSCSI CSI | `clusters/prd/platform/iscsi-csi/install.sh` |
| 1Password Connect | `clusters/prd/platform/onepassword-connect/install.sh` |
| ESO | `clusters/prd/platform/external-secrets/install.sh` |
| Argo CD (+ `root.yaml`) | `clusters/prd/platform/argocd/install.sh` |

Do **not** add bootstrap scripts for cert-manager, Envoy, CNPG, or apps — those
are `application.yaml` only under [`clusters/prd/`](../clusters/prd/).

Bootstrap Secrets (never commit): `op-credentials`, `onepassword-connect-token`,
and (until ESO owns it) the iSCSI driver-config Secret — scripts annotate
`Prune=false`. Re-run the matching `install.sh` if lost.
