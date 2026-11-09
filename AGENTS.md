# Oziro Desktop - Agent Instructions

## Project Identity
Oziro Desktop is an independent Linux Desktop Environment.
It is not a theme, rice, or a collection of desktop configurations.

## Core Principles
1. Ease of use.
2. User freedom and customization.
3. Performance and responsiveness.
4. Reliability and security.
5. Consistent and original visual design.

## Initial Platform
- Arch Linux
- Wayland
- Hyprland as the initial compositor

## Preferred Technologies
- React
- TypeScript
- Rust
- D-Bus
- Hyprland IPC

Technology choices must be evaluated before implementation.
Do not introduce unnecessary dependencies.

## Engineering Rules
- Inspect existing files before modifying them.
- Never overwrite user files without permission.
- Never run destructive commands without explicit approval.
- Never use sudo unnecessarily.
- Never fake hardware functionality.
- Handle unsupported hardware gracefully.
- Keep components modular and testable.
- Document architectural decisions.
- Run tests after meaningful changes.
- Do not claim success without verification.

## Development Workflow
Before implementing a major feature:
1. Inspect the current architecture.
2. Explain the proposed changes.
3. Identify affected components.
4. Implement incrementally.
5. Run tests.
6. Report results and limitations.

## Performance
- Avoid unnecessary background processes.
- Minimize CPU and RAM consumption.
- Avoid unnecessary rendering.
- Make visual effects optional.
- Support reduced-motion and low-effects modes.

## Collaboration
Multiple agents may work on this repository.
Avoid modifying files owned by another agent without coordination.
Use Git branches or worktrees for parallel development.

## Documentation
Keep PROJECT_CONTEXT.md updated whenever architecture,
technical decisions, project status, or milestones change.

## Important
The existing desktop environment must never be replaced
or modified as part of ordinary development tasks.
