#!/usr/bin/env bash
# Authentik sits in front of uptime.lab — OpenTofu talks to Kuma via local port-forward.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT}/connect/env.sh"

PORT="${UPTIMEKUMA_PORTFORWARD:-13001}"
NS="${UPTIMEKUMA_NAMESPACE:-uptime-kuma}"
SVC="${UPTIMEKUMA_SERVICE:-uptime-kuma}"

cleanup() {
  if [[ -n "${PF_PID:-}" ]]; then
    kill "${PF_PID}" 2>/dev/null || true
    wait "${PF_PID}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

kubectl -n "${NS}" port-forward "svc/${SVC}" "${PORT}:3001" >/dev/null 2>&1 &
PF_PID=$!

ready=false
for _ in $(seq 1 40); do
  if curl -sf -o /dev/null "http://127.0.0.1:${PORT}/"; then
    ready=true
    break
  fi
  sleep 0.25
done

if [[ "${ready}" != true ]]; then
  echo "port-forward to ${NS}/${SVC} failed on :${PORT}" >&2
  exit 1
fi

export UPTIMEKUMA_ENDPOINT="http://127.0.0.1:${PORT}"
exec "$@"
