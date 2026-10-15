# Product requirements

> Direction update, 2026-10-15: [Inspiration and notch bar direction](INSPIRATION.md) records the owner's latest concept and takes precedence over conflicting statements here. This document describes the earlier floating-clock baseline and needs revision before implementing the notch bar.

Status: proposed for discussion, 2026-10-15. The [requirements register](REQUIREMENTS.md) owns acceptance criteria; this document owns product scope.

## Problem and user

The primary user wants to read the local time while working in other applications without switching windows or relying on the menu-bar clock. The utility must remain readable without drawing attention, stealing keyboard focus, or consuming noticeable resources.

Initial use is personal, on the reference M1 Pro MacBook Pro. External-monitor use is part of the release verification. A wider public audience and distribution are later decisions.

## Main journeys

1. Launch the app. A single clock appears near the top-right of the usable desktop and a menu-bar item provides Settings and Quit.
2. Drag the clock to a useful location. On relaunch, it returns to a reachable position on the selected display when available.
3. Open Settings. Change time format, font, size, color mode, opacity, date, or seconds and see the result immediately.
4. Hide the clock while presenting, then show it again from the menu bar. A reset-position command recovers a misplaced clock.
5. Resume after sleep or disconnect a monitor. The clock shows current local time and remains reachable.

## Release scope

Core milestone includes the AppKit clock panel, accurate local time, 12/24-hour formatting, manual repositioning, menu-bar controls, persistence, and basic appearance customization. Release completion also includes optional seconds/date and opt-in launch at login. These follow the core milestone rather than delaying the first useful clock.

One clock appears on one selected monitor. Users may drag it between monitors. There is no clock-per-monitor mode, world clock, alarm, countdown, or custom date-format language in this release.

The clock should join ordinary desktop Spaces. Participation in another application's full-screen Space and Stage Manager must be evaluated in M0. In contexts where the platform prevents visibility, use a documented limitation and preserve settings and recovery. Do not escalate to private APIs or system-level window layers.

## Non-goals

Music, notifications, weather, widgets, plugins, cloud synchronization, Dynamic Island behavior, notch attachment, cross-platform support, SwiftUI, continuous animations, and remote time synchronization are excluded. The app displays the Mac's time; it does not correct the system clock.

## Success and release gate

All release requirements in [Requirements](REQUIREMENTS.md) must have evidence or an explicit scope change. The clock must remain above tested ordinary application windows without changing the typing target. Position recovery, sleep/wake, time-zone changes, keyboard settings access, and VoiceOver checks must pass.

Performance must be measured on the reference Mac. Missing the proposed budgets triggers investigation or a documented budget revision before release. No numerical guarantee exists until measurements support it.

## Working assumptions

The application uses no network services and needs no Accessibility, Screen Recording, or Input Monitoring access for its planned local panel interactions. This is an architectural expectation to verify during M0. Launch-at-login authorization uses the operating system's service state. Public distribution and signing remain undecided.

The minimal typography direction is recommended. Appearance controls should help readability across wallpapers without adding theme packs or a theme editor.
