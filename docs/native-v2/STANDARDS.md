# Engineering and design standards

## Code
- Keep components small, required properties explicit and signals narrow. Use stable IDs for models. No arbitrary command construction from user input.
- Pure imported QML JS uses conservative ES5-compatible syntax; avoid object spread. Validate all external paths, manifests and settings.
- Add new runtime files to native/install.sh, native/preflight.sh and native/login-session-install.sh as appropriate. Use local assets with clear provenance.
- Handle absent hardware/services gracefully; no invented metrics. Keep logs actionable and free of secrets.
- Preserve backwards-compatible preference keys, explicit migrations, atomic writes and recovery for invalid config.

## UX
- Approved direction: Midnight/Graphite/Aurora/Porcelain, own mark, understated macOS-inspired interaction. Do not copy Apple assets.
- Consistent spacing (4/8px rhythm), typography, icon stroke, contrast and keyboard focus. No decorative cards, marketing copy, gratuitous gradients or oversized labels.
- Top bar compact (32 logical px default), status icons with accurate labels and tooltips; icon-only controls need accessible names.
- Dock motion: short, local, reversible, stable click targets; user toggle and Eco override. Avoid infinite animation, constant repaint and software blur.
- Target WCAG-style 4.5:1 normal text contrast and 3:1 large text/meaningful UI where practical; actual contrast audits pending. Provide keyboard access, non-color status cues, readable scaling and reduced motion.

## Performance
- Short-run target: main process settled PSS <=170 MiB, idle CPU <0.5% of one core on reference machine. These are provisional goals, not current certified results.
- Long-term ambition: <100 MiB shell PSS where feasible without sacrificing correctness; not a hard release promise.
- Event-driven by default, bounded reconciliation only with justification, on-demand surfaces, no new daemon/poll loop without evidence. Measure process tree, GPU, idle/warm/interactive and actual battery before claiming savings.
- Record hardware, versions, sample interval, active features, context and variance. Compare like-for-like.
