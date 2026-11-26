# Decision log

| ID | Decision | Rationale / tradeoff |
|---|---|---|
| D01 | Native QML/Quickshell over prior web shell for active v2 | Less runtime complexity and resource overhead goal; actual savings require benchmarks |
| D02 | Niri first, adapters not custom compositor | Existing verified environment and Wayland IPC; independence is product integration, not replacing every dependency |
| D03 | On-demand popups and stable keyed models | Reduce resident work and delegate churn |
| D04 | Energy policy from real UPower state | Unknown is explicit; avoid inaccurate battery claims |
| D05 | Hyprlock/PAM, no custom password collector | Actual session lock, established auth; automatic sleep/idle still blocked |
| D06 | Nested preview for UI | No repeated logout, settings temporary; not an isolation/security boundary |
| D07 | Preserve Ryoku and use experimental SDDM entry | Safe return; wrapper/system services still partly shared |
| D08 | Oziro mark and coordinated local art | Original identity, approved direction at 0.9.17; no copied Apple assets |
| D09 | Fixed dock hit targets and transform-only wave | Predictable clicks, bounded motion; transparent headroom input masked, runtime must be checked |
| D10 | Explicit confirmation and logind for power | Respect system authorization; no force or sleep until safe |
| D11 | Living handbook and evidence labels | Avoid relying on chat history or conflating code with testing |

Revisit decisions if measured evidence or user feedback contradicts assumptions. Record rationale and migration impact.
