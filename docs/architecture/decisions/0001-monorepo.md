# ADR 0001: Modular Monorepo

- **Status:** Accepted for foundation
- **Date:** 2026-11-09

## Context

Oziro has a Rust system layer and a React/TypeScript UI. They need independent build and test workflows while remaining easy to develop together.

## Decision

Use one Git repository with:
- npm workspaces for frontend packages
- Cargo workspace for Rust crates and applications
- explicit integration directories for Linux/compositor adapters
- shared, versioned protocol concepts mirrored in Rust and TypeScript

## Consequences

- Frontend and Rust can be built independently.
- System integration is isolated from presentation.
- The protocol transport is not prematurely selected.
- A future split into separate repositories remains possible if operational needs justify it.
