# Visual families and hover morphing

Status: implementation started in a stack based on the completed native app baseline. This document separates delivered layers from the remaining visual and motion work.

## Design contract

Components choose information: analog/digital time, calendar, or AI usage. A visual family chooses the native design recipe. A palette chooses colors and materials. Wavy is the intended current family, including custom vector numerals inspired by the analog hands. Counter preserves the existing tiled digital design as a separate family.

The clock and right-side widget must eventually share housing details, typography, stroke weights, material depth, and animation. Palettes remain independently selectable. Existing version 1 JSON palettes remain compatible. An optional `family` recommendation accepts only `wavy` or `counter`; selecting such a palette chooses its recommended family. Unsupported family names fail decoding. JSON cannot execute code or introduce arbitrary native renderers.

## Stack layers

1. Visual-family foundation: saved Wavy/Counter preference, separate Visual family and Palette controls, optional validated plugin recommendation, and family propagation to recreated views. This layer establishes the contract; it does not claim finished family-specific artwork.
2. Wavy numeral renderer: reusable vector digits, colon, and percentage symbol; the Wavy digital clock uses them in both sizes, while Counter retains tiled digits. This starts the artwork layer, not the full coherent widget family.
3. Remaining family artwork: matching compact and expanded analog, date, and AI components, with wavy primary numerals and readable native supporting labels. Finish Counter's matching calendar and usage treatment. Review both families as complete contact sheets.
4. Hover morph: shared transition coordinator and semantic component geometry. Replace independent window resizing/fading with a continuous, reversible transformation. Add hover and accessibility behavior, then capture motion recordings and compare resource use.

## Morph behavior to implement

Keep the measured menu-bar height and physical notch exclusion authoritative. The shell grows downward from its fixed top anchor. The same recognizable clock hands, numerals, date, and usage gauges move into their expanded locations; secondary labels appear as room opens up. Use compatible paths/layers for shape changes rather than substituting unrelated screens.

Maintain independent hover intent, click-expanded state, and transition progress. Proposed starting values are 100–150 ms hover intent, 250–350 ms exit grace, and 350–450 ms expansion. Tune by observation, not fixed assumptions about an Apple animation. Allow entry during collapse to reverse from the current presentation position. Keep the app open while menus or settings interactions require it. Preserve click and keyboard alternatives and an option to disable hover. Reduce Motion removes the spatial morph.

One main-actor transition coordinator owns progress and cancellation. Retarget in-flight motion instead of stacking completion handlers. Stop transition-only work at rest; preserve the existing clock/provider scheduling. Do not expand hit areas into the physical notch or keep a large invisible panel intercepting unrelated clicks.

## Review and validation

Review a wavy numeral sheet, then compact/expanded contact sheets for both families. Verify all digits, `11:11`, `08:08`, `100%`, and 12/24-hour format. Test palette changes and clock/widget replacements without losing the chosen family.

For motion, check frame continuity, interrupted transitions, rapid entry/exit, menu interactions, Reduce Motion, monitor changes, and hidden/sleeping operation. Record short native videos plus CPU/memory probes on the built-in Retina display. Existing 32-point sizing must remain intact at the compact resting state. Older macOS and physical reconnection remain explicit hardware checks.

References: Apple's [Designing Fluid Interfaces](https://developer.apple.com/videos/play/wwdc2018/803/), [Animate with springs](https://developer.apple.com/videos/play/wwdc2023/10158/), and [Motion guidance](https://developer.apple.com/design/human-interface-guidelines/motion). The references inform responsiveness, continuity, and interruptibility; the proposed timings above are this app's starting values.
