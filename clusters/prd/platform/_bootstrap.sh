# Shared helpers for platform bootstrap / DR scripts.
# shellcheck shell=bash

PLATFORM_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${PLATFORM_ROOT}/../../.." && pwd)"

homelab_kubeconfig() {
  export KUBECONFIG="${KUBECONFIG:-${REPO_ROOT}/connect/prd/kubeconfig}"
  if [[ ! -f "${KUBECONFIG}" ]]; then
    echo "missing ${KUBECONFIG} — run: moon run connect:sync" >&2
    exit 1
  fi
}

# Keep seeded Secrets when Argo prune runs (chicken-and-egg credentials).
homelab_protect_secret() {
  local ns="$1" name="$2"
  kubectl -n "${ns}" annotate secret "${name}" \
    argocd.argoproj.io/sync-options=Prune=false \
    --overwrite >/dev/null
}
