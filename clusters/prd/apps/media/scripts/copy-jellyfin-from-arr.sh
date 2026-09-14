#!/usr/bin/env bash
# Copy Jellyfin config from Proxmox arr VM into media/jellyfin-config PVC.
# Requires: kubectl (connect/prd), SSH to arr.
#
# Usage (from repo root):
#   source connect/env.sh
#   ./clusters/prd/apps/media/scripts/copy-jellyfin-from-arr.sh
set -eo pipefail

ARR_HOST="${ARR_HOST:-arr@192.168.1.9}"
ARR_STACK="${ARR_STACK:-/home/arr/docker/arr-stack}"
COMPOSE_DIR="${COMPOSE_DIR:-/home/arr/docker}"
NS=media
PVC=jellyfin-config
REMOTE_CONFIG="${ARR_STACK}/jellyfin/config"

ssh_arr() {
  if [[ -n "${SSHPASS:-}" ]] && command -v sshpass >/dev/null; then
    sshpass -e ssh \
      -o StrictHostKeyChecking=accept-new \
      -o PreferredAuthentications=password \
      -o PubkeyAuthentication=no \
      "${ARR_HOST}" "$@"
    return
  fi
  ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new "${ARR_HOST}" "$@"
}

echo "==> Stopping Compose jellyfin on ${ARR_HOST}"
ssh_arr "cd ${COMPOSE_DIR} && docker compose stop jellyfin"

echo "==> Scaling down k8s jellyfin (RWO iSCSI)"
kubectl -n "${NS}" scale deploy/jellyfin --replicas=0 2>/dev/null || true
kubectl -n "${NS}" wait --for=delete pod -l app.kubernetes.io/name=jellyfin --timeout=180s 2>/dev/null || true

echo "==> Waiting for PVC ${PVC}"
kubectl -n "${NS}" wait --for=jsonpath='{.status.phase}'=Bound "pvc/${PVC}" --timeout=300s

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

echo "==> Fetch config from ${REMOTE_CONFIG} (may take a few minutes; ~2.7G)"
ssh_arr "test -d ${REMOTE_CONFIG} && tar -C ${REMOTE_CONFIG} -cf - ." >"${tmpdir}/jellyfin-config.tar"

echo "==> Load into PVC ${PVC}"
kubectl -n "${NS}" delete pod cfg-copy-jellyfin --ignore-not-found --wait=true
kubectl -n "${NS}" run cfg-copy-jellyfin \
  --image=docker.io/library/alpine:3.20.3@sha256:029a752048e32e843bd6defe3841186fb8d19a28dae8ec287f433bb9d6d1ad85 \
  --restart=Never \
  --overrides="$(cat <<EOF
{
  "spec": {
    "containers": [{
      "name": "copy",
      "image": "docker.io/library/alpine:3.20.3@sha256:029a752048e32e843bd6defe3841186fb8d19a28dae8ec287f433bb9d6d1ad85",
      "command": ["sleep", "7200"],
      "volumeMounts": [{"name": "cfg", "mountPath": "/config"}]
    }],
    "volumes": [{"name": "cfg", "persistentVolumeClaim": {"claimName": "${PVC}"}}],
    "restartPolicy": "Never",
    "nodeSelector": {"node-role.kubernetes.io/control-plane": ""},
    "tolerations": [{"key": "node-role.kubernetes.io/control-plane", "operator": "Exists", "effect": "NoSchedule"}]
  }
}
EOF
)"

kubectl -n "${NS}" wait --for=condition=Ready pod/cfg-copy-jellyfin --timeout=180s
kubectl -n "${NS}" exec -i cfg-copy-jellyfin -- sh -c 'rm -rf /config/* /config/.[!.]* /config/..?* 2>/dev/null; tar -C /config -xf -' \
  <"${tmpdir}/jellyfin-config.tar"
kubectl -n "${NS}" exec cfg-copy-jellyfin -- chown -R 1000:1000 /config
kubectl -n "${NS}" delete pod cfg-copy-jellyfin --wait=true

echo "==> Scale jellyfin back up"
kubectl -n "${NS}" scale deploy/jellyfin --replicas=1
kubectl -n "${NS}" rollout status deploy/jellyfin --timeout=300s

cat <<'EOF'

Jellyfin config copied. Compose jellyfin on arr stays stopped — do not start it again after cutover.
Confirm https://jellyfin.lab.jacobdrury.com and remove transitional jellyfin Backend/HTTPRoute if still present.
EOF
