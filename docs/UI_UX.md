# UI and UX

## Current visual and motion direction, 2026-10-16

The owner is creating this project primarily for its aesthetics, rich UI components, and animations. A visually distinctive result is a central product goal. Treat clock faces, materials, depth, expressive details, and compact-to-expanded motion as core design work, with readability and accessibility built into that work.

Design compact and expanded states together. Prototype the expansion/collapse choreography, switching between clock faces, and feedback for interactive components before treating the visual design as complete. A working plain-text clock alone does not satisfy the intended outcome. Start with one polished face and its transitions, then extend the visual family.

Proposed review criteria:

- The first face has a deliberate silhouette, palette, typography or hand design, and treatment of depth/material, informed by the saved references.
- Expansion, collapse, and clock switching have specified start/end states and can be interrupted or reversed without jumps, clipped content, or focus theft.
- Compact resting geometry still matches menu-bar height and stays above the notch lower edge. Transition geometry must be designed explicitly.
- Reduce Motion provides an equally usable reduced-motion treatment, and VoiceOver can read time without depending on the animated graphics.
- Evaluate frame pacing and energy during motion separately from idle clock cost. No specific animation duration or refresh-rate target is accepted yet.

The older alternatives and floating-clock dimensions below are historical planning notes pending the notch redesign.

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

The earlier text-only MVP recommendation is superseded. Develop a distinctive clock face and motion treatment first, then add further faces without diluting their visual quality.

## Layout specification

Use 48-point system medium text with monospaced digits by default. Support 20 to 160 points. Reserve width for the widest expected time in the selected font, format, and locale, including day period. Recompute on those settings changes. A font change may change frame size; clamp position afterward.

Use 12 points of horizontal hit-area padding and 8 points vertically. Date text is 45% of the effective time size, with a 12-point minimum, separated by 4 points. Measure actual strings rather than hard-coding a panel width. For long date strings, grow within the usable screen and then fit without silently truncating the date. Settings controls show both preferred size and any temporary fit reduction.

The earlier blanket exclusion of decorative transitions and hover animation is superseded. Choose motion intentionally for expansion, face changes, and component interaction. Native Settings controls can still use Auto Layout and accommodate longer localized labels.

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

Respect Reduce Motion and increased-contrast preferences. Provide a reduced-motion alternative for the planned animations. If a material direction is later adopted, honor Reduce Transparency with a solid alternative. Do not rely solely on color for login status or validation errors.

Acceptance belongs to FR-006/FR-007 and NFR-007/NFR-008. Test real VoiceOver navigation rather than checking labels in code alone.
