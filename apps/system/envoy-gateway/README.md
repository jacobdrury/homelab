# Envoy Gateway

Homelab ingress: VIP **`192.168.5.21`** (Cilium L2), TLS via wildcard **`*.lab.jacobdrury.com`**.

| | |
|--|--|
| Chart | `oci://docker.io/envoyproxy/gateway-helm` **v1.9.1** |
| Namespace | `envoy-gateway-system` |
| Gateway | `Gateway/lab` |
| First route | `https://argocd.lab.jacobdrury.com` → `argocd-server:80` |

## Prerequisites

1. Cilium L2 + IP pool — `bash apps/system/cilium/install.sh`
2. cert-manager + `letsencrypt-prod` — `bash apps/system/cert-manager/install.sh`
3. DNS: `argocd.lab` → `192.168.5.21` (`infrastructure/lab.yaml` + `moon run dns:apply`)

## Install

```bash
cd connect/prd
bash apps/system/envoy-gateway/install.sh
```

## Add a route

HTTPRoute in the app namespace, `parentRefs` → `lab` in `envoy-gateway-system`, hostname under `*.lab.jacobdrury.com`.
