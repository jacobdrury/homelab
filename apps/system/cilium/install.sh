#!/usr/bin/env bash
# Bootstrap Cilium onto prd (pre-Argo). Idempotent helm upgrade --install.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
CILIUM_VERSION="${CILIUM_VERSION:-1.19.7}"
ROOT_REPO="$(cd "${ROOT}/../../.." && pwd)"
KUBECONFIG="${KUBECONFIG:-${ROOT_REPO}/connect/prd/kubeconfig}"
export KUBECONFIG
if [[ ! -f "${KUBECONFIG}" ]]; then
  echo "missing ${KUBECONFIG} — run: moon run connect:sync" >&2
  exit 1
fi

helm repo add cilium https://helm.cilium.io >/dev/null 2>&1 || true
helm repo update cilium >/dev/null

helm upgrade --install cilium cilium/cilium \
  --version "${CILIUM_VERSION}" \
  --namespace kube-system \
  --values "${ROOT}/values.yaml" \
  --wait \
  --timeout 10m

echo "OK — Cilium ${CILIUM_VERSION}"
kubectl -n kube-system get pods -l app.kubernetes.io/part-of=cilium -o wide
kubectl get nodes -o wide
