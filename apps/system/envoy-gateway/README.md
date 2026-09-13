# Envoy Gateway

Homelab ingress: VIP **`192.168.5.21`** (Cilium L2), TLS via wildcard **`*.lab.jacobdrury.com`**.

| | |
|--|--|
| Chart | `docker.io/envoyproxy` / `gateway-helm` **v1.9.1** ([Argo install](https://gateway.envoyproxy.io/docs/install/install-argocd/)) |
| Namespace | `envoy-gateway-system` |
| GitOps | `clusters/prd/platform/envoy-gateway/` |
| Gateway | `Gateway/lab` |
| First route | `https://argocd.lab.jacobdrury.com` → `argocd-server:80` |

## Bootstrap (disaster recovery)

Prefer Argo. If chicken-egg:

```bash
cd connect/prd
bash apps/system/envoy-gateway/install.sh
```

## Add a route

HTTPRoute in the app namespace, `parentRefs` → `lab` in `envoy-gateway-system`, hostname under `*.lab.jacobdrury.com`. Commit under the app or `clusters/prd/platform/envoy-gateway/resources.yaml` as appropriate.
