# Adaptive compact menu-bar sizing

`MenuBarGeometry.swift` owns display measurements and panel frames. `AppDelegate` captures the panel's current screen, coalesces display/backing/Space/presentation changes, and applies a frame only when geometry changes. Placement now follows the saved monitor choice in Settings, defaulting to the built-in display. Follow active display is an explicit option; specific monitors are selected by UUID, with built-in/first-screen fallback after disconnection. Existing clock ticks also recheck geometry, without a new polling timer.

The measured height is `screen.frame.maxY - screen.visibleFrame.maxY`, in points. This excludes bottom/side Dock reservations. A notched display also constrains the height with `safeAreaInsets.top`; the auxiliary top areas locate the physical cutout so clock and widget content stay on its sides. Heights round down to backing pixels. Existing horizontal padding, component widths, and expanded body height remain unchanged.

When auto-hide removes the top reservation or leaves only a one-pixel reveal strip, the resolver uses the last measured height for the same display, frame, and scale. If unavailable, it uses the native notch safe inset, the status-item window height only when that window belongs to this display and touches its top edge, then global status-bar thickness as a last resort. It keeps a stable compact band while the system menu is hidden. Missing auxiliary areas on an otherwise notched screen hide the panel until geometry is valid.

AppKit does not expose a separate per-display hidden menu-bar height. On a plain display first encountered with auto-hide enabled, a status-item/global fallback may remain approximate until the menu bar supplies a measurable reservation. Hover reveal is not treated as a command to animate the app's height. Geometry is rechecked on native notifications and the existing clock cadence. Very narrow displays clip the original component layout rather than moving content into the cutout.

## Verification on 2026-10-16

- `swift test`: 20 tests passed. Six geometry tests cover notched/plain fixtures, 22/24/28/32/38/48-point bands, 1x/2x scaling, negative/above-primary origins, bottom Dock exclusion, auto-hide fallbacks, missing cutout geometry, and compact/expanded top alignment.
- Release app built and ad-hoc signed with `scripts/build-app.sh`.
- Connected built-in display reports 1512×982 points at 2x, a 32-point top reservation and safe inset, and a 185-point notch gap. Global status-bar thickness is 22 points, demonstrating why it cannot be the primary measurement.
- Connected external display reports 1920×1080 at 1x, origin (-1920, 479), no top reservation and no notch. This exercises the initial hidden/unreserved fallback; the physical hidden menu-bar height is not proven by this observation.
- Existing 72-second app probe exercised compact, expanded, repeated transitions, and recovered compact. Mean CPU percentages of one core were 3.155 / 1.464 / 8.678 / 0.472 respectively. Peak RSS was 103.484 MiB; peak physical footprint 34.501 MiB. These short samples include live usage updates and desktop activity and are not a long-term performance baseline.
- Native component rendering against both connected screen geometries passed compact → expanded → compact frame assertions. The built-in uses 409×32 compact and 640×422 expanded frames; the external uses 224×22 and 640×412. Both keep the top fixed. The running app also passed collapse-button and compact-clock expansion interactions.
- Older macOS releases, changing the user's scaling/arrangement settings, and physically moving the panel between screens remain manual checks. No system settings were changed.

Native references: [NSScreen.visibleFrame](https://developer.apple.com/documentation/appkit/nsscreen/visibleframe), [safeAreaInsets](https://developer.apple.com/documentation/appkit/nsscreen/safeareainsets), and [currentSystemPresentationOptions](https://developer.apple.com/documentation/appkit/nsapplication/currentsystempresentationoptions).

## Monitor selection follow-up, 2026-10-16

Settings now shows the chosen display and geometry. Live UI switching between the built-in Retina display and external G27F produced 32-point/185-point-gap and 22-point/no-gap diagnostics respectively. The previous active-screen launch policy could place the app on the external monitor, explaining why the laptop-sized compact bar was not always shown. The updated default selects the built-in display; no Mac-model-specific height constant was added.
