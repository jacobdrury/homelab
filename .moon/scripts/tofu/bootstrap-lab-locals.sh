#!/usr/bin/env bash
# Create lab_locals.tf when ../lab.yaml exists (infrastructure/* OpenTofu projects).
set -euo pipefail

lab_yaml="../lab.yaml"
lab_locals="lab_locals.tf"

if [[ ! -f "$lab_yaml" ]]; then
  exit 0
fi

if [[ -f "$lab_locals" ]]; then
  exit 0
fi

cat >"$lab_locals" <<'EOF'
locals {
  lab = yamldecode(file("${path.module}/../lab.yaml"))
}
EOF

echo "bootstrap: created ${lab_locals} (reads ../lab.yaml)"
