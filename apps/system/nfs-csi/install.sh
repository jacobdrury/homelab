# Bootstrap NFS CSI onto prd (pre-Argo). Idempotent helm upgrade --install.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
NFS_CSI_VERSION="${NFS_CSI_VERSION:-4.13.4}"
ROOT_REPO="$(cd "${ROOT}/../../.." && pwd)"
KUBECONFIG="${KUBECONFIG:-${ROOT_REPO}/connect/prd/kubeconfig}"
export KUBECONFIG
if [[ ! -f "${KUBECONFIG}" ]]; then
  echo "missing ${KUBECONFIG} — run: moon run connect:sync" >&2
  exit 1
fi

helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts >/dev/null 2>&1 || true
helm repo update csi-driver-nfs >/dev/null

helm upgrade --install csi-driver-nfs csi-driver-nfs/csi-driver-nfs \
  --version "${NFS_CSI_VERSION}" \
  --namespace kube-system \
  --values "${ROOT}/values.yaml" \
  --wait \
  --timeout 5m

kubectl apply -f "${ROOT}/storageclass.yaml"

echo "OK — NFS CSI ${NFS_CSI_VERSION}"
kubectl -n kube-system get pods -l app.kubernetes.io/instance=csi-driver-nfs -o wide
kubectl get sc scarif-nfs
