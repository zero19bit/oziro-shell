# Foundation 0.3 — user-reported memory baseline
Arch/Ryoku, Niri, 2026-11-26. PID 203508, 60 samples per phase.
Cold: mean PSS 159.0 MiB, min 157.2, max 160.2; CPU approx 0.24% of one core.
Warm: mean PSS 184.8 MiB, min 157.2, max 205.3; CPU approx 4.56% of one core.
Prior 0.1 single PSS snapshot 226.4 MiB; comparison is not a controlled A/B test. Warm workload not independently verified. Functional persistence checklist not yet returned. No GPU or battery measurement.
0.4: compare dock disabled and enabled, both after 60s without input, then warm idle after popups closed. Test pinned launches, unpin, running indicators, Niri focus, and persistence. Do not treat missing functionality on Hyprland as supported. Dock disabled by default.
