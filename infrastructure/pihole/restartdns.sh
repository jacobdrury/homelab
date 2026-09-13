#!/usr/bin/env bash
# Clear Pi-hole FTL DNS cache (negative NXDOMAIN/NODATA for new Cloudflare records).
# Uses Pi-hole v6 API: POST /api/action/restartdns
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "${MOON_WORKSPACE_ROOT:-$(cd "${ROOT}/../.." && pwd)}/.moon/scripts/tofu/env.sh"

LAB_YAML="${MOON_WORKSPACE_ROOT:-$(cd "${ROOT}/../.." && pwd)}/infrastructure/lab.yaml"
if [[ -z "${PIHOLE_URL:-}" ]]; then
  HOST="$(python3 - "${LAB_YAML}" <<'PY'
import pathlib, re, sys
text = pathlib.Path(sys.argv[1]).read_text()
m = re.search(r"(?m)^[ \t]*pihole:[ \t]*\n[ \t]+host:[ \t]*([^\s#]+)", text)
if not m:
    raise SystemExit(f"pihole.host not found in {sys.argv[1]}")
print(m.group(1))
PY
)"
  PIHOLE_URL="http://${HOST}"
fi

if [[ -z "${PIHOLE_PASSWORD:-}" ]]; then
  echo "PIHOLE_PASSWORD unset — moon should load it via TOFU_SECRET_PIHOLE_PASSWORD" >&2
  exit 1
fi

AUTH="$(curl -fsS -m 15 -X POST "${PIHOLE_URL}/api/auth" \
  -H 'Content-Type: application/json' \
  -d "{\"password\":$(python3 -c 'import json,os; print(json.dumps(os.environ["PIHOLE_PASSWORD"]))')}")"

SID="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["session"]["sid"])' <<<"${AUTH}")"
CSRF="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["session"]["csrf"])' <<<"${AUTH}")"

curl -fsS -m 30 -X POST "${PIHOLE_URL}/api/action/restartdns" \
  -H "sid: ${SID}" \
  -H "X-FTL-CSRF: ${CSRF}" \
  -H "X-CSRF-Token: ${CSRF}" \
  -H 'Content-Type: application/json' \
  -d '{}' >/dev/null

echo "OK — Pi-hole DNS restarted (${PIHOLE_URL})"

# Optional smoke: confirm apex resolves via this Pi-hole after flush.
CHECK_NAME="${PIHOLE_CHECK_NAME:-lab.jacobdrury.com}"
HOST_ONLY="${PIHOLE_URL#http://}"
HOST_ONLY="${HOST_ONLY#https://}"
HOST_ONLY="${HOST_ONLY%%/*}"
if command -v dig >/dev/null 2>&1; then
  ANSWER="$(dig @"${HOST_ONLY}" "${CHECK_NAME}" A +short | head -n1 || true)"
  if [[ -n "${ANSWER}" ]]; then
    echo "check ${CHECK_NAME} @${HOST_ONLY} → ${ANSWER}"
  else
    echo "check ${CHECK_NAME} @${HOST_ONLY} → (no A yet — client/browser may still need a moment)" >&2
  fi
fi
