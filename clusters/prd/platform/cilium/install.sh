#!/usr/bin/env bash
# Bootstrap Cilium onto prd (pre-Argo). Idempotent helm upgrade --install.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../_bootstrap.sh
source "${ROOT}/../_bootstrap.sh"
homelab_kubeconfig

CILIUM_VERSION="${CILIUM_VERSION:-1.19.7}"

helm repo add cilium https://helm.cilium.io >/dev/null 2>&1 || true
helm repo update cilium >/dev/null

helm upgrade --install cilium cilium/cilium \
  --version "${CILIUM_VERSION}" \
  --namespace kube-system \
  --values "${ROOT}/values.yaml" \
  --wait \
  --timeout 10m

kubectl apply -f "${ROOT}/resources.yaml"

echo "OK — Cilium ${CILIUM_VERSION} (L2 LB pool 192.168.5.21)"
kubectl -n kube-system get pods -l app.kubernetes.io/part-of=cilium -o wide
kubectl get ciliumloadbalancerippool,ciliuml2announcementpolicy
kubectl get nodes -o wide
