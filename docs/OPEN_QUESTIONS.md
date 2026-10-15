# Open questions

> Direction update, 2026-10-15: [Inspiration and notch bar direction](INSPIRATION.md) records the owner's latest concept and takes precedence over conflicting statements here. This document describes the earlier floating-clock baseline and needs revision before implementing the notch bar.

Status: discussion agenda, 2026-10-15. Recommendations let planning proceed, but they are not owner approval. This phase creates documentation only.

| ID | Question | Recommended working assumption | Resolve by |
|---|---|---|---|
| Q-001 | Which macOS version is installed, and should the app support other versions? | Start with a proposed macOS 13 minimum; claim only tested versions. | Before app-target setup |
| Q-002 | What is the final app name, bundle identifier, and source-repository location? | Use macOS Floating Clock as a working title; keep source outside the vault. | Before creating a repository |
| Q-003 | Must the clock appear above another app in full screen, or is a documented limitation acceptable? | Require ordinary-window and desktop-Spaces behavior; assess full-screen results in M0 before making a release promise. | M0 exit |
| Q-004 | Is plain floating typography the preferred appearance? | Start with text only; evaluate a compact pill if actual wallpaper readability fails. | Before M3 styling |
| Q-005 | Should launch at login, date, and seconds ship in the first release? | Yes, as M4 options, all off by default. | Before committing release scope |
| Q-006 | Is one clock on one selected display enough? | Yes. Allow drag/move-to-display; defer duplicated clocks. | Before M2 placement work |
| Q-007 | Is click-through or a locked clock needed? | Defer. Default drag behavior remains straightforward and recoverable. | After first usability feedback |
| Q-008 | Is the 24-hour default suitable, and should the date follow the system calendar? | Use 24-hour by default and localized system calendar/date; support explicit 12-hour mode. | M1 formatting review |
| Q-009 | How will the app be distributed? | Local personal build first; choose Developer ID or App Store before release packaging. | Before M4 installed-login evidence and M5 |
| Q-010 | Which additional displays and OS environments are available for testing? | Verify built-in and an external display; mark unavailable combinations unverified. | Before compatibility claims |
| Q-011 | Are the proposed CPU, memory, and timing budgets appropriate on this Mac? | Use them as starting budgets and revise only with measurements. | M5 performance review |

## Technical uncertainties to close with evidence

- M0 must resolve passive dragging, focus retention, and the final collection-behavior combination. No official API name guarantees all full-screen cases.
- M1 must prove explicit 12/24-hour selection under locale preferences, including Persian/Arabic digits and localized day periods.
- M2 must verify display identity fallback with actual adapters, mirroring, and clamshell changes.
- M3 must verify how VoiceOver reaches the nonactivating overlay and whether the Settings readout is needed.
- M4 must confirm the login item's state and installed-bundle behavior with the selected signing setup.

## Suggested discussion order

First settle the intended everyday placement and full-screen expectation. Then confirm the owner's macOS version and visual preference. Repository naming and release distribution can follow before implementation reaches their decision gates. Performance budgets remain proposals until a working clock produces measurements.
