# Bootstrap democratic-csi (zfs-generic-iscsi) onto prd. Idempotent.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
CHART_VERSION="${DEMOCRATIC_CSI_VERSION:-0.15.1}"
ROOT_REPO="$(cd "${ROOT}/../../.." && pwd)"
KUBECONFIG="${KUBECONFIG:-${ROOT_REPO}/connect/prd/kubeconfig}"
export KUBECONFIG
KEY_FILE="${ROOT}/secrets/scarif-csi"
VALUES_TMP="$(mktemp)"
trap 'rm -f "${VALUES_TMP}"' EXIT

if [[ ! -f "${KUBECONFIG}" ]]; then
  echo "missing ${KUBECONFIG} — run: moon run connect:sync" >&2
  exit 1
fi
if [[ ! -f "${KEY_FILE}" ]]; then
  if command -v op >/dev/null 2>&1; then
    echo "missing ${KEY_FILE} — fetching from 1Password (scarif CSI SSH)"
    mkdir -p "$(dirname "${KEY_FILE}")"
    # SSH Key item in Homelab vault
    op item get 'scarif CSI SSH (democratic-csi)' --reveal --fields 'private key' \
      | sed 's/^"//;s/"$//' > "${KEY_FILE}"
    chmod 600 "${KEY_FILE}"
    if ! grep -q 'BEGIN OPENSSH PRIVATE KEY' "${KEY_FILE}"; then
      echo "1Password fetch did not look like an OpenSSH private key" >&2
      rm -f "${KEY_FILE}"
      exit 1
    fi
  else
    echo "missing ${KEY_FILE}" >&2
    echo "  restore from 1Password item: scarif CSI SSH (democratic-csi)" >&2
    echo "  or: ssh-keygen -t ed25519 -f ${KEY_FILE} -N '' -C 'democratic-csi@prd'" >&2
    exit 1
  fi
fi

# Inject private key into values (never commit secrets/)
python3 - "${ROOT}/values.yaml" "${KEY_FILE}" "${VALUES_TMP}" <<'PY'
import sys
from pathlib import Path
values_path, key_path, out_path = sys.argv[1:4]
text = Path(values_path).read_text()
key = Path(key_path).read_text().rstrip("\n") + "\n"
# Content under a literal block must be indented deeper than `privateKey: |`
indented = "\n".join("        " + line if line else "" for line in key.splitlines())
needle = '      privateKey: ""'
if needle not in text:
    raise SystemExit('values.yaml missing privateKey: "" placeholder')
replacement = "      privateKey: |\n" + indented
Path(out_path).write_text(text.replace(needle, replacement, 1))
PY

helm repo add democratic-csi https://democratic-csi.github.io/charts/ >/dev/null 2>&1 || true
helm repo update democratic-csi >/dev/null

kubectl create namespace democratic-csi --dry-run=client -o yaml | kubectl apply -f -
# CSI node pods need hostPath / privileged (baseline PSA blocks them otherwise)
kubectl label namespace democratic-csi \
  pod-security.kubernetes.io/enforce=privileged \
  pod-security.kubernetes.io/audit=privileged \
  pod-security.kubernetes.io/warn=privileged \
  --overwrite

helm upgrade --install scarif-iscsi democratic-csi/democratic-csi \
  --version "${CHART_VERSION}" \
  --namespace democratic-csi \
  --values "${VALUES_TMP}" \
  --wait \
  --timeout 10m

kubectl get sc scarif-iscsi
kubectl -n democratic-csi get pods -o wide
echo "OK — democratic-csi ${CHART_VERSION} (scarif-iscsi)"
