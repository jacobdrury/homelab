# cert-manager

Issues **`*.lab.jacobdrury.com`** via Let’s Encrypt **DNS-01** (Cloudflare). Token from Homelab item **Cloudflare Zone DNS API Token** via ESO.

| | |
|--|--|
| Chart | `jetstack/cert-manager` **v1.21.2** |
| Namespace | `cert-manager` |
| Issuer | `ClusterIssuer/letsencrypt-prod` |

## Install

```bash
cd connect/prd
bash apps/system/cert-manager/install.sh
```

Requires `ClusterSecretStore/onepassword`. Then install [envoy-gateway](../envoy-gateway/).
