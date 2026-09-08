# shellcheck shell=bash
# For scripts / agents that are not inside connect/<cluster> (no direnv).
# Prefer: cd connect/prd   (direnv loads env)
#
#   source connect/env.sh              # default prd
#   CONNECT_CLUSTER=stg source connect/env.sh

_connect_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
_cluster="${CONNECT_CLUSTER:-prd}"
_cfg="${_connect_dir}/${_cluster}"

export KUBECONFIG="${_cfg}/kubeconfig"
export TALOSCONFIG="${_cfg}/talosconfig"

if [[ ! -f "${KUBECONFIG}" ]] || [[ ! -f "${TALOSCONFIG}" ]]; then
  echo "connect: missing ${_cluster} configs — run: CONNECT_CLUSTER=${_cluster} moon run connect:sync" >&2
fi

unset _connect_dir _cluster _cfg
