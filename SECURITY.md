# Oziro Security Baseline

## Current status

This document defines the baseline for the foundation scaffold. It is not a claim that Oziro has completed a security audit.

## Required principles

- Oziro Shell must run as the logged-in user, never as root.
- Do not use `sudo` as an application dependency.
- Never pass frontend-provided strings to a shell.
- Use typed, allow-listed operations across the native bridge.
- Validate every request at the Rust boundary.
- Keep D-Bus permissions and service access minimal.
- Use Polkit only for operations that genuinely require authorization.
- Store user configuration with restrictive, user-owned permissions.
- Do not silently rewrite Hyprland or other desktop configuration.
- Avoid logging secrets, tokens, or sensitive system data.

## Threat boundaries

Treat the following as untrusted:
- UI input
- application metadata
- D-Bus responses
- compositor IPC responses
- configuration files that may have been edited externally

## Reporting

For a security issue, include severity, affected component, reproduction steps, impact, and a proposed mitigation. Do not publish exploit details for an unresolved vulnerability.
