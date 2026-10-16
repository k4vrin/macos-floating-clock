# Implementation roadmap

> Implemented addition, 2026-10-16: [Right-side widgets](RIGHT_SIDE_WIDGETS.md) documents reusable calendar and AI usage items, independent slot selection, Codex app-server refresh, and the Claude status-line bridge.


> Implemented update, 2026-10-16: [Clock packs](CLOCK_PACKS.md) defines the digital clock and installable multi-clock sets. It supersedes earlier exclusions of clock packs or a second clock design. Version 1 uses native renderer templates and declarative JSON.


## Visual delivery priority, 2026-10-16

The owner is creating this project primarily for its aesthetics, rich UI components, and animations. A visually distinctive result is a central product goal. Treat clock faces, materials, depth, expressive details, and compact-to-expanded motion as core design work, with readability and accessibility built into that work.

Before the original implementation milestones below, define compact/expanded compositions and motion studies for expansion, collapse, and face switching. Pair the notch feasibility experiment with an early prototype of one expressive face and its transitions. Include visual and motion review in the first usable milestone rather than postponing aesthetics until final polish.

Later acceptance must check transition interruption, reduced-motion behavior, frame pacing during animation, and energy after returning to rest. The detailed milestone sequence below still needs the coordinated notch revision; its text-only starting point is superseded.

> Direction update, 2026-10-15: [Inspiration and notch bar direction](INSPIRATION.md) records the owner's latest concept and takes precedence over conflicting statements here. This document describes the earlier floating-clock baseline and needs revision before implementing the notch bar.

Status: proposed sequence, no milestones started. This plan does not authorize source implementation, create a repository, or reserve time in the learning schedule. No delivery dates are assumed.

## M0: Validate window behavior

Once implementation is authorized, create a small disposable AppKit experiment in the chosen source workspace. Test a transparent nonactivating panel, ordinary-window stacking, menu access, drag focus, desktop Spaces, Stage Manager, and full-screen transitions on the reference Mac. Test actual behavior without Accessibility or Screen Recording grants.

Record the OS build, app activation policy, style masks, collection behavior combination, and results. Compare the proposed modern collection behavior with an auxiliary full-screen configuration where useful. Exit when ordinary-window visibility/focus works and full-screen limitations are explicit. If the required behavior fails, revise ADR-003 before proceeding.

## M1: Deliver a useful clock

Create the separate source repository and AppKit target after the source location is selected. Add one panel, current local time, 12/24-hour selection, menu-bar Settings/Show-Hide/Quit, and boundary-based updates without seconds. Use default typography. Add deterministic formatting tests and verify typing focus in other apps.

Exit with FR-001 to FR-004 and FR-007 working on the reference Mac. No customization framework is needed.

## M2: Make it resilient

Add drag placement, versioned defaults, reset position, display recovery, wake/time-zone/locale handling, and desktop Spaces policy from M0. Exercise corrupt preferences and monitor removal. Cancel timers while hidden or sleeping.

Exit with FR-005 and FR-008 to FR-011 evidence. Record unresolved full-screen contexts as release limitations for review.

## M3: Add readable customization

Add installed fonts, size, opacity, and color modes in native AppKit Settings. Finish keyboard placement controls, current-time accessibility fallback if necessary, and VoiceOver verification. Check scaled and mixed-resolution displays. Re-measure frame size when appearance settings change.

Exit with FR-006 and NFR-007/NFR-008 evidence and no clipped supported clock strings.

## M4: Complete first-release options

Add optional seconds/date and opt-in `SMAppService.mainApp` login behavior. Run boundary-lateness tests and real installed-app login tests, including approval-needed/error states and external disabling.

Exit with FR-012/FR-013 evidence and confirmed timer cadence in both modes. Choose distribution/signing before treating login behavior as release-ready.

## M5: Verify and package

Run the full acceptance matrix and performance protocol. Fix failures or revise a proposed budget with measurements and rationale. Record supported OS builds, known limitations, signing/install instructions, and final bundle metadata. Verify FR-014 and every NFR.

Exit with a tagged, reproducible source revision and evidence from a signed installed build suitable for the chosen channel. Public publication is a separate user action.

## Later candidates

Only after the clock release, evaluate a solid compact pill or material background, click-through with a recoverable lock command, notch-adjacent placement, multiple clocks, widgets, and Intel verification if needed. Media controls, weather, cloud sync, and plugin systems need their own PRD rather than extending this one by default.
