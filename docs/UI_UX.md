# UI and UX

> Direction update, 2026-10-15: [Inspiration and notch bar direction](INSPIRATION.md) records the owner's latest concept and takes precedence over conflicting statements here. This document describes the earlier floating-clock baseline and needs revision before implementing the notch bar.

Status: proposed direction for discussion. No visual mockup or rendered app has been created.

## Design directions

| Direction | Usability | AppKit complexity | Performance implication | Recommendation |
|---|---|---|---|---|
| Minimal floating digits | Few visual elements; contrast depends on content behind it | Low, native text in a transparent panel | Small redraw region, no material sampling | Start here |
| Glass-like translucent card | Background material can improve separation, but needs Reduce Transparency behavior | Medium, `NSVisualEffectView`, appearance and contrast testing | Compositing/material cost must be measured, even when text is static | Later experiment |
| Notch-adjacent clock | Frees desktop area but competes with menu extras and camera housing | High, safe regions, geometry changes, full-screen rules | Static text can be cheap; integration adds event handling | Deferred |
| Compact pill | Clear bounds and easier dragging, useful on busy wallpapers | Low to medium, rounded solid/translucent background | Modest static compositing; avoid heavy shadows | Candidate after initial usability feedback |
| Large typography clock | Readable at distance, occupies substantial working area | Low, but long locale strings and fit limits need care | Larger dirty area; still update only on changed content | Supported through size setting, no separate mode |

The proposed MVP has one text-only direction. Avoid shipping several unfinished themes. If wallpaper readability is inadequate in user trials, evaluate the compact pill before adding blur.

## Layout specification

Use 48-point system medium text with monospaced digits by default. Support 20 to 160 points. Reserve width for the widest expected time in the selected font, format, and locale, including day period. Recompute on those settings changes. A font change may change frame size; clamp position afterward.

Use 12 points of horizontal hit-area padding and 8 points vertically. Date text is 45% of the effective time size, with a 12-point minimum, separated by 4 points. Measure actual strings rather than hard-coding a panel width. For long date strings, grow within the usable screen and then fit without silently truncating the date. Settings controls show both preferred size and any temporary fit reduction.

There is no title bar, blinking separator, automatic movement, decorative transition, or hover animation. Text ticks change in place. Native Settings controls use Auto Layout and accommodate longer localized labels.

Automatic color follows macOS appearance, not the background behind the overlay. Light and dark text modes provide manual recovery. Opacity below 1.0 is user-selected and may reduce readability. Do not describe automatic mode as universal contrast adaptation.

## Interaction and states

| State or action | Expected behavior |
|---|---|
| First launch | Show the clock and status item with defaults. No permission walkthrough or modal onboarding. |
| Passive display | Preserve the foreground app's focus and typing target. |
| Dragging | Move the panel from its content hit area; persist once on release. No selection of clock text. |
| Settings open | Activate a normal titled window. Edits preview immediately, including format and opacity. Closing it leaves the clock running. |
| Hidden | Remove the clock and suspend updates. Keep Show Clock and Settings available in the status menu. |
| Display disconnected | Move to a reachable available display; do not open a modal dialog. |
| Invalid preference/missing font | Use a validated fallback and a non-blocking settings message where useful. |
| Login error | Explain actual service state in Settings and offer the OS settings route when relevant. |
| Quit | End the process; no confirmation dialog or lingering background helper. |

The status menu order is Show/Hide Clock, Settings, Reset Position, separator, Quit. Use a stable compact symbol instead of another ticking menu-bar clock. Settings uses Command-comma when the app/menu has focus; Command-Q quits when the app is active. These are local key equivalents, not global keyboard hooks.

## Accessibility

Use native text elements or expose equivalent readable clock/date semantics from the custom view. Provide a useful application/status-item label and keyboard access to menu actions, settings fields, and position presets. Include a Move to Display selector and Reset Position in Settings so essential placement does not depend on dragging.

VoiceOver should read the current time on demand. Do not post a spoken announcement every second or minute. Test the nonactivating panel's discoverability with VoiceOver; if the overlay cannot be reached reliably, provide a current-time readout in Settings. This is a functional fallback to test, not evidence already obtained.

Respect Reduce Motion and increased-contrast preferences. The initial design has no decorative motion. If a material direction is later adopted, honor Reduce Transparency with a solid alternative. Do not rely solely on color for login status or validation errors.

Acceptance belongs to FR-006/FR-007 and NFR-007/NFR-008. Test real VoiceOver navigation rather than checking labels in code alone.
