# Settings and persistence

Implemented in the AppKit prototype on 2026-10-16. Open **Settings…** from the status-item menu or by right-clicking either compact component. Changes apply immediately and are stored in the app's `UserDefaults` domain.

| Control | Default | Behavior |
|---|---|---|
| Display | Built-in display preferred | Choose the laptop, follow the active display, or select a connected monitor by name. Specific monitors are stored by Core Graphics display UUID. A disconnected choice falls back to the built-in display, then the first available screen; its saved UUID remains unchanged so reconnection restores placement. |
| Clock | The Wavy One | All installed clock designs appear here. |
| Right side | The Daily One | Choose the date card, AI usage, or an installed widget. Existing selection persists across upgrades. |
| Theme | Original objects | Three bundled palettes, plus installed theme plugins. Changes affect the shell, analog and digital clocks, date card, and usage widget. Original objects preserves each design's accent. |
| Use 24-hour time | On | Updates the expanded time label, digital faces, and clock accessibility labels. Analog hands retain the same instant. Twelve-hour digital tiles show four digits; the expanded label identifies AM/PM. |
| Reduce animations | Off | Removes expansion/collapse motion. The macOS Reduce Motion preference always takes precedence. |
| Start expanded | Off | Starts with the expanded clock on the next normal launch. Closing Settings leaves the app running. |
| Install theme or clock pack | Action | Imports a validated local JSON manifest through the existing pack store. Select the installed theme or component after installation. |

The display diagnostic shows the screen actually chosen, its resolved compact height, and the notch gap. On the connected 14-inch MacBook Pro, native APIs report a 32-point menu band and a 185-point cutout gap at the current scaling. The external G27F reports no top reservation and uses the 22-point fallback. Monitor selection now controls which geometry is used rather than inheriting the screen on which the app happened to launch.

## Implementation

- `AppPreferences.swift` owns settings persistence and monitor selection/fallback. Display selection is independent of `panel.screen`, so a selected display remains authoritative across geometry notifications.
- `SettingsWindowController.swift` owns the native controls and palette preview. It calls narrow callbacks on the app delegate rather than repositioning windows or reading provider credentials itself.
- `ThemeDesign.swift` defines validated theme data and per-view AppKit palettes. There is no shared mutable global theme and no added timer.
- `AppDelegate` applies settings, captures the selected display's native geometry, updates the existing clock views, and refreshes the controls after display or pack changes.
- `MenuBarGeometry.swift` retains responsibility for measured heights, cutout bounds, auto-hide fallbacks, and top-anchored frames. See [Compact geometry](COMPACT_GEOMETRY.md).

Theme plugins use the same local pack directory as clocks and widgets. See [Theme plugins](THEME_PLUGINS.md) for the manifest and example. A missing theme uses Original objects until its manifest becomes available again; its saved key is retained. Invalid or duplicate imported packs are rejected without replacing existing files.

## Scope and remaining checks

This settings window does not implement launch-at-login registration, arbitrary fonts, a manual compact-height override, or multiple simultaneous clock panels. Previous floating-clock settings proposals are superseded by the implemented controls above. Older macOS versions and physical monitor disconnect/reconnect remain manual hardware checks; fallback/selection behavior is covered by deterministic tests.

## Hover-only expansion

Expansion now follows pointer presence. Start expanded is removed from Settings, and legacy saved values are ignored. Clicks do not latch the panel open. Leaving the panel collapses it automatically after a brief exit grace, with menu tracking temporarily preserving the panel while a submenu is open. Reduce animations also disables the spatial morph.
