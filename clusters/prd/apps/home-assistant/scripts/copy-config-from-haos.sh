#!/usr/bin/env bash
# Copy Home Assistant /config from HA OS VM 105 into home-assistant-config PVC,
# then install pinned hass-oidc-auth custom component.
#
# Requires: kubectl (connect/prd), SSH to the HA OS host (hassio / homeassistant user).
#
# Usage (from repo root):
#   source connect/env.sh
#   ./clusters/prd/apps/home-assistant/scripts/copy-config-from-haos.sh
set -eo pipefail

HA_HOST="${HA_HOST:-root@192.168.2.8}"
# HA OS: Supervisor-managed config is usually /config via SSH addon, or
# /mnt/data/supervisor/homeassistant on the host console.
REMOTE_CONFIG="${REMOTE_CONFIG:-/config}"
NS=home-assistant
PVC=home-assistant-config
ALPINE_IMAGE=docker.io/library/alpine:3.20.3@sha256:029a752048e32e843bd6defe3841186fb8d19a28dae8ec287f433bb9d6d1ad85
OIDC_VERSION=v1.2.1
OIDC_ZIP_URL="https://github.com/christiaangoossens/hass-oidc-auth/releases/download/${OIDC_VERSION}/hass-oidc-auth.zip"

ssh_ha() {
  if [[ -n "${SSHPASS:-}" ]] && command -v sshpass >/dev/null; then
    sshpass -e ssh \
      -o StrictHostKeyChecking=accept-new \
      -o PreferredAuthentications=password \
      -o PubkeyAuthentication=no \
      "${HA_HOST}" "$@"
    return
  fi
  ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new "${HA_HOST}" "$@"
}

echo "==> Stopping Home Assistant Core on ${HA_HOST} (best-effort)"
ssh_ha "ha core stop" 2>/dev/null \
  || ssh_ha "hassio homeassistant stop" 2>/dev/null \
  || echo "WARN: could not stop core via ha CLI — stop the VM or Core in UI before continuing if SQLite is busy"

echo "==> Scaling down k8s home-assistant (RWO iSCSI)"
kubectl -n "${NS}" scale deploy/home-assistant --replicas=0 2>/dev/null || true
kubectl -n "${NS}" wait --for=delete pod -l app.kubernetes.io/name=home-assistant --timeout=180s 2>/dev/null || true

echo "==> Waiting for PVC ${PVC}"
kubectl -n "${NS}" wait --for=jsonpath='{.status.phase}'=Bound "pvc/${PVC}" --timeout=300s

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

echo "==> Fetch config from ${HA_HOST}:${REMOTE_CONFIG}"
ssh_ha "test -d ${REMOTE_CONFIG} && tar -C ${REMOTE_CONFIG} -cf - \
  --exclude='./home-assistant_v2.db-shm' \
  --exclude='./home-assistant_v2.db-wal' \
  --exclude='./deps' \
  --exclude='./__pycache__' \
  ." >"${tmpdir}/ha-config.tar"

echo "==> Download hass-oidc-auth ${OIDC_VERSION}"
curl -fsSL "${OIDC_ZIP_URL}" -o "${tmpdir}/hass-oidc-auth.zip"

echo "==> Load into PVC ${PVC}"
kubectl -n "${NS}" delete pod cfg-copy-home-assistant --ignore-not-found --wait=true
kubectl -n "${NS}" run cfg-copy-home-assistant \
  --image="${ALPINE_IMAGE}" \
  --restart=Never \
  --overrides="$(cat <<EOF
{
  "spec": {
    "containers": [{
      "name": "copy",
      "image": "${ALPINE_IMAGE}",
      "command": ["sleep", "7200"],
      "volumeMounts": [{"name": "cfg", "mountPath": "/config"}]
    }],
    "volumes": [{"name": "cfg", "persistentVolumeClaim": {"claimName": "${PVC}"}}],
    "restartPolicy": "Never"
  }
}
EOF
)"

kubectl -n "${NS}" wait --for=condition=Ready pod/cfg-copy-home-assistant --timeout=180s
kubectl -n "${NS}" exec -i cfg-copy-home-assistant -- sh -c 'rm -rf /config/* /config/.[!.]* /config/..?* 2>/dev/null; tar -C /config -xf -' \
  <"${tmpdir}/ha-config.tar"

kubectl -n "${NS}" cp "${tmpdir}/hass-oidc-auth.zip" "${NS}/cfg-copy-home-assistant:/tmp/hass-oidc-auth.zip"
kubectl -n "${NS}" exec cfg-copy-home-assistant -- sh -c '
  set -e
  apk add --no-cache unzip >/dev/null
  mkdir -p /config/custom_components/auth_oidc
  rm -rf /config/custom_components/auth_oidc/*
  unzip -qo /tmp/hass-oidc-auth.zip -d /config/custom_components/auth_oidc
  rm -f /tmp/hass-oidc-auth.zip
  mkdir -p /config/packages
'

kubectl -n "${NS}" delete pod cfg-copy-home-assistant --wait=true

cat <<'EOF'

Config copied into PVC home-assistant-config (incl. hass-oidc-auth).
Next:
  1. Ensure 1Password items exist (prd Home Assistant Postgres + OIDC).
  2. Wait for home-assistant-pg Ready.
  3. ./clusters/prd/apps/home-assistant/scripts/migrate-recorder-to-postgres.sh
  4. kubectl -n home-assistant scale deploy/home-assistant --replicas=1
  5. Confirm https://homeassistant.lab.jacobdrury.com and Authentik SSO.
  6. Stop / onboot=0 Proxmox VM 105 after soak.
EOF
