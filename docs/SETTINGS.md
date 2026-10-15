# Settings and persistence

> Direction update, 2026-10-15: [Inspiration and notch bar direction](INSPIRATION.md) records the owner's latest concept and takes precedence over conflicting statements here. This document describes the earlier floating-clock baseline and needs revision before implementing the notch bar.

Status: proposed defaults. Covers FR-006 to FR-008 and FR-013. Appearance specifications are in [UI and UX](UI_UX.md).

## Configuration contract

| Setting | Default | Validation and behavior |
|---|---|---|
| Hour format | 24-hour | Enum with 12-hour and 24-hour choices. Invalid stored value restores 24-hour. |
| Show seconds | Off | Boolean. Immediately changes scheduling cadence and reserved text width. |
| Show date | Off | Boolean. Adds one localized short-date line. |
| Font | System, medium weight, monospaced digits | Persist system choice or installed font PostScript name. Missing font falls back to system. Do not assume custom fonts support monospaced digits. |
| Preferred text size | 48 points | Finite value from 20 to 160 points. Clamp finite out-of-range values; reject NaN/infinity. Effective size may shrink to fit a small display. |
| Text opacity | 1.0 | Finite value from 0.3 to 1.0. Apply to text content, not the settings window or menu. |
| Text color mode | Automatic | Automatic, light, dark. Automatic follows system appearance; it cannot inspect wallpaper or promise contrast against every window. |
| Position | Top-right, 16-point margin | Display hint and normalized offsets, validated and clamped by ScreenPlacement. See Window management. |
| Launch at login | Off | Actual OS registration status is authoritative, not a stored Boolean. |
| Clock visibility | Shown on launch | Session-only state; Hide does not cause an invisible restart. |

Only these controls belong in the first release. Theme packs, custom color editors, custom date patterns, global shortcuts, click-through mode, and per-display instances require separate scope decisions.

## Persistence design

Use a namespaced, versioned settings representation in `UserDefaults`, initially schema version 1. Keep serialization in the store rather than controllers. Use explicit defaults and validate each field independently so one corrupt value does not discard valid preferences.

Apply changes in memory immediately. Coalesce rapid slider changes and save after roughly 300 ms of inactivity; persist drag position on mouse-up. Finish pending saves before ordinary termination. UserDefaults is not a transactional database or secure secret store. A forced kill may lose the final pending edit, which must not corrupt subsequent startup.

Reject unsupported future schema versions without overwriting the saved representation. Run with safe defaults and show a non-blocking explanation in Settings. Add migrations only when a schema changes; preserve fixtures for older schemas. Do not call `synchronize()` repeatedly or write on clock ticks.

Reset Appearance restores format and visual controls. Reset Position changes placement only. Neither action changes login registration. There is no blanket Reset All action in the initial design, avoiding an ambiguous interaction with OS-controlled login state.

## Login integration

Use `SMAppService.mainApp` after a deliberate toggle. Query status when Settings opens and after registration/unregistration completes. Distinguish enabled, not registered, approval required, and service unavailable/not found. Catch errors, display an actionable message, and leave the control consistent with actual status.

When approval is required, offer Apple's Login Items settings entry point. Do not retry registration on every launch or force a disabled setting back on. A checkbox showing the user's intent is insufficient if OS approval remains pending. Test changes made externally in System Settings.

Validate from a stable, installed app bundle with the intended signing configuration. Xcode-run behavior alone is not release evidence. No separate launch daemon, privileged helper, or custom LaunchAgent is proposed.

## References

Checked 2026-10-15: [SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice), [register](https://developer.apple.com/documentation/servicemanagement/smappservice/register()), [deprecated SMLoginItemSetEnabled](https://developer.apple.com/documentation/servicemanagement/smloginitemsetenabled(_:_:)). Apple documents the modern service APIs for macOS 13 onward. This design does not use the deprecated helper registration API.
