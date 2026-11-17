#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "== Packaging shell syntax =="
bash -n PKGBUILD
bash -n packaging/bin/oziro-session-start
bash -n scripts/test-on-arch.sh

echo "== Required package assets =="
test -f packaging/systemd/user/oziro-shell.service
test -f packaging/autostart/io.oziro.Desktop.Shell.desktop
test -f frontend/shell-ui/package.json
test -x scripts/test-on-arch.sh

grep -Fq 'OZIRO_FRONTEND_DIR=/usr/share/oziro/shell-ui' \
  packaging/systemd/user/oziro-shell.service
grep -Fq 'Restart=on-failure' packaging/systemd/user/oziro-shell.service
grep -Fq 'systemctl --user import-environment' packaging/bin/oziro-session-start
grep -Fq 'cargo run -p oziro-shell-host' scripts/test-on-arch.sh

echo "Packaging metadata checks passed."
