# First clock prototype

## Compact clock form correction, 2026-10-16

The owner clarified that REF-03's horizontal clock is the compact clock's form reference, not merely inspiration for rounding the enclosing bar. Compact mode must show an actual analog dial in that elongated body, with a rounded outer end and a square mounting end toward the notch. Retain the expanded Wavy face's cream dial, red housing/rim, colored markers, and wavy red/black hands. Do not copy the reference's straight hands, typography, or terracotta palette as a new clock theme.

Implemented the miniature analog clock on the left, with the existing short date on the right. It occupies the existing menu-bar-height bounds; no taller compact window or second timer was added. Main and compact faces share the same wavy-hand drawing and current-time sample. Hands fit the elongated dial at every angle. Clicking the miniature clock expands the main view, and it exposes an accessible button with the current time.

The current miniature is 84 points wide and as tall as the bar. The black outer pill with digital time is superseded. The expanded circular face remains the main clock. Live expansion/collapse was checked and actual window screenshots were saved under ignored `output/screenshots/compact-horizontal-live.png` and `output/screenshots/expanded-horizontal-live.png` in the project checkout.

Implemented and checked 2026-10-16. This is the first visual prototype, not completion of the release roadmap.

### Compact analog revision resource check

A fresh 72-sample Release probe includes the new compact analog face. Steady CPU excludes the first two samples of each resting phase. Memory ranges include all samples.

| Phase | Mean CPU | Physical footprint | RSS |
|---|---|---|---|
| compact | 0.02% | 22.0–32.7 MiB | 66.8–86.0 MiB |
| expanded | 0.54% | 47.8–63.1 MiB | 84.0–84.9 MiB |
| transitions | 11.55% | 39.3–64.7 MiB | 85.8–87.7 MiB |
| recovered_compact | 0.03% | 32.3–40.9 MiB | 87.0–87.7 MiB |

This is a short development check, not the full release performance protocol. No frame-rate loop or additional clock timer was introduced. Raw samples are in ignored `output/compact-horizontal-resource-samples.csv`.

## What runs

Native Swift 6/AppKit application, built with SwiftPM and packaged as `build/Wavy Clock.app`. The first face, The Wavy One, draws its cream dial, red rim, rounded hour markers, and wavy hands directly with AppKit/Core Graphics. No third-party packages or SwiftUI are used.

A compact bar has time on the left and a short date on the right of the camera-housing gap. Clicking it expands a larger clock/date composition. The window resizes with a 0.36-second eased transition and the content fades over 0.24 seconds. Reduce Motion removes these transitions. The Collapse button and menu-bar icon provide recovery. Expanded rendering updates once per second; compact time updates on minute boundaries. Hidden/sleeping operation cancels clock updates.

The panel uses screen safe-area and auxiliary top-area geometry for the notch gap. It uses the smaller of system menu-bar thickness and camera-housing height on a notched display. When these dimensions differ in the opposite direction, product geometry needs review rather than claiming exact behavior on every configuration. On an unnotched screen it uses a centered compact bar without a fake notch.

## Verification

- Release build and local ad-hoc signing succeeded with Xcode SDK 27.0 / Apple Swift 6.4.0, using Swift 6 language mode and a macOS 13 deployment target.
- Three XCTest cases passed: hour/minute position consistency, midnight/noon analog position, and compact height constraints. These are model tests, not full system acceptance.
- Ran the native app on macOS 27.0.1, build 26A434, Apple Silicon.
- Used live UI interaction to expand from the compact bar and collapse through its button. Captured actual app-window screenshots, not generated mockups.
- Final build hides collapsed detail controls from accessibility. Full keyboard navigation, VoiceOver reading, sleep/wake, full-screen apps, multiple display configurations, and macOS 13 runtime support remain unverified.
- CPU/memory probes exercise compact, expanded, repeated transitions, and return to compact. They are short development measurements and do not satisfy the longer release protocol in TESTING.md.

## Resource measurement method

The opt-in `--performance-probe output/resource-samples.csv` mode samples cumulative process user+system CPU time and Mach resident/physical footprint once per second. CPU is normalized so 100% means one logical core. The probe runs 20 seconds compact, 20 seconds expanded, 12 seconds of repeated transitions, and 20 seconds compact recovery. It exits after 72 samples. The measurement timer exists only in probe mode.

For steady-state CPU summaries, exclude the first two samples of each resting phase to separate startup/transition work; report transition samples separately. Memory ranges include all phase samples. Physical footprint and RSS are different metrics. This experiment does not include WindowServer/GPU energy, battery impact, prolonged leak testing, or statistical frame-pacing validation.

## Short resource probe results

Release build, 72 samples, collected before the final accessibility-only change that hides collapsed controls. The final accessibility change was rebuilt and checked separately; these samples are not a fresh benchmark of that last revision. CPU summaries below exclude the first two samples of each resting phase; transition measurements include all 12 samples. Physical footprint and RSS ranges include every sample in the phase.

| Phase | Mean CPU | Peak sampled CPU | Physical footprint range | RSS range |
|---|---|---|---|---|
| compact | 0.03% | 0.14% | 32.0 to 32.2 MiB | 85.0 to 85.2 MiB |
| expanded | 0.44% | 0.71% | 48.6 to 71.3 MiB | 79.0 to 99.6 MiB |
| transitions | 10.69% | 13.38% | 41.8 to 65.2 MiB | 79.8 to 84.0 MiB |
| recovered_compact | 0.04% | 0.28% | 32.3 to 42.0 MiB | 79.4 to 80.8 MiB |

CPU returns to idle after the transition sequence. Interpret memory recovery using the recorded series rather than the peak during animated window resizing. These short runs cannot establish a leak-free or battery-life claim.

## Screenshots and local run

Live window screenshots are saved under ignored `output/screenshots/`. They show the app window itself, so the physical camera cutout and surrounding desktop are not visible. Generated images, traces, and app bundles stay outside the vault and Git.

```sh
zsh scripts/build-app.sh
open 'build/Wavy Clock.app'
swift test
```

## Remaining scope

Only one face is implemented. There is no theme switcher, preferences window, saved customization, login registration, AI usage integration, or release packaging/notarization. Screen placement and menu-item collision handling need broader verification. The fixed expanded composition is a first design for review, not a finalized responsive component system.

The source and previous documentation edits remain local and uncommitted. The existing GitHub repository has not been updated in this pass.

## Platform references

Geometry choices were checked against Apple's [screen safe-area documentation](https://developer.apple.com/documentation/appkit/nsscreen/safeareainsets) and [auxiliary top-left area](https://developer.apple.com/documentation/appkit/nsscreen/auxiliarytopleftarea-uglc). Animation uses AppKit's [NSAnimationContext](https://developer.apple.com/documentation/appkit/nsanimationcontext). These references describe APIs, not proof of compatibility on every macOS version.

## Digital clock and sets

The second clock and installable set implementation, validation, native UI checks, and resource measurements are recorded in [Clock packs](CLOCK_PACKS.md). Both clock types share the host timer and compact height constraint.
