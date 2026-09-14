#!/usr/bin/env bash
# Copy *arr / qBit configs from Proxmox arr VM into media namespace iSCSI PVCs.
# Requires: kubectl (connect/prd), SSH to arr@192.168.1.9, jq optional.
#
# Usage (from repo root):
#   source connect/env.sh
#   ./clusters/prd/apps/media/scripts/copy-configs-from-arr.sh
set -euo pipefail

ARR_HOST="${ARR_HOST:-arr@192.168.1.9}"
ARR_STACK="${ARR_STACK:-/home/arr/docker/arr-stack}"
NS=media
COMPOSE_DIR="${COMPOSE_DIR:-/home/arr/docker}"

# Map: remote relative dir under ARR_STACK → PVC name
# Adjust REMOTE_* if compose volume paths differ on the VM.
declare -A PVC_FOR=(
  [qbittorrent]=qbittorrent-config
  [sonarr-anime]=sonarr-anime-config
  [sonarr-tv]=sonarr-tv-config
  [prowlarr]=prowlarr-config
)

echo "==> Stopping Compose apps on ${ARR_HOST} (Jellyfin stays up)"
ssh -o BatchMode=yes "${ARR_HOST}" \
  "cd ${COMPOSE_DIR} && docker compose stop qbittorrent sonarr-anime sonarr-tv prowlarr"

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

copy_one() {
  local name="$1"
  local pvc="${PVC_FOR[$name]}"
  local remote="${ARR_STACK}/${name}"

  echo "==> ${name}: fetch from ${remote}"
  ssh -o BatchMode=yes "${ARR_HOST}" \
    "test -d ${remote}/config && tar -C ${remote}/config -cf - . || tar -C ${remote} -cf - ." \
    >"${tmpdir}/${name}.tar"

  echo "==> ${name}: load into PVC ${pvc}"
  kubectl -n "${NS}" delete pod "cfg-copy-${name}" --ignore-not-found --wait=true
  kubectl -n "${NS}" run "cfg-copy-${name}" \
    --image=docker.io/library/alpine:3.20.3@sha256:029a752048e32e843bd6defe3841186fb8d19a28dae8ec287f433bb9d6d1ad85 \
    --restart=Never \
    --overrides="$(cat <<EOF
{
  "spec": {
    "containers": [{
      "name": "copy",
      "image": "docker.io/library/alpine:3.20.3@sha256:029a752048e32e843bd6defe3841186fb8d19a28dae8ec287f433bb9d6d1ad85",
      "command": ["sleep", "3600"],
      "volumeMounts": [{"name": "cfg", "mountPath": "/config"}]
    }],
    "volumes": [{"name": "cfg", "persistentVolumeClaim": {"claimName": "${pvc}"}}],
    "restartPolicy": "Never",
    "nodeSelector": {"node-role.kubernetes.io/control-plane": ""},
    "tolerations": [{"key": "node-role.kubernetes.io/control-plane", "operator": "Exists", "effect": "NoSchedule"}]
  }
}
EOF
)"

  kubectl -n "${NS}" wait --for=condition=Ready "pod/cfg-copy-${name}" --timeout=120s
  kubectl -n "${NS}" exec -i "cfg-copy-${name}" -- sh -c 'rm -rf /config/* /config/.[!.]* 2>/dev/null; tar -C /config -xf -' \
    <"${tmpdir}/${name}.tar"
  kubectl -n "${NS}" exec "cfg-copy-${name}" -- chown -R 99:100 /config
  kubectl -n "${NS}" delete pod "cfg-copy-${name}" --wait=true
  echo "==> ${name}: done"
}

for app in qbittorrent sonarr-anime sonarr-tv prowlarr; do
  copy_one "${app}"
done

echo "==> Restart media Deployments to pick up configs"
kubectl -n "${NS}" rollout restart deploy/qbittorrent deploy/sonarr-anime deploy/sonarr-tv deploy/prowlarr
kubectl -n "${NS}" rollout status deploy/qbittorrent --timeout=180s
kubectl -n "${NS}" rollout status deploy/sonarr-anime --timeout=180s
kubectl -n "${NS}" rollout status deploy/sonarr-tv --timeout=180s
kubectl -n "${NS}" rollout status deploy/prowlarr --timeout=180s

cat <<'EOF'

Next:
  1. Port-forward and set qBit Network Interface = wg0
  2. Point Sonarr download clients at qbittorrent.media.svc.cluster.local:8080
  3. Align root folders with /anime /tv /downloads if needed
  4. Enable httproutes.yaml in application.yaml; remove those routes from transitional/

Compose on arr remains stopped for the four apps — do not start them again after cutover.
EOF
