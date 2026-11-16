#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

for package in gtk4 webkitgtk-6.0; do
  if ! pkg-config --exists "$package"; then
    echo "Missing native development dependency: $package" >&2
    echo "Install the matching Arch Linux development package before continuing." >&2
    exit 1
  fi
done

echo "== Building Oziro frontend for local WebKit loading =="
npm run build

echo "== Starting Oziro GTK4 + WebKitGTK native window =="
cargo run -p oziro-shell-host
