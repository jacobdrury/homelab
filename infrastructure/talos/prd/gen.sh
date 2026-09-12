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

# Default --install-disk is yavin's NVMe; naboo patch overrides to /dev/vda for the worker.
talosctl gen config prd "https://k8s.lab.jacobdrury.com:6443" \
  --with-secrets secrets.yaml \
  --install-disk /dev/nvme0n1 \
  --install-image "$INSTALL_IMAGE" \
  --additional-sans k8s.lab.jacobdrury.com,yavin.lab.jacobdrury.com,naboo.lab.jacobdrury.com,192.168.5.11,192.168.5.14 \
  --config-patch @"${ROOT}/patches/cluster.yaml" \
  --config-patch-control-plane @"${ROOT}/patches/yavin.yaml" \
  --config-patch-worker @"${ROOT}/patches/naboo.yaml" \
  --with-docs=false \
  --with-examples=false \
  -t controlplane,worker,talosconfig \
  -o generated/ \
  --force

# Talos 1.12+: replace generated HostnameConfig (auto: stable) with static names
python3 - <<'PY'
from pathlib import Path

hosts = {
    "generated/controlplane.yaml": "yavin",
    "generated/worker.yaml": "naboo",
}

for path_str, hostname in hosts.items():
    path = Path(path_str)
    parts = path.read_text().split("\n---\n")
    out = []
    for part in parts:
        if "kind: HostnameConfig" in part:
            out.append(
                "apiVersion: v1alpha1\n"
                f"kind: HostnameConfig\nauto: off\nhostname: {hostname}\n"
            )
        else:
            out.append(part.rstrip("\n"))
    path.write_text("\n---\n".join(out).rstrip() + "\n")
PY

talosctl validate -c generated/controlplane.yaml --mode metal
talosctl validate -c generated/worker.yaml --mode metal

# Cluster is up — default to yavin; override TALOS_ENDPOINT for maintenance apply.
ENDPOINT="${TALOS_ENDPOINT:-192.168.5.11}"
talosctl --talosconfig generated/talosconfig config endpoint "$ENDPOINT"
talosctl --talosconfig generated/talosconfig config node 192.168.5.11

echo "OK — installer ${INSTALL_IMAGE} (${VERSION})"
echo "     CP:     generated/controlplane.yaml  (yavin)"
echo "     worker: generated/worker.yaml        (naboo)"
echo "     apply naboo (maintenance IP):"
echo "       talosctl apply-config --insecure -n <maint-ip> -f generated/worker.yaml"
