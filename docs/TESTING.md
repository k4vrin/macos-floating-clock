# Testing and verification

## Visual and motion acceptance, 2026-10-16

Include design review against the saved references and primary aesthetic goal. Review the chosen face, compact/expanded compositions, materials, and interaction feedback at actual display scale. A technically correct generic clock is not sufficient for the stated product intent.

Exercise expansion/collapse and face switching, including rapid reversal, repeated activation, display changes mid-transition, and sleep/wake. Check clipping, flicker, discontinuities, input responsiveness, and Reduce Motion behavior. Measure frame pacing, main-thread work, and energy during transitions separately from steady idle. Confirm animation work stops after completion and when hidden/asleep. Exact motion budgets need definition after the first prototype; do not report an unmeasured smoothness guarantee.

> Direction update, 2026-10-15: [Inspiration and notch bar direction](INSPIRATION.md) records the owner's latest concept and takes precedence over conflicting statements here. This document describes the earlier floating-clock baseline and needs revision before implementing the notch bar.

Status: strategy only. No tests, runtime checks, performance samples, or rendered diagrams have been executed for an application in this project.

## Test layers

Use XCTest for deterministic logic and persistence tests. Add AppKit integration tests for controller lifecycle and update propagation. UI automation may cover Settings where stable; manual evidence remains necessary for cross-app focus, Spaces, login, and accessibility behavior.

| Area | Required cases |
|---|---|
| Time/formatting | Midnight, noon, 23:59, leap day, month/year rollover, seconds on/off, date on/off, explicit 12/24-hour format |
| Locale/calendar | At least en_US, en_GB, de_DE, fa_IR, ar_SA, and ja_JP; long day-period strings, non-Latin digits, current-calendar behavior |
| DST/time zone | Fixed fixtures on both sides of spring-forward and fall-back in a DST-observing zone; time-zone changes across midnight; manually adjusted wall clock |
| Scheduler | Exactly one active timer, cancellation, delayed delivery skips missed ticks, strictly future boundary, refresh after hidden/wake, no tick writes to defaults |
| Settings | Missing fields, wrong types, NaN/infinity, invalid enums, missing font, schema migration, unsupported future version, burst slider edits |
| Geometry | Negative screen origins, zero travel range, tiny usable area, long text, missing display UUID, changed scale, disconnect during drag |
| Lifecycle | First launch, relaunch, Settings close, hidden clock, Quit, sleep, display sleep, wake, menu tracking during boundary updates |

Keep time-zone and locale fixtures explicit. Never make deterministic tests depend on today's date or the test machine's settings. Simulated time tests prove formatting and state transitions; they do not prove actual wake notifications or display timing.

## Manual environment matrix

Record actual model, architecture, OS version/build, Xcode/SDK, source revision, signing, and display configuration for each run. Primary hardware is the 14-inch M1 Pro MacBook Pro. Owner's installed OS is not yet recorded.

Test the proposed minimum macOS 13 release and the current supported development OS before claiming both. If minimum-version hardware/VM testing is unavailable, mark that support unverified or revise the declared minimum. Intel is outside the first evidence target unless the owner requests it.

Test built-in display alone, external alone where possible, mixed Retina/non-Retina displays, and monitors placed left/right/above. Include mirrored mode, scaled resolution, Dock positions, auto-hide, clamshell/disconnect, and camera-housing clearance.

For window behavior, use ordinary Finder, Safari, and a text editor. Verify typed text still enters the prior app after dragging the clock. Add full-screen Safari and another app, Mission Control transitions, Stage Manager on/off, and separate display Spaces on/off. Where a system option needs sign-out to apply, apply it before recording results. Record conditional failures instead of treating a single successful configuration as universal.

Run keyboard-only settings and menu actions, VoiceOver on-demand reading, increased contrast, and Reduce Motion. If permission prompts appear, record the exact trigger and investigate against NFR-011.

## Performance protocol

Build Release, run outside the debugger, and wait two minutes for warm-up. Fix wallpaper, display brightness, refresh/scaling, power source, Low Power Mode, and foreground workload. Record ambient background load and thermal state. Use the same tool and metric definitions across comparisons.

