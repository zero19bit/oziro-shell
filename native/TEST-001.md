# User-reported baseline, 2026-11-26
Arch / Ryoku, Niri 26.04. Foundation 0.1. Nine of eleven checks passed; workspace unsupported in the original Hyprland-only backend, battery UI unconfirmed. Panel layout works. UPower detects a physical and aggregate battery.

One process smaps_rollup: RSS 349996 KiB, PSS 231836 KiB, private clean + dirty 207732 KiB, swap 0. Five top readings (2s interval): 0, 0, 0, 0.5, 0 percent CPU. Short sample only, not a battery or GPU measurement. No memory savings demonstrated by Foundation 0.2 yet.

Retest: switch Niri workspaces via keyboard and panel, including two outputs if possible; verify battery and AC transition; sample PSS after fresh launch, after opening and closing popups, and after 60 seconds idle. Run benchmark.sh with the current Oziro PID, not the Ryoku PID. Record Quickshell version and exact log. Do not change power limits or compositor config during baseline.
