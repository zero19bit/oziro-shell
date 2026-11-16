# Contributing to Oziro

## Engineering rules

- Keep modules small and responsibility-focused.
- Use strict TypeScript and Rust formatting.
- Do not access Linux services from React components.
- Do not execute arbitrary shell commands from frontend input.
- Do not report mock or preview values as live system state.
- Do not silently modify user configuration.
- Add tests for behavior and error paths.
- Document architectural decisions in `docs/architecture/decisions/`.

## Frontend

```bash
npm install
npm run dev
npm run typecheck
npm run lint
npm run test
npm run build
```

## Rust

```bash
cargo fmt --all -- --check
cargo clippy --workspace --all-targets -- -D warnings
cargo test --workspace
```

## Changes

Prefer small, reviewable changes. Do not combine unrelated features. Update documentation when a public interface or architectural boundary changes.
