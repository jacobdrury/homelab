#!/usr/bin/env bash
# Copy *arr / qBit configs from Proxmox arr VM into media namespace iSCSI PVCs.
# Requires: kubectl (connect/prd), SSH to arr. Set SSHPASS if using password auth.
#
# Usage (from repo root):
#   source connect/env.sh
#   ARR_HOST=arr@arr.lab.jacobdrury.com SSHPASS=… ./clusters/prd/apps/media/scripts/copy-configs-from-arr.sh
set -eo pipefail

ARR_HOST="${ARR_HOST:-arr@arr.lab.jacobdrury.com}"
ARR_STACK="${ARR_STACK:-/home/arr/docker/arr-stack}"
NS=media
COMPOSE_DIR="${COMPOSE_DIR:-/home/arr/docker}"

remote_config() {
  case "$1" in
    qbittorrent) echo "${ARR_STACK}/qbittorrent" ;;
    sonarr-anime) echo "${ARR_STACK}/sonarr-anime/data" ;;
    sonarr-tv) echo "${ARR_STACK}/sonarr-tv/data" ;;
    prowlarr) echo "${ARR_STACK}/prowlarr/data" ;;
    *) echo "unknown app: $1" >&2; return 1 ;;
  esac
}

pvc_for() {
  case "$1" in
    qbittorrent) echo qbittorrent-config ;;
    sonarr-anime) echo sonarr-anime-config ;;
    sonarr-tv) echo sonarr-tv-config ;;
    prowlarr) echo prowlarr-config ;;
    *) echo "unknown app: $1" >&2; return 1 ;;
  esac
}

ssh_arr() {
  if [[ -n "${SSHPASS:-}" ]] && command -v sshpass >/dev/null; then
    sshpass -e ssh \
      -o StrictHostKeyChecking=accept-new \
      -o PreferredAuthentications=password \
      -o PubkeyAuthentication=no \
      "${ARR_HOST}" "$@"
    return
  fi
  ssh -o BatchMode=yes "${ARR_HOST}" "$@"
}

echo "==> Stopping Compose apps on ${ARR_HOST} (Jellyfin + gluetun stay up for now)"
ssh_arr "cd ${COMPOSE_DIR} && docker compose stop qbittorrent sonarr-anime sonarr-tv prowlarr"

echo "==> Scaling down k8s Deployments (RWO iSCSI PVCs cannot attach to copy pods otherwise)"
kubectl -n "${NS}" scale deploy/qbittorrent deploy/sonarr-anime deploy/sonarr-tv deploy/prowlarr --replicas=0
kubectl -n "${NS}" wait --for=delete pod -l 'app.kubernetes.io/name in (qbittorrent,sonarr-anime,sonarr-tv,prowlarr)' --timeout=180s || true

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

copy_one() {
  local name="$1"
  local pvc remote
  pvc="$(pvc_for "${name}")"
  remote="$(remote_config "${name}")"

  echo "==> ${name}: fetch from ${remote}"
  ssh_arr "test -d ${remote} && tar -C ${remote} -cf - ." >"${tmpdir}/${name}.tar"

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
  kubectl -n "${NS}" exec -i "cfg-copy-${name}" -- sh -c 'rm -rf /config/* /config/.[!.]* /config/..?* 2>/dev/null; tar -C /config -xf -' \
    <"${tmpdir}/${name}.tar"
  kubectl -n "${NS}" exec "cfg-copy-${name}" -- chown -R 99:100 /config
  kubectl -n "${NS}" delete pod "cfg-copy-${name}" --wait=true
  echo "==> ${name}: done"
}

for app in qbittorrent sonarr-anime sonarr-tv prowlarr; do
  copy_one "${app}"
done

echo "==> Scale media Deployments back up with copied configs"
kubectl -n "${NS}" scale deploy/qbittorrent deploy/sonarr-anime deploy/sonarr-tv deploy/prowlarr --replicas=1
kubectl -n "${NS}" rollout status deploy/qbittorrent --timeout=180s
kubectl -n "${NS}" rollout status deploy/sonarr-anime --timeout=180s
kubectl -n "${NS}" rollout status deploy/sonarr-tv --timeout=180s
kubectl -n "${NS}" rollout status deploy/prowlarr --timeout=180s

cat <<'EOF'

Next (post-copy fixes):
  1. qBit Network Interface = wg0; WebUI port 8080
  2. Sonarr download clients → qbittorrent.media.svc.cluster.local:8080
  3. Prowlarr apps → sonarr-*.media.svc.cluster.local
  4. Enable httproutes.yaml; remove those routes from transitional/

Compose on arr remains stopped for the four apps — do not start them again after cutover.
EOF
