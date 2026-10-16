# Time engine

## Motion and clock cadence update, 2026-10-16

Aesthetic animation is now a core goal. The boundary scheduler below governs wall-time sampling and discrete displayed values, not every animation frame. Presentation may interpolate hand positions or animate card changes using separately managed motion state. Continuous hand motion remains a design option, not an approved requirement. Reconcile animated values with current wall time after interruptions, wake, and visibility changes. The older ban on frame-rate work must not be interpreted as a ban on animation; any active frame-driven work needs a measured reason and lifecycle cancellation.

> Direction update, 2026-10-15: [Inspiration and notch bar direction](INSPIRATION.md) records the owner's latest concept and takes precedence over conflicting statements here. This document describes the earlier floating-clock baseline and needs revision before implementing the notch bar.

Status: proposed. Covers FR-001, FR-004, FR-009, FR-012, and NFR-003/NFR-004.

## Accuracy contract

The clock mirrors the Mac's wall time. It does not promise UTC accuracy, query NTP, or correct an incorrectly configured system clock. Every render samples the current `Date` once and derives time and date from that same instant. Never increment a displayed counter in response to timer ticks.

Inject a time provider for deterministic tests. Production uses the system wall clock. Monotonic timing can measure elapsed latency during tests; calendar presentation uses wall time. DST changes and manual clock jumps must not accumulate drift.

## Scheduling

Use one non-repeating `Timer` on the main run loop in common modes so dragging and menu tracking do not suspend normal updates. After each callback, obtain current time, generate display state, and schedule the next wall-clock boundary. With seconds visible, target the next whole second. Otherwise target the next minute. Compute from the current instant, not from callback count or an assumed previous delivery time.

Initial proposed timer tolerance is 50 ms in seconds mode and 100 ms in minute mode. These are budgets to measure against NFR-004, not delivery guarantees. Timers may arrive late under load. If measurements fail, first examine main-thread work and scheduling before increasing frequency.

Cancel the previous timer before scheduling a replacement. Avoid immediate-reschedule loops at exact boundaries by choosing a strictly future fire date. On late delivery, render the current time once; do not replay missed ticks. Cancel updates when hidden, asleep, or the display is sleeping. Refresh immediately on showing or waking, then realign.

`DispatchSourceTimer` offers leeway and queue control but adds ownership/cancellation concerns and a main-thread hop if used off-main. Keep it as an alternative if measurements show a concrete Timer problem. A repeating timer also avoids some drift internally, but explicit boundary rescheduling makes wall-time realignment easier to inspect. Neither timer is a real-time guarantee.

## Formatting

Use cached `DateFormatter` instances initially. `Date.FormatStyle` is a viable typed alternative, but choose one strategy rather than maintaining two production paths. Use localized templates for time fields and localized short style for date. Explicit 12/24-hour selection must remain authoritative while digits, day periods, and ordering follow locale. Validate the output for locales whose hour-cycle preferences may override formatter behavior; do not assume a template forces the requested hour cycle.

If implementation needs an explicit localized pattern to enforce FR-004, record that approach and tests in ADR-004. Do not impose a fixed POSIX locale on the user-facing date. The display calendar follows the current locale/calendar, while time zone follows system settings. The first release has no custom zone or format-string field.

Rebuild formatters on locale, calendar, time-zone, or relevant settings changes. Use a fixed locale/calendar/time zone in unit tests. Compare the time string, date string, and accessibility value before updating the view. Native monospaced digits and reserved layout width prevent width jitter without animating each tick.

## Events and recovery

| Event | Source | Action |
|---|---|---|
| System clock change | Default notification center, `NSSystemClockDidChange` | Sample current time, cancel old timer, realign. |
| Time-zone change | Default center, `NSSystemTimeZoneDidChange` | Refresh time-zone-dependent formatters and realign. |
| Locale preferences change | Default center, `NSLocale.currentLocaleDidChangeNotification` | Refresh locale/calendar formatting, relayout, and realign. |
| Sleep/wake | `NSWorkspace.shared.notificationCenter`, `willSleepNotification`/`didWakeNotification` | Cancel on sleep; refresh state and position on wake. |
| Display sleep/wake | Workspace screens-did-sleep/wake notifications | Suspend/resume display work without changing the saved user visibility preference. |
| Screen configuration | Default center, `NSApplication.didChangeScreenParametersNotification` | Reconcile placement; resume only if a display is available. |
| Show or seconds-toggle | Internal action | Refresh immediately and select the new boundary cadence. |

Use the exact Swift notification names supplied by the selected SDK. The baseline design uses established `Notification.Name` observation rather than newer typed-message APIs. DST needs no special tick arithmetic: each refresh formats the actual instant in the current time zone. Midnight updates both lines from the same sample.

## References

Checked 2026-10-15: [Timer tolerance](https://developer.apple.com/documentation/foundation/timer/tolerance), [system clock change](https://developer.apple.com/documentation/foundation/nsnotification/name-swift.struct/nssystemclockdidchange), [time-zone change](https://developer.apple.com/documentation/foundation/nsnotification/name-swift.struct/nssystemtimezonedidchange), [workspace wake](https://developer.apple.com/documentation/appkit/nsworkspace/didwakenotification), [screen configuration change](https://developer.apple.com/documentation/appkit/nsapplication/didchangescreenparametersnotification). Installed Foundation headers confirm the legacy clock and time-zone notifications. Availability of an event does not establish how soon it will be delivered under load.
