#!/usr/bin/env bash
# Sourced by OpenTofu moon tasks. Reads secrets from project env (infrastructure/*/moon.yml).
#
#   TOFU_SECRET_<NAME>=op://...   → op read → export NAME
#   TOFU_ENV_<NAME>=value         → export NAME=value (no op)
set -euo pipefail

if ! command -v op &>/dev/null; then
  echo "op CLI not found — install: brew install --cask 1password-cli" >&2
  exit 1
fi

has_secret=false
while IFS='=' read -r key value; do
  [[ "$key" == TOFU_SECRET_* ]] || continue
  has_secret=true
  var_name="${key#TOFU_SECRET_}"
  export "$var_name"
  printf -v "$var_name" '%s' "$(op read "$value")"
done < <(env | grep '^TOFU_SECRET_' || true)

while IFS='=' read -r key value; do
  [[ "$key" == TOFU_ENV_* ]] || continue
  var_name="${key#TOFU_ENV_}"
  export "$var_name=$value"
done < <(env | grep '^TOFU_ENV_' || true)

if [[ "$has_secret" == false ]]; then
  echo "no TOFU_SECRET_* vars — set project env in moon.yml" >&2
  exit 1
fi
