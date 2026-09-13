# External Secrets Operator → 1Password Connect

| | |
|--|--|
| Chart | `external-secrets/external-secrets` **2.10.0** |
| Namespace | `external-secrets` |
| Store | `ClusterSecretStore/onepassword` |
| Vault | Homelab |

Depends on [onepassword-connect](../onepassword-connect/).

## Install (pre-Argo)

```bash
cd connect/prd
bash apps/system/onepassword-connect/install.sh
bash apps/system/external-secrets/install.sh
```

Seeds Secret `onepassword-connect-token` from Homelab item **`prd Connect token`**.

## Smoke test

```bash
# one-time Homelab item (if missing):
# op item create --category=Password --title='ESO smoke test' --vault Homelab password='eso-smoke-ok'

kubectl apply -f apps/system/external-secrets/smoke-test.yaml
kubectl -n eso-smoke wait --for=condition=Ready externalsecret/eso-smoke --timeout=120s
kubectl -n eso-smoke get secret eso-smoke -o jsonpath='{.data.password}' | base64 -d; echo
kubectl delete -f apps/system/external-secrets/smoke-test.yaml
```
