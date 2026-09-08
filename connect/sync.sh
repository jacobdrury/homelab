#!/usr/bin/env bash
# Populate connect/<cluster>/{kubeconfig,talosconfig} from Talos generated configs.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLUSTER="${CONNECT_CLUSTER:-prd}"
DEST="${ROOT}/connect/${CLUSTER}"
TALOS_SRC="${ROOT}/infrastructure/talos/${CLUSTER}/generated/talosconfig"
NODE="${TALOS_NODE:-192.168.5.11}"
FALLBACK="${TALOS_NODE_FALLBACK:-192.168.5.111}"

if [[ ! -f "${TALOS_SRC}" ]]; then
  echo "missing ${TALOS_SRC}" >&2
  echo "run: moon run talos-prd:gen   (or ./gen.sh in infrastructure/talos/${CLUSTER})" >&2
  exit 1
fi

mkdir -p "${DEST}"
cp "${TALOS_SRC}" "${DEST}/talosconfig"
chmod 600 "${DEST}/talosconfig"

talosctl --talosconfig "${DEST}/talosconfig" config endpoint "${NODE}"
talosctl --talosconfig "${DEST}/talosconfig" config node "${NODE}"

fetch() {
  local n="$1"
  talosctl --talosconfig "${DEST}/talosconfig" \
    kubeconfig "${DEST}/kubeconfig" \
    -n "${n}" \
    --endpoints "${n}" \
    --merge=false \
    --force
}

if ! fetch "${NODE}"; then
  echo "primary ${NODE} failed — trying fallback ${FALLBACK}" >&2
  talosctl --talosconfig "${DEST}/talosconfig" config endpoint "${FALLBACK}"
  talosctl --talosconfig "${DEST}/talosconfig" config node "${FALLBACK}"
  fetch "${FALLBACK}"
  # Prefer primary endpoint again for day-to-day talosctl
  talosctl --talosconfig "${DEST}/talosconfig" config endpoint "${NODE}"
  talosctl --talosconfig "${DEST}/talosconfig" config node "${NODE}"
fi

chmod 600 "${DEST}/kubeconfig"

echo "OK — ${DEST}/kubeconfig"
echo "OK — ${DEST}/talosconfig"
echo "Load env:  cd connect/${CLUSTER} && direnv allow   # or: source connect/env.sh"
