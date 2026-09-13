# 1Password Connect

In-cluster Connect API for the **Homelab** vault. External Secrets Operator talks to this; the official Operator is **not** installed.

| | |
|--|--|
| Chart | `1password/connect` **2.4.1** (app 1.8.2) |
| Namespace | `onepassword` |
| Service | `http://onepassword-connect.onepassword.svc:8080` |
| Connect server | `prd` (1Password account) |

## Bootstrap secrets (1Password Homelab)

| Item | Type | Use |
|------|------|-----|
| `prd Connect credentials` | Document | `1password-credentials.json` for Helm |
| `prd Connect token` | Password | Connect API token for ESO (`external-secrets` install) |

Created once with `op connect server create` / `op connect token create` — not in Git.

## Install (pre-Argo)

```bash
cd connect/prd   # or: source connect/env.sh
bash apps/system/onepassword-connect/install.sh
```

Requires signed-in `op` CLI. Then install [external-secrets](../external-secrets/).
