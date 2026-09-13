#!/usr/bin/env bash
# Bootstrap cert-manager + Cloudflare DNS-01 ClusterIssuer. Idempotent.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../_bootstrap.sh
source "${ROOT}/../_bootstrap.sh"
homelab_kubeconfig

CHART_VERSION="${CERT_MANAGER_VERSION:-v1.21.2}"
NS=cert-manager

if ! kubectl get clustersecretstore onepassword >/dev/null 2>&1; then
  echo "ClusterSecretStore/onepassword missing — install ESO first" >&2
  exit 1
fi

helm repo add jetstack https://charts.jetstack.io >/dev/null 2>&1 || true
helm repo update jetstack >/dev/null

kubectl create namespace "${NS}" --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install cert-manager jetstack/cert-manager \
  --version "${CHART_VERSION}" \
  --namespace "${NS}" \
  --values "${ROOT}/values.yaml" \
  --wait \
  --timeout 5m

kubectl apply -f "${ROOT}/resources.yaml"
echo "waiting for Secret cloudflare-api-token"
kubectl -n "${NS}" wait --for=condition=Ready externalsecret/cloudflare-api-token --timeout=120s

echo "waiting for ClusterIssuer letsencrypt-prod Ready"
for _ in $(seq 1 30); do
  if kubectl get clusterissuer letsencrypt-prod -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | grep -q True; then
    break
  fi
  sleep 2
done
kubectl get clusterissuer letsencrypt-prod

kubectl -n "${NS}" get pods
echo "OK — cert-manager ${CHART_VERSION} + ClusterIssuer/letsencrypt-prod"
