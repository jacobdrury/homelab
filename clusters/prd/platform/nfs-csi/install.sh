#!/usr/bin/env bash
# Bootstrap NFS CSI onto prd (pre-Argo). Idempotent helm upgrade --install.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../_bootstrap.sh
source "${ROOT}/../_bootstrap.sh"
homelab_kubeconfig

NFS_CSI_VERSION="${NFS_CSI_VERSION:-4.13.4}"

helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts >/dev/null 2>&1 || true
helm repo update csi-driver-nfs >/dev/null

helm upgrade --install csi-driver-nfs csi-driver-nfs/csi-driver-nfs \
  --version "${NFS_CSI_VERSION}" \
  --namespace kube-system \
  --values "${ROOT}/values.yaml" \
  --wait \
  --timeout 5m

kubectl apply -f "${ROOT}/resources.yaml"

echo "OK — NFS CSI ${NFS_CSI_VERSION}"
kubectl -n kube-system get pods -l app.kubernetes.io/instance=csi-driver-nfs -o wide
kubectl get sc scarif-nfs
