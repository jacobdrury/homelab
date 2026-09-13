#!/usr/bin/env bash
# Bootstrap Envoy Gateway (disaster recovery). Prefer Argo after first install.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../_bootstrap.sh
source "${ROOT}/../_bootstrap.sh"
homelab_kubeconfig

CHART_VERSION="${ENVOY_GATEWAY_VERSION:-v1.9.1}"
NS=envoy-gateway-system

if ! kubectl get clusterissuer letsencrypt-prod >/dev/null 2>&1; then
  echo "ClusterIssuer/letsencrypt-prod missing — install cert-manager first" >&2
  exit 1
fi

kubectl create namespace "${NS}" --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install eg oci://docker.io/envoyproxy/gateway-helm \
  --version "${CHART_VERSION}" \
  --namespace "${NS}" \
  --values "${ROOT}/values.yaml" \
  --wait \
  --timeout 10m

kubectl apply -f "${ROOT}/resources.yaml"

echo "waiting for Certificate lab-wildcard-tls Ready"
kubectl -n "${NS}" wait --for=condition=Ready certificate/lab-wildcard-tls --timeout=10m

echo "waiting for Gateway/lab Programmed"
for _ in $(seq 1 60); do
  if kubectl -n "${NS}" get gateway lab -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}' 2>/dev/null | grep -q True; then
    break
  fi
  sleep 3
done
kubectl -n "${NS}" get gateway lab
kubectl -n "${NS}" get svc -l gateway.envoyproxy.io/owning-gateway-name=lab -o wide
kubectl -n "${NS}" get pods
echo "OK — Envoy Gateway ${CHART_VERSION} · VIP 192.168.5.21 · https://argocd.lab.jacobdrury.com"
