---
type: project-hub
status: proposed
created: 2026-10-15
language: en
---

# macOS Floating Clock

A native macOS clock utility, now directed toward a compact notch bar with expandable clock designs and possible companion content.

This folder contains planning documents for discussion. This repository contains documentation and inspiration only. No application source, build, performance results, or runtime verification exists for this project. The working name is provisional.

## Latest direction, 2026-10-15

See [Clock inspiration and notch bar direction](docs/INSPIRATION.md) for all seven saved reference images and the owner's updated concept. Compact mode extends on both sides of the notch, exactly matches the macOS menu-bar height, and does not extend below the notch. Expanded mode reveals switchable expressive clock designs. A date or AI subscription usage widget is a possible companion on the other side.

This replaces the earlier text-only floating-clock direction. The initial documents below are retained as a planning baseline, with notices where they need revision. They are not yet an implementation-ready specification for the notch bar.

## Original product boundary, pending revision

The first release focuses on one local-time clock, one movable floating panel, a menu-bar item, settings, and reliable recovery after sleep or display changes. Swift and AppKit are required. SwiftUI, media controls, weather, widgets, cloud sync, plugins, and notch integration are outside this release.

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
