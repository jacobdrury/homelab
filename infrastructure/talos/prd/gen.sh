#!/usr/bin/env bash
# Regenerate machine configs from secrets + patches.
# Requires: talosctl 1.12.7 (proto), existing secrets.yaml
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

SCHEMATIC_ID="$(tr -d '[:space:]' < schematic.id)"
INSTALL_IMAGE="factory.talos.dev/metal-installer/${SCHEMATIC_ID}:v1.12.7"
VERSION="${TALOS_VERSION:-v1.12.7}"

if [[ ! -f secrets.yaml ]]; then
  echo "missing secrets.yaml — run: talosctl gen secrets -o secrets.yaml" >&2
  exit 1
fi

mkdir -p generated

talosctl gen config prd "https://k8s.lab.jacobdrury.com:6443" \
  --with-secrets secrets.yaml \
  --install-disk /dev/nvme0n1 \
  --install-image "$INSTALL_IMAGE" \
  --additional-sans k8s.lab.jacobdrury.com,yavin.lab.jacobdrury.com,192.168.5.11 \
  --config-patch @"${ROOT}/patches/cluster.yaml" \
  --config-patch-control-plane @"${ROOT}/patches/yavin.yaml" \
  --with-docs=false \
  --with-examples=false \
  -t controlplane,talosconfig \
  -o generated/ \
  --force

# Talos 1.12+: replace generated HostnameConfig (auto: stable) with static yavin
python3 - <<'PY'
from pathlib import Path
path = Path("generated/controlplane.yaml")
parts = path.read_text().split("\n---\n")
out = []
for part in parts:
    if "kind: HostnameConfig" in part:
        out.append(
            "apiVersion: v1alpha1\n"
            "kind: HostnameConfig\nauto: off\nhostname: yavin\n"
        )
    else:
        out.append(part.rstrip("\n"))
path.write_text("\n---\n".join(out).rstrip() + "\n")
PY

talosctl validate -c generated/controlplane.yaml --mode metal

# Maintenance endpoint (DHCP); after install switch to .11
ENDPOINT="${TALOS_ENDPOINT:-192.168.5.128}"
talosctl --talosconfig generated/talosconfig config endpoint "$ENDPOINT"
talosctl --talosconfig generated/talosconfig config node 192.168.5.11

echo "OK — installer ${INSTALL_IMAGE} (${VERSION})"
echo "     config: generated/controlplane.yaml"
echo "     apply:  talosctl apply-config --insecure -n ${ENDPOINT} -f generated/controlplane.yaml"
