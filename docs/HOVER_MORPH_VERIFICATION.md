# Hover morph verification

Recorded 2026-10-17 on the development Mac, a 14-inch MacBook Pro with M1 Pro. This change sits above the Wavy numeral PR. It has no new package dependencies.

## Checks

- 32 Swift tests pass. New cases cover reversible spring state, settling to both endpoints, keeping one instance of each view throughout the transition, theme preservation after replacement, notch hit exclusion, and window top anchoring on an external-display geometry with a negative horizontal origin.
- Release packaging and ad-hoc signing succeed.
- Native Wavy and Counter previews reviewed at five transition positions for both right-side items. A calendar label collision found at 50% was corrected. The analog mount now rounds into the full circular housing instead of leaving a square mounting edge.
- Live panel checked on the built-in notched display: entry into the left wing expands; leaving into the non-interactive notch region collapses automatically. The expanded panel contains the same two objects and no duplicate compact row.
- Native motion GIF uses the same spring and views with fixed sample time. Usage stills contain synthetic account data. These are renderer previews, not recordings of pointer input.

## Resource probe

The opt-in `--performance-probe` sampled the release executable once per second for 72 seconds. It exercised 20 seconds compact, 20 seconds expanded, 12 seconds of repeated target changes, and 20 seconds recovered compact. CPU percentages refer to one core. The probe ran before the final housing-radius and analog-marker cosmetic corrections; final packaging and unit checks include those corrections.

| Phase | CPU mean, all samples | CPU mean after first 3 phase samples | Peak RSS |
| --- | ---: | ---: | ---: |
| Compact | 1.447% | 0.377% | 79.5 MiB |
| Expanded | 2.042% | 0.446% | 94.7 MiB |
| Repeated morphs | 18.887% | 19.586% | 96.9 MiB |
| Recovered compact | 1.378% | 0.364% | 97.9 MiB |

The highest one-second CPU sample was 25.467% during repeated morphs. Recovered compact ended at 90.2 MiB RSS and 47.3 MiB physical footprint. Allocator and graphics caches retain some memory after transitions; this short run does not establish long-term leak behavior. Transition work stops at rest. Raw measurements remain local in ignored `output/hover-morph-performance.csv`.

## Remaining manual coverage

Physical external-display reconnection, other macOS versions and scaling configurations, prolonged hover stress, live Reduce Motion changes, and VoiceOver-only operation need additional manual coverage. Geometry tests do not substitute for every physical display. Hover-only expansion intentionally removes click/keyboard latching.
