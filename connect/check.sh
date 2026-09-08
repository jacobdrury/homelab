#!/usr/bin/env bash
# Verify kubectl + talosctl against connect/<cluster>.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=env.sh
source "${ROOT}/connect/env.sh"

if [[ ! -f "${KUBECONFIG}" ]] || [[ ! -f "${TALOSCONFIG}" ]]; then
  echo "run: moon run connect:sync" >&2
  exit 1
fi

echo "== kubectl =="
kubectl config current-context
kubectl get nodes -o wide

echo
echo "== talosctl =="
talosctl version --short
talosctl get members -o yaml 2>/dev/null | head -40 || talosctl health --wait-timeout 30s
