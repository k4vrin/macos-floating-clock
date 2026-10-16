---
type: project-hub
status: prototype
created: 2026-10-15
language: en
---

# macOS Floating Clock

## First clock prototype

Implemented 2026-10-16. The first native AppKit face, **The Wavy One**, adapts the cream/red reference with raised hour markers and wavy hands. A menu-bar-height horizontal analog clock, shaped after REF-03 and styled like the main face, expands into the clock/date panel with animated resizing and reduced-motion support. Click either compact wing to expand, click Collapse to close, or use the clock menu-bar icon for Expand/Collapse, Show/Hide, and Quit.

Build and run from the repository root:

```sh
zsh scripts/build-app.sh
open 'build/Wavy Clock.app'
swift test
```

The build uses SwiftPM with Swift 6 language mode and the installed Xcode toolchain, then packages and ad-hoc signs a local `.app`. It is a development prototype, not a notarized distribution. Open `Package.swift` in Xcode to inspect the sources.

See [First clock verification](docs/FIRST_CLOCK.md) for actual checks, resource measurements, limitations, and screenshot locations. Earlier planning documents remain proposals where not explicitly implemented. Analog and digital clocks, reusable date/AI widgets, pack installation, and saved selections are implemented. Claude needs its status-line connection configured. Launch at login and general settings remain planned.

## Primary product goal, 2026-10-16

The owner is creating this project primarily for its aesthetics, rich UI components, and animations. A visually distinctive result is a central product goal. Treat clock faces, materials, depth, expressive details, and compact-to-expanded motion as core design work, with readability and accessibility built into that work. See [the visual direction](docs/INSPIRATION.md) for the reference gallery and latest intent.

A native macOS clock utility, now directed toward a compact notch bar with expandable clock designs and possible companion content.

This repository contains project documentation, reference images, and the first AppKit clock prototype. The working name is provisional.

## Latest direction, 2026-10-15

See [Clock inspiration and notch bar direction](docs/INSPIRATION.md) for all seven saved reference images and the owner's updated concept. Compact mode extends on both sides of the notch, exactly matches the macOS menu-bar height, and does not extend below the notch. Expanded mode reveals switchable expressive clock designs. Date and AI subscription usage widgets now occupy the independently selectable right-hand slot.

This replaces the earlier text-only floating-clock direction. The initial documents below are retained as a planning baseline, with notices where they need revision. Use the implemented clock-pack and right-side-widget documents for the current contracts.

## Current prototype boundary

The prototype uses Swift and AppKit for one notch panel, analog and digital clock designs, independently selected right-side date/AI widgets, installable declarative packs, and lifecycle-aware refresh. Full settings, movable floating placement, launch at login, media controls, weather, cloud sync, and executable third-party plugins remain outside the implemented scope.

The reference device is a 14-inch MacBook Pro with M1 Pro and a display notch. Proposed deployment baseline is macOS 13 or later, subject to the owner's installed OS and the compatibility matrix. An API being available does not mean that every OS version has been tested.

## Documents

| Document | Read it for |
|---|---|
| [Inspiration and latest direction](docs/INSPIRATION.md) | Seven image references, compact/expanded states, companion ideas |
| [PRD](docs/PRD.md) | User need, release scope, success criteria |
| [Requirements](docs/REQUIREMENTS.md) | Stable requirement IDs and acceptance criteria |
| [Architecture](docs/ARCHITECTURE.md) | Components, ownership, lifecycle, platform constraints |
| [UI and UX](docs/UI_UX.md) | Design alternatives, recommended direction, interactions |
| [Window management](docs/WINDOW_MANAGEMENT.md) | Focus, placement, monitors, Spaces, full-screen limits |
| [Time engine](docs/TIME_ENGINE.md) | Wall time, formatting, scheduling, recovery |
| [Settings](docs/SETTINGS.md) | Defaults, validation, persistence, login integration |
| [Roadmap](docs/ROADMAP.md) | Incremental milestones and exit conditions |
| [Testing](docs/TESTING.md) | Verification matrix and measurement procedures |
| [Decisions](docs/DECISIONS.md) | Required constraints and proposed ADRs |
| [Open questions](docs/OPEN_QUESTIONS.md) | Discussion points and implementation blockers |

## Original technical starting point, pending revision

Use an accessory AppKit application with a borderless, nonactivating `NSPanel`, a custom `NSView` containing native text fields, and a persistent `NSStatusItem`. Keep AppKit operations on the main thread. A single clock engine reads current system time at each scheduled boundary; a settings store uses `UserDefaults`.

The largest risk is focus and window visibility across full-screen Spaces and Stage Manager. First validate a small window-behavior experiment on the reference Mac before building customization. Ordinary-window floating behavior is required. Full-screen behavior needs recorded evidence and must not be advertised as universal.

Launch at login, optional seconds, and optional date are proposed release requirements, delivered after the core clock milestone. That original notch deferral is superseded by the latest direction; its geometry and interactions need a new feasibility pass.

## Future development setup

When implementation is authorized, create a separate source repository outside this vault. Use Xcode with a macOS SDK supporting the proposed macOS 13 deployment target, Swift, an AppKit app target, and XCTest targets. Remove any template SwiftUI entry point and use `NSApplicationDelegate`. Keep the exact Xcode and Swift versions in that repository's README after testing them. No package dependencies are proposed.

Local build artifacts and signing material belong outside the vault. Choose the bundle identifier, source location, signing identity, and distribution channel before release work. Repository setup does not start implementation or change the learning backlog.

## Evidence and status

Technical research was checked against Apple documentation and selected installed Xcode SDK declarations on 2026-10-15. References appear beside the relevant recommendations. SDK declarations confirm availability, not runtime behavior. All performance numbers are proposed targets. See [Testing](docs/TESTING.md) for how evidence must be recorded.

## Digital clock and installable sets

The Originals set now includes analog and digital designs. Use the status menu **Clocks** to switch. **Install Clock Pack…** imports an additional set from JSON. See [Clock pack architecture and format](docs/CLOCK_PACKS.md) and the [Blue Hour example](examples/blue-hour.clockpack.json).

## Right-side widgets

Select a flip calendar or Codex/Claude usage desk from **Right-side Widgets**. Each supports compact and expanded views and can be included in an installed pack. [Architecture, provider connections, and limitations](docs/RIGHT_SIDE_WIDGETS.md).

### Settings and theme plugins

Right-click the compact clock and open **Settings…** to choose a monitor, clock, right-side widget, and theme. The app now prefers the built-in display and measures its menu-bar band automatically. Settings also includes 12/24-hour time, reduced animations, and start-expanded behavior. See [Settings](docs/SETTINGS.md) and [Theme plugins](docs/THEME_PLUGINS.md); [Tide Pool](examples/tide-pool.clockpack.json) is an installable theme-only example.
