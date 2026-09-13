#!/usr/bin/env bash
# Bootstrap External Secrets Operator + ClusterSecretStore (1Password Connect).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../_bootstrap.sh
source "${ROOT}/../_bootstrap.sh"
homelab_kubeconfig

CHART_VERSION="${ESO_CHART_VERSION:-2.10.0}"
NS=external-secrets
TOKEN_TMP="$(mktemp)"
trap 'rm -f "${TOKEN_TMP}"' EXIT

if ! command -v op >/dev/null 2>&1; then
  echo "op CLI required to fetch Connect token" >&2
  exit 1
fi
if ! kubectl -n onepassword get svc onepassword-connect >/dev/null 2>&1; then
  echo "1Password Connect not found — run clusters/prd/platform/onepassword-connect/install.sh first" >&2
  exit 1
fi

echo "fetching Connect token from Homelab (prd Connect token)"
op item get 'prd Connect token' --vault Homelab --reveal --fields password \
  | tr -d '\r\n' | sed 's/^"//;s/"$//' > "${TOKEN_TMP}"
if [[ ! -s "${TOKEN_TMP}" ]]; then
  echo "empty Connect token from 1Password" >&2
  exit 1
fi

helm repo add external-secrets https://charts.external-secrets.io >/dev/null 2>&1 || true
helm repo update external-secrets >/dev/null

kubectl create namespace "${NS}" --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install external-secrets external-secrets/external-secrets \
  --version "${CHART_VERSION}" \
  --namespace "${NS}" \
  --values "${ROOT}/values.yaml" \
  --wait \
  --timeout 5m

kubectl -n "${NS}" create secret generic onepassword-connect-token \
  --from-file=token="${TOKEN_TMP}" \
  --dry-run=client -o yaml | kubectl apply -f -
homelab_protect_secret "${NS}" onepassword-connect-token

kubectl apply -f "${ROOT}/resources.yaml"

echo "waiting for ClusterSecretStore/onepassword Ready"
for _ in $(seq 1 30); do
  if kubectl get clustersecretstore onepassword -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | grep -q True; then
    break
  fi
  sleep 2
done
kubectl get clustersecretstore onepassword

kubectl -n "${NS}" get pods -o wide
echo "OK — External Secrets ${CHART_VERSION} + ClusterSecretStore/onepassword"
echo "Smoke: ensure Homelab item 'ESO smoke test' exists, then:"
echo "  kubectl apply -f ${ROOT}/smoke-test.yaml"
echo "  kubectl -n eso-smoke get externalsecret,secret"
