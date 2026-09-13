# Bootstrap 1Password Connect onto prd. Idempotent.
# Credentials come from Homelab vault document "prd Connect credentials" (never committed).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
CHART_VERSION="${OP_CONNECT_CHART_VERSION:-2.4.1}"
ROOT_REPO="$(cd "${ROOT}/../../.." && pwd)"
KUBECONFIG="${KUBECONFIG:-${ROOT_REPO}/connect/prd/kubeconfig}"
export KUBECONFIG
NS=onepassword
CREDS_TMP="$(mktemp)"
trap 'rm -f "${CREDS_TMP}"' EXIT

if [[ ! -f "${KUBECONFIG}" ]]; then
  echo "missing ${KUBECONFIG} — run: moon run connect:sync" >&2
  exit 1
fi
if ! command -v op >/dev/null 2>&1; then
  echo "op CLI required to fetch Connect credentials" >&2
  exit 1
fi

echo "fetching 1password-credentials.json from Homelab (prd Connect credentials)"
op document get 'prd Connect credentials' --vault Homelab --out-file "${CREDS_TMP}" --force
if [[ ! -s "${CREDS_TMP}" ]]; then
  echo "empty credentials file from 1Password" >&2
  exit 1
fi

helm repo add 1password https://1password.github.io/connect-helm-charts/ >/dev/null 2>&1 || true
helm repo update 1password >/dev/null

kubectl create namespace "${NS}" --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install onepassword-connect 1password/connect \
  --version "${CHART_VERSION}" \
  --namespace "${NS}" \
  --values "${ROOT}/values.yaml" \
  --set-file connect.credentials="${CREDS_TMP}" \
  --wait \
  --timeout 5m

kubectl -n "${NS}" get pods,svc -o wide
echo "OK — 1Password Connect ${CHART_VERSION} (http://onepassword-connect.${NS}.svc:8080)"
