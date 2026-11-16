#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

for command in npm cargo; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Required command not found: $command" >&2
    exit 1
  fi
done

echo "== Frontend: typecheck =="
npm run typecheck

echo "== Frontend: lint =="
npm run lint

echo "== Frontend: tests =="
npm run test

echo "== Frontend: production build =="
npm run build

echo "== Rust: formatting =="
cargo fmt --all -- --check

echo "== Rust: clippy =="
cargo clippy --workspace --all-targets -- -D warnings

echo "== Rust: tests =="
cargo test --workspace

echo "Oziro foundation verification completed."
