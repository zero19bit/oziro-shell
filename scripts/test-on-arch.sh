#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

MODE="${1:---launch}"
case "$MODE" in
  --launch) LAUNCH=1 ;;
  --check-only) LAUNCH=0 ;;
  -h|--help)
    cat <<'HELP'
Usage: bash scripts/test-on-arch.sh [--launch|--check-only]

  --launch      Run all checks, build Oziro, then launch the native Wayland shell.
  --check-only  Run all checks and build, but do not open desktop surfaces.
HELP
    exit 0
    ;;
  *)
    echo "Unknown option: $MODE" >&2
    exit 2
    ;;
esac

if (( EUID == 0 )); then
  echo "Do not run Oziro as root. Run this script as your desktop user." >&2
  exit 1
fi

if (( LAUNCH == 1 )) && [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
  echo "No active Wayland session detected." >&2
  echo "Log in to Hyprland or KDE Wayland, or use --check-only." >&2
  exit 1
fi

STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
LOG_DIR="$STATE_HOME/oziro"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/test-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "============================================================"
echo " Oziro Arch test"
echo " Repository: $ROOT_DIR"
echo " Mode: $MODE"
echo " Log: $LOG_FILE"
echo "============================================================"

missing_commands=()
for command in node npm cargo rustc pkg-config; do
  if ! command -v "$command" >/dev/null 2>&1; then
    missing_commands+=("$command")
  fi
done

if (("${#missing_commands[@]}" > 0)); then
  printf 'Missing commands: %s\n' "${missing_commands[*]}" >&2
  echo "Install the Arch build dependencies with:" >&2
  echo "sudo pacman -S --needed base-devel git nodejs npm rust pkgconf gtk4 webkitgtk-6.0 gtk4-layer-shell libpulse" >&2
  exit 1
fi

if ! node -e 'const [major, minor] = process.versions.node.split(".").map(Number); process.exit(major > 20 || (major === 20 && minor >= 19) ? 0 : 1)'; then
  echo "Node.js 20.19 or newer is required. Current: $(node --version)" >&2
  exit 1
fi

missing_pkgconfig=()
for package in gtk4 webkitgtk-6.0 gtk4-layer-shell-0 libpulse; do
  if ! pkg-config --exists "$package"; then
    missing_pkgconfig+=("$package")
  fi
done

if (("${#missing_pkgconfig[@]}" > 0)); then
  printf 'Missing native development libraries: %s\n' "${missing_pkgconfig[*]}" >&2
  echo "Install the Arch packages with:" >&2
  echo "sudo pacman -S --needed gtk4 webkitgtk-6.0 gtk4-layer-shell libpulse pkgconf" >&2
  exit 1
fi

echo
echo "== Toolchain =="
node --version
npm --version
rustc --version
cargo --version
cargo fmt --version
cargo clippy --version

echo
echo "== Frontend dependencies =="
npm ci --no-audit --no-fund

echo
echo "== Frontend typecheck =="
npm run typecheck

echo
echo "== Frontend lint =="
npm run lint

echo
echo "== Frontend tests =="
npm run test

echo
echo "== Frontend production build =="
npm run build

echo
echo "== Rust formatting =="
cargo fmt --all -- --check

echo
echo "== Rust Clippy =="
cargo clippy --workspace --all-targets -- -D warnings

echo
echo "== Rust tests =="
cargo test --workspace

echo
echo "== Native shell build =="
cargo build -p oziro-shell-host

echo
echo "============================================================"
echo " Oziro build and checks passed."
echo " No desktop configuration or system package was changed."
echo "============================================================"

if (( LAUNCH == 0 )); then
  echo "Check-only mode complete. The native shell was not launched."
  exit 0
fi

echo
echo "Starting Oziro on the current Wayland session."
echo "The panel and dock will appear over your current desktop."
echo "Press Ctrl+C in this terminal to stop Oziro."
exec cargo run -p oziro-shell-host
