# Bootstrap Argo CD onto prd, then apply app-of-apps root. Idempotent.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
CHART_VERSION="${ARGOCD_CHART_VERSION:-10.9.0}"
ROOT_REPO="$(cd "${ROOT}/../../.." && pwd)"
KUBECONFIG="${KUBECONFIG:-${ROOT_REPO}/connect/prd/kubeconfig}"
export KUBECONFIG
NS=argocd

if [[ ! -f "${KUBECONFIG}" ]]; then
  echo "missing ${KUBECONFIG} — run: moon run connect:sync" >&2
  exit 1
fi

helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
helm repo update argo >/dev/null

kubectl create namespace "${NS}" --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install argocd argo/argo-cd \
  --version "${CHART_VERSION}" \
  --namespace "${NS}" \
  --values "${ROOT}/values.yaml" \
  --wait \
  --timeout 10m

# App-of-apps root (watches clusters/prd/applications once that lands on main)
kubectl apply -f "${ROOT_REPO}/clusters/prd/root.yaml"

kubectl -n "${NS}" get pods -o wide
echo
echo "OK — Argo CD ${CHART_VERSION}"
echo "UI (until Envoy):  kubectl -n argocd port-forward svc/argocd-server 8080:80"
echo "User: admin"
echo "Pass: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo"
echo
echo "GitOps sync needs clusters/prd on origin/main (commit + push if not yet)."
