---
title: 'Update stale planning copy in SessionsPlaceholder'
type: 'chore'
created: '2026-10-06'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The Sessions tab (`SessionsPlaceholder`, `string_theory_flutter/lib/widgets/bag/sessions_placeholder.dart:46`) tells users "Session logging & Apple Health sync coming soon in Epic 2." That leaks internal planning vocabulary and is false: manual session logging (+ Log Session FAB on the Bag tab) and Apple Health / Health Connect workout detection have shipped. Source: Epic 4 retro action item 13 (`epic-4-retro-item-13-update-stale-planning-copy-in-sessionspl`).

**Approach:** Replace only the body copy with accurate, user-facing text that says a session history view is not available yet and points users to what works today: logging a match with + Log Session on the Bag tab, and automatic detection of Apple Health / Health Connect tennis workouts. Keep the "COURT SESSIONS" heading, icon and layout. No new Sessions screen (that remains future work). Add a widget test asserting the new copy and the absence of "Epic" wording, then mark the sprint-status action item done.

</frozen-after-approval>

## Implementation Notes

- Final copy (revised after review): "Your session history will appear here. Add a racquet, then log a match with + Log Session on the Bag tab. On iPhone and Android, tennis workouts from Apple Health or Health Connect are detected for you to assign." Body text capped at 420 px wide.
- Files: `string_theory_flutter/lib/widgets/bag/sessions_placeholder.dart` (copy), `string_theory_flutter/test/virtual_bag_screen_test.dart` (assert copy in existing Sessions-tab navigation test), `_bmad-output/implementation-artifacts/sprint-status.yaml` (item 13 → done).
- TDD: the new assertions failed against the old copy (red), then passed after the copy change (green). `dart analyze` clean; full `flutter test` passed (365 tests).

## Review Triage Log

- Empty bag hides + Log Session (`_buildFab` requires `hasRacquets`) — medium, patched: copy now says "Add a racquet, then...".
- "Picked up automatically" false on web/desktop (`createHealthSyncService` returns the simulated service; `syncWorkouts()` returns `[]`) — medium, patched: copy is scoped to iPhone and Android.
- Mobile detection is not fully automatic (needs Health access; user assigns the racquet) — low, patched in the same copy fix ("detected for you to assign").
- Both health platforms are named on every device — low, rejected: needs platform-dependent copy for little gain, and the new wording ties each service to its platform.
- No action button or link from the placeholder — medium, deferred (new UI, beyond a copy fix).
- "+ Log Session" label duplicated in copy and test — low, rejected: a shared constant adds API for a rare rename.
- Copy only asserted on the bottom-nav path — low, rejected: rail, drawer and bottom nav all render the same `SessionsPlaceholder`.
- Negative check too narrow — low, patched: also asserts that "coming soon" is absent.
- Spec status contradicts the tracker — false: the spec had not been finalized yet when the review ran.
- No TDD/verification record — low, patched by the note above.
- Tracker has no link to the resolving spec — low, rejected: matches how the other done items are recorded.
- Long line on desktop — low, patched: maxWidth 420.
- Doc comment incomplete — low, rejected: it is still accurate.
