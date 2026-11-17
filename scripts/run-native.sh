#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

for package in gtk4 webkitgtk-6.0 gtk4-layer-shell-0; do
  if ! pkg-config --exists "$package"; then
    echo "Missing native development dependency: $package" >&2
    exit 1
  fi
done

echo "== Building Oziro Liquid Glass panel =="
npm run build

echo "== Starting Oziro native Wayland panel =="
cargo run -p oziro-shell-host