1. Collect three 10-minute idle samples each for app-off baseline, minute mode, and seconds mode. Use Instruments Time Profiler/System Trace and Activity Monitor as appropriate. Report CPU mean/p95, timer wakeups, formatting calls, and changed-state redraw counts. Setup notifications and interaction can cause additional updates; distinguish these from steady-state cadence.
2. Record physical footprint at minutes 2 and 30. Use Allocations/leak inspection if growth exceeds the proposed threshold. Keep footprint and RSS labels separate.
3. Log intended boundaries and callback times for at least 120 seconds-mode and 20 minute-mode boundaries. An internal callback timestamp cannot prove visible presentation. Use an externally recorded display with a synchronized reference or another calibrated presentation measurement, record its temporal resolution, and state uncertainty. Debug instrumentation may change performance, so report that build separately.
4. Repeat sleep/wake and hide/show transitions ten times. Count active timers after recovery and inspect the first refreshed value. Measure event-delivery-to-refresh separately from time spent asleep or blocked by the OS.
5. Measure ten cold and ten warm startups and twenty changes per settings control. Define cold trials by a documented cache condition; do not call ordinary relaunches cold. Capture input-to-presentation latency and main-thread stalls.

Energy impact is relative evidence. Run at least three comparable 30-minute battery sessions for app-off, minute mode, and seconds mode with controlled workload and brightness. Record wakeups, CPU and Instruments energy indicators, and battery change with its noise. Do not convert Activity Monitor Energy Impact into watts or promise hours of battery life from short samples. If the difference is below measurement resolution, say so.

## Login and installation tests

Use the intended signed installed bundle at a stable location. Enable login startup, sign out/in, verify one instance, disable it, and repeat. Check approval-required state, registration errors, and changes made in System Settings. Confirm login launch shows the clock without opening Settings or stealing typing focus. Signing/notarization checks depend on the chosen distribution channel and belong in M5.

## Evidence record and release gate

For every acceptance run, record requirement ID, environment, procedure, expected result, actual result, pass/fail/unverified, source revision, and artifact location. Keep large traces and generated builds outside the vault; store concise summaries and safe links here if later requested.

M5 cannot pass solely on deterministic tests. It needs actual AppKit behavior, multi-display recovery, login, accessibility, and performance evidence. A proposed budget may change only through a documented decision backed by measurements. Open full-screen limitations need explicit product review before release claims.

## Adaptive compact geometry

See [COMPACT_GEOMETRY.md](COMPACT_GEOMETRY.md) for geometry regression coverage, connected-display observations, performance samples, and remaining hardware checks.

## Settings and theme plugins, 2026-10-16

- Final `swift test`: 24 tests passed, including preferences persistence, stable monitor selection and disconnection fallback, theme-only/legacy pack decoding, duplicate theme IDs, invalid RGB values, explicit 12/24-hour formatting, and theme retention after clock replacement.
- Native UI: selected external G27F (22-point compact band, no cutout), restored the built-in Retina display (32-point band, 185-point cutout), installed Tide Pool through the file picker, selected Sea glass, and expanded the themed clock. A subsequent app launch restored the monitor and theme.
- Native Settings window includes monitor, clock, widget, theme, 24-hour time, reduced animation, and start-expanded controls. Closing Settings keeps the clock running. Clock replacement and preference toggles were also exercised from the window.
- Existing 72-second performance probe, built-in Retina display and Sea glass theme: mean CPU as a percentage of one core was 1.575 compact, 1.644 expanded, 11.074 during repeated transitions, and 0.484 after recovery to compact. Peak RSS was 95.188 MiB; peak physical footprint was 67.767 MiB. These short measurements include live provider refreshes and are not long-term memory-leak or idle benchmarks. The final time-label formatting fix adds no timers or rendering cadence changes.
- Older macOS releases and physical display disconnection/reconnection remain manual hardware checks. Theme loading is JSON-only; arbitrary executable plugins are not supported.
