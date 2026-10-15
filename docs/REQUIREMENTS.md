# Requirements and acceptance criteria

> Direction update, 2026-10-15: [Inspiration and notch bar direction](INSPIRATION.md) records the owner's latest concept and takes precedence over conflicting statements here. This document describes the earlier floating-clock baseline and needs revision before implementing the notch bar.

Status: proposed. IDs are stable. Changing a criterion requires an entry in [Decisions](DECISIONS.md). Core means M1 to M3; release adds M4 and M5. M0 validates feasibility first.

## Functional requirements

| ID | Stage | Requirement and acceptance criterion |
|---|---|---|
| FR-001 | Core | Display local system time. Given an injected instant, locale, calendar, and time zone, the displayed time matches the fixture. Production reads `Date` rather than accumulating elapsed ticks. |
| FR-002 | Core | Float above ordinary windows. Switching and typing in at least three other apps leaves the clock visible and preserves the input target. See the environment matrix in Testing. |
| FR-003 | Core | Use a transparent, borderless panel. No title bar or resize controls appear; pixels outside the clock content are transparent. |
| FR-004 | Core | Support explicit 12-hour and 24-hour modes. Midnight, noon, and 23:59 render correctly; 12-hour mode includes a localized day period. Relaunch preserves the choice. |
| FR-005 | Core | Allow dragging between displays without activating the clock app. Releasing the drag stores a reachable position; Reset Position restores the default on an available display. |
| FR-006 | Core | Provide installed-font selection, size, text opacity, and automatic/light/dark text modes. Invalid values fall back to documented defaults and previews never clip the supported strings. |
| FR-007 | Core | Maintain a menu-bar item with Show/Hide Clock, Settings, Reset Position, and Quit. Each action works when the clock is hidden; Settings can become key for keyboard entry. |
| FR-008 | Core | Persist validated settings and placement. A fresh install, ordinary restart, missing font, and malformed stored data all produce a usable clock without a crash. |
| FR-009 | Core | Recover after sleep, display sleep, clock adjustment, time-zone or locale change. The next refresh uses current system state and only one update timer remains active. See NFR-004. |
| FR-010 | Core | Support display attachment, removal, resolution changes, and mixed scaling. The full panel stays inside the chosen usable frame, including after its preferred display disappears. |
| FR-011 | Core | Request all-desktop-Spaces visibility. M0 records behavior with separate display Spaces and Stage Manager. Record full-screen results separately; known unsupported contexts must not be presented as guaranteed support. |
| FR-012 | Release | Allow optional seconds and optional localized short date. Both default off. Hiding seconds changes scheduling to minute boundaries; midnight updates the date. |
| FR-013 | Release | Offer opt-in launch at login. Default off; show actual `SMAppService` state, registration errors, and approval-needed state. Installed-app login and subsequent disabling pass real sign-out/sign-in tests. |
| FR-014 | Core | Hide on request for the current session and show through the menu bar. Relaunch shows the clock. Quit removes the panel and status item and terminates the process. |

## Non-functional requirements

These are proposed engineering budgets, not measured results. Measurements use a Release build outside the debugger after warm-up, except responsiveness tests. Testing defines sampling and artifacts.

| ID | Proposed target | Acceptance and measurement |
|---|---|---|
| NFR-001 | Mean process CPU below 0.5% without seconds and below 1.0% with seconds | Three 10-minute idle runs per mode on M1 Pro. Use macOS process CPU convention, where 100% is one logical core. Report mean and p95 plus background load. |
| NFR-002 | Physical footprint at or below 60 MiB; no continuing growth | Record the chosen Instruments physical-footprint metric at minute 2 and minute 30. Growth above 5 MiB after warm-up requires investigation. Report RSS separately if collected; do not substitute metrics silently. |
| NFR-003 | No display-rate loop; one scheduled clock timer at most | Instrument timer creation, cancellation, and redraws. One update per second or minute during steady visible operation. Hidden and sleeping clock has no scheduled display updates. Wake tests check cancellation/recreation. |
| NFR-004 | Display-boundary lateness p95 at or below 250 ms and max at or below 1 s under idle load | Sample at least 120 second boundaries and 20 minute boundaries. Measure actual presentation where possible, plus callback latency separately. After wake/system-change delivery, refresh within 1 s while runnable. Busy-system and sleeping intervals are reported separately. |
| NFR-005 | First clock visible within 1 s for warm launch and 2 s for cold launch | Ten trials each; measure process start to first presented clock, report median/p95 and cache conditions. The targets apply to the reference Mac. |
| NFR-006 | Settings feedback p95 below 100 ms | Twenty changes each for size, format, opacity; measure input to visible update. No main-thread stalls above 100 ms attributable to the app during normal dragging. |
| NFR-007 | Complete essential keyboard and VoiceOver access | Settings and all menu actions have meaningful labels and keyboard operation. VoiceOver reads current clock/date on demand without announcing every tick. Reduced-motion mode has no decorative movement. |
| NFR-008 | Reachable, legible output across supported displays | Run primary, external, left/right/above layouts, Retina/non-Retina, and scaled resolutions. Check text sharpness, no clipping, and full-frame recovery after unplug. |
| NFR-009 | Explicit compatibility claims | Proposed macOS 13 minimum. Build against that deployment target; record tested OS/build versions. An untested OS is marked unverified, even if API availability permits it. |
| NFR-010 | Battery impact measured before any claim | Compare app-off, minute mode, and second mode in controlled runs. Report CPU, wakeups, and energy indicators. There is no credible battery-hours guarantee yet. |
| NFR-011 | Local operation without sensitive permissions | Offline clock operation passes. Fresh-install tests prompt for no Accessibility, Screen Recording, or Input Monitoring grants. Login registration may require OS approval. No telemetry or network dependency. |

## Traceability

M1 validates FR-001 to FR-004 and FR-007. M2 covers FR-005, FR-008 to FR-011. M3 covers FR-006 and NFR-007. M4 adds FR-012 and FR-013. M5 verifies the full register, including FR-014 and all NFRs. M0 provides early evidence for FR-002, FR-003, FR-005, FR-011, and NFR-011.
