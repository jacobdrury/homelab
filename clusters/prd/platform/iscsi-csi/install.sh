#!/usr/bin/env bash
# Bootstrap democratic-csi (scarif-iscsi). Seeds driver-config Secret from 1Password
# (same shape Argo ExternalSecret later owns), then Helm with values.yaml.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../_bootstrap.sh
source "${ROOT}/../_bootstrap.sh"
homelab_kubeconfig

CHART_VERSION="${DEMOCRATIC_CSI_VERSION:-0.15.1}"
NS=democratic-csi
SECRET=scarif-iscsi-democratic-csi-driver-config
KEY_TMP="$(mktemp)"
CFG_TMP="$(mktemp)"
trap 'rm -f "${KEY_TMP}" "${CFG_TMP}"' EXIT

if ! command -v op >/dev/null 2>&1; then
  echo "op CLI required to fetch scarif CSI SSH private key" >&2
  exit 1
fi

echo "fetching SSH private key from Homelab (scarif CSI SSH)"
op item get 'scarif CSI SSH (democratic-csi)' --reveal --fields 'private key' \
  | sed 's/^"//;s/"$//' > "${KEY_TMP}"
chmod 600 "${KEY_TMP}"
if ! grep -q 'BEGIN OPENSSH PRIVATE KEY' "${KEY_TMP}"; then
  echo "1Password fetch did not look like an OpenSSH private key" >&2
  exit 1
fi

# Match ExternalSecret template in resources.yaml (driver-config-file.yaml).
{
  echo 'driver: zfs-generic-iscsi'
  echo 'sshConnection:'
  echo '  host: 192.168.5.10'
  echo '  port: 22'
  echo '  username: root'
  echo '  privateKey: |'
  sed 's/^/    /' "${KEY_TMP}"
  cat <<'EOF'
zfs:
  datasetParentName: scarif-ssd/k8s/vols
  detachedSnapshotsDatasetParentName: scarif-ssd/k8s/snaps
  zvolEnableReservation: false
  zvolCompression: ""
  zvolDedup: ""
  zvolBlocksize: ""
iscsi:
  shareStrategy: targetCli
  shareStrategyTargetCli:
    basename: iqn.2026-09.com.jacobdrury.scarif
    tpg:
      attributes:
        authentication: 0
        generate_node_acls: 1
        cache_dynamic_acls: 1
        demo_mode_write_protect: 0
      auth: {}
    block:
      attributes:
        emulate_tpu: 0
  targetPortal: 192.168.5.10:3260
  interface: ""
  namePrefix: csi-
  nameSuffix: -prd
EOF
} > "${CFG_TMP}"

helm repo add democratic-csi https://democratic-csi.github.io/charts/ >/dev/null 2>&1 || true
helm repo update democratic-csi >/dev/null

kubectl create namespace "${NS}" --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "${NS}" \
  pod-security.kubernetes.io/enforce=privileged \
  pod-security.kubernetes.io/audit=privileged \
  pod-security.kubernetes.io/warn=privileged \
  --overwrite

kubectl -n "${NS}" create secret generic "${SECRET}" \
  --from-file=driver-config-file.yaml="${CFG_TMP}" \
  --dry-run=client -o yaml | kubectl apply -f -
homelab_protect_secret "${NS}" "${SECRET}"

helm upgrade --install scarif-iscsi democratic-csi/democratic-csi \
  --version "${CHART_VERSION}" \
  --namespace "${NS}" \
  --values "${ROOT}/values.yaml" \
  --wait \
  --timeout 10m

# When ESO is already up, let it own refreshes (safe no-op if CRDs missing).
if kubectl get crd externalsecrets.external-secrets.io >/dev/null 2>&1; then
  kubectl apply -f "${ROOT}/resources.yaml"
fi

kubectl get sc scarif-iscsi
kubectl -n "${NS}" get pods -o wide
echo "OK — democratic-csi ${CHART_VERSION} (scarif-iscsi)"
