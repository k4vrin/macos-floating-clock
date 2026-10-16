# Decisions and trade-offs

> Implemented update, 2026-10-16: [Clock packs](CLOCK_PACKS.md) defines the digital clock and installable multi-clock sets. It supersedes earlier exclusions of clock packs or a second clock design. Version 1 uses native renderer templates and declarative JSON.


> Direction update, 2026-10-15: [Inspiration and notch bar direction](INSPIRATION.md) records the owner's latest concept and takes precedence over conflicting statements here. This document describes the earlier floating-clock baseline and needs revision before implementing the notch bar.

Created 2026-10-15. Required constraints come directly from the supplied brief. Proposed ADRs are recommendations for discussion and have not been accepted by the owner. No ADR implies runtime verification.

## ADR-001: Native AppKit scope

Status: required by brief.

Use Swift, AppKit, NSWindow/NSPanel, and NSView. Start with native frameworks and `UserDefaults`. The first release contains clock functionality only and no SwiftUI. This keeps the implementation within the requested platform and learning scope. A future WidgetKit extension or SwiftUI settings rewrite requires a new decision.

## ADR-002: macOS 13 baseline

Status: proposed, confirm before creating the app target.

Choose macOS 13 as a provisional minimum because it includes `SMAppService` and `canJoinAllApplications`. Supporting older systems would require different login/window paths with additional tests. Raising the baseline may simplify testing but excludes more machines. Confirm the owner's OS and available compatibility environments in Q-001. API availability alone does not establish supported runtime behavior.

## ADR-003: One passive floating panel

Status: proposed, M0 validation required.

Use an accessory app with one nonactivating borderless NSPanel at floating level and a retained menu-bar item. Ordinary NSWindow is an alternative but requires more attention to focus behavior. Do not use high system window levels to manufacture universal visibility.

Request all desktop Spaces; evaluate eligible full-screen/Stage Manager participation using documented flags. Freeze the exact flag combination only after recording M0 results. The release claim must list tested conditions. Full-screen invisibility in specific contexts may be an accepted limitation; ordinary-window invisibility is a blocker.

## ADR-004: Boundary scheduling and cached formatting

Status: proposed.

Use a one-shot main-run-loop Timer, cached DateFormatter instances, and current wall time sampled on each refresh. Recompute the next boundary and skip missed ticks. DispatchSourceTimer and Date.FormatStyle remain reasonable alternatives but need a concrete benefit before switching. No frame-rate timer is warranted for static digits.

Before closing M1, record how explicit hour-cycle selection interacts with locale. FR-004 must hold across the locale matrix, rather than relying on undocumented formatter assumptions.

## ADR-005: One selected monitor and normalized placement

Status: proposed.

Show one clock and persist a display hint plus normalized offsets. Always clamp after display or content-size changes. Pixel coordinates and screen indices are fragile across scaling/reordering. Multiple simultaneous clock panels would add lifecycle and configuration work that the initial user journey does not require.

## ADR-006: Text-only visual direction

Status: superseded by ADR-009 and ADR-010.

Start with native text, monospaced system digits, explicit size/opacity, and automatic/light/dark text modes. Glass materials and notch attachment add compositing or geometry questions before the core clock is proven. A compact solid pill is the next candidate if readability feedback demands a background.

## ADR-007: Release options follow the core milestone

Status: proposed scope interpretation.

The brief lists date, seconds, and login startup as initial requirements while its compact MVP list omits them. Include all three in the first release at M4, with a smaller useful clock delivered first. This resolves the ambiguity without treating the omissions as permission to drop requested capabilities.

## ADR-008: Local settings, OS-owned login state

Status: proposed.

Use versioned UserDefaults for preferences and geometry. Query SMAppService for actual login registration/authorization. Do not conflate a preference checkbox with service state, and do not add a database or helper daemon. Keep visibility session-only so relaunch remains a recovery path.

## ADR-009: Capture the owner's notch bar direction

Status: owner-stated product direction, captured 2026-10-15. Technical design and release scope remain open.

The compact app extends on both sides of the notch, exactly matches the macOS menu-bar height, and never extends below the notch while compact. Expanded mode reveals switchable clock faces inspired by the seven saved images. A date or AI subscription usage widget is a possible companion, not an approved integration. See [Inspiration](INSPIRATION.md).

This supersedes ADR-006's text-only recommendation and the notch deferral in the initial scope. ADR-003's free-floating presentation and ADR-005's drag-placement model require review. ADR-001's native Swift/AppKit constraint remains; clock-only scope must be revisited if a companion widget is selected. Existing FR/NFR IDs remain recorded, but geometry, analog rendering, scheduling, settings, roadmap, and testing need coordinated revision before implementation. No new technical feasibility claim is made by saving these references.

## ADR-010: Aesthetics and animation are primary goals

Status: owner-stated product priority, captured 2026-10-16.

The owner is creating this project primarily for its aesthetics, rich UI components, and animations. A visually distinctive result is a central product goal. Treat clock faces, materials, depth, expressive details, and compact-to-expanded motion as core design work, with readability and accessibility built into that work.

This supersedes the earlier exclusions of decorative motion and the recommendation to defer visual richness until after a plain-text clock. Swift/AppKit remains the stack. Animation timing, materials, continuous hand motion, and rendering technique remain design choices to prototype. Keep wall-time sampling distinct from visual animation and assess active-motion performance separately from idle efficiency.

Affected documents include the PRD, visual direction, UI/UX, architecture, time engine, roadmap, requirements, and testing. Readability, Reduce Motion, compact notch geometry, and reliable lifecycle behavior remain acceptance concerns. This decision authorizes a documentation update, not application implementation.

## Decision record template

When a choice changes, append a dated record with status, context, decision, alternatives, consequences, affected requirement IDs, and supporting evidence. Keep prior records readable and mark superseded decisions explicitly. Do not mark a proposal accepted merely because implementation follows it.
