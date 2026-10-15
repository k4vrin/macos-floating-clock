# Window management

> Direction update, 2026-10-15: [Inspiration and notch bar direction](INSPIRATION.md) records the owner's latest concept and takes precedence over conflicting statements here. This document describes the earlier floating-clock baseline and needs revision before implementing the notch bar.

Status: proposed configuration pending M0 evidence. Covers FR-002, FR-003, FR-005, FR-010, and FR-011.

## Panel policy

Start with one borderless `NSPanel` created with the nonactivating panel style. Set a clear background, non-opaque backing, `.floating` level, no window shadow for the text-only direction, and `hidesOnDeactivate = false`. Apple documents a default of true for panels, so relying on the default would hide the clock while working elsewhere. Keep the panel out of ordinary window cycling and disable tabbing.

Configure nonactivation at construction. The clock does not need to become key or main; Settings uses a separate normal window. Mouse-down inside the clock starts a drag without activating the app. Do not enable `ignoresMouseEvents` in the default mode because that would prevent dragging. Click-through and locking are deferred rather than adding a second interaction mode now.

`.floating` targets stacking above ordinary windows. It does not mean above menus, secure system UI, other higher-level overlays, every game, or every full-screen application. Do not use screen-saver or shielding levels, repeated `orderFront` timers, or private APIs to force visibility.

## Spaces, full screen, and Stage Manager

Request `.canJoinAllSpaces` for desktop Spaces. On the proposed macOS 13 baseline, evaluate `.canJoinAllApplications` for participation alongside other apps. Apple describes eligible full-screen participation, which leaves runtime conditions to verify. It is mutually exclusive with `.primary` and `.auxiliary`.

Evaluate `.fullScreenAuxiliary` in M0 rather than treating its name as proof of cross-app visibility. It belongs to a separate group mutually exclusive with `.fullScreenPrimary` and `.fullScreenNone`. Record the final tested combination in ADR-003. Do not indiscriminately combine flags or add `.moveToActiveSpace` as a workaround for a different Spaces policy.

Test full-screen Safari and one other ordinary app, transitions in and out, Mission Control, Stage Manager on/off, and displays with separate Spaces on/off. Record app activation policy, masks, collection behaviors, OS build, and observed focus. A failure in a full-screen context is a documented limitation requiring a product decision; a failure over ordinary windows blocks the release.

## Geometry and persistence

AppKit screen coordinates use points in a global desktop space, which may include negative origins. Never assume the selected screen starts at zero or use pixels as window coordinates. Re-read `NSScreen.visibleFrame` after configuration changes. It accounts for the Dock and menu bar, including the notch-adjacent menu-bar region, and must not be cached indefinitely.

Default placement is 16 points inside the top-right of the selected usable frame. Proposed selection is the screen containing the focused window at first launch, with the first available screen as fallback. The clock remains on its selected display rather than following the pointer or focused app.

Persist a display UUID when obtainable through public display APIs, plus normalized horizontal/vertical offsets within the available travel rectangle. A display's array index or localized name is not a persistent identity. Treat even a UUID as a preference hint, since adapters and mirroring may change identity.

On restore, locate that display, recompute the content size, map offsets into the current usable frame, then clamp the entire panel inside it with a 16-point margin where space permits. If the display is missing, choose an available display and clamp there. If the content exceeds available width/height, reduce the effective font size to fit without overwriting the preferred size. Handle a zero-sized travel interval without division by zero.

During dragging, permit crossing displays. On release, choose the display with the greatest panel intersection, clamp, and persist once. Do not write settings for every mouse-moved event. Reconcile after display attach/detach, wake, resolution changes, panel-size changes, and Reset Position. Defer showing the panel when no usable display is available.

Use point-based text/layout and AppKit backing conversion where pixel alignment is required. On backing-scale changes, refresh layout if necessary; do not multiply font sizes by the scale factor.

## References and evidence boundary

Checked 2026-10-15: [nonactivatingPanel](https://developer.apple.com/documentation/appkit/nswindow/stylemask-swift.struct/nonactivatingpanel), [hidesOnDeactivate](https://developer.apple.com/documentation/appkit/nswindow/hidesondeactivate), [floating level](https://developer.apple.com/documentation/appkit/nswindow/level-swift.struct/floating), [canJoinAllApplications](https://developer.apple.com/documentation/appkit/nswindow/collectionbehavior-swift.struct/canjoinallapplications), [visibleFrame](https://developer.apple.com/documentation/appkit/nsscreen/visibleframe), [safeAreaInsets](https://developer.apple.com/documentation/appkit/nsscreen/safeareainsets).

The installed SDK confirms the availability and exclusivity described above. No panel has been run for this project. Notch attachment would require a separate design using safe-area and auxiliary top-area APIs; it is not a hidden MVP requirement.
