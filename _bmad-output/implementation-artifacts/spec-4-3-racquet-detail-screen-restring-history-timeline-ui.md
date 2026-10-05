---
title: 'Story 4.3: Racquet Detail Screen & Restring History Timeline UI'
type: 'feature'
created: '2026-10-05'
status: 'ready-for-dev'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-4-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Tennis players cannot inspect the detailed lifecycle, tension decay metrics, or past stringbed performance of individual racquets. While Story 4.1 persisted `RestringEvent` records and Story 4.2 enabled 1-tap restrings, there is no UI to view a racquet's full history to evaluate string durability, longevity, and tension choices.

**Approach:** Add `installedTension` to `RestringEvent` on the backend so historical snapshots capture installed tension. In Flutter, wire `RacquetCard.onTap` to push a dedicated `RacquetDetailScreen` featuring an "Overview" tab (specs, radial health gauge, wear stats, tension decay estimator, and `[Restrung Today]` action) and a "History" tab (chronological timeline of past stringbeds with dates, string description, court hours, days active, retired health score, and installed tension).

## Boundaries & Constraints

**Always:**
- Tapping any `RacquetCard` in the Virtual Bag list or grid navigates to `RacquetDetailScreen` for that racquet.
- `RacquetDetailScreen` includes two tabs: "Overview" and "History", adhering to the Court Midnight theme and 8-point spatial grid.
- The "Overview" tab displays: racquet name, primary indicator, string brand/model, material category, installed tension, stringing date, `RadialHealthGauge`, logged court hours, remaining rated hours, tension decay estimate text via `DecayEngine.calculateTensionLossText`, and `_buildRestrungButton` (reusing `RestringSheet.show`).
- The "History" tab queries `client.bag.getRestringHistory(racquetId: racquet.id!)` and renders a chronological timeline (newest to oldest).
- Each past stringbed timeline item displays: stringing and restring dates formatted (e.g. "Aug 10 – Oct 2"), string description (brand + model or category), final court hours (e.g. "18.5 court hours"), active days (e.g. "53 days active"), retired health score badge with matching health color (green >=70%, amber 40-69%, red <40%), and installed tension (e.g. "52.0 lbs" or "—" if not set).
- Empty state: When a racquet has no prior restrings, the History tab displays a friendly empty state ("No past restrings recorded for this racquet yet. Restring history will appear here once you retire your first stringbed.").
- Real-time reactivity: Wrap `RacquetDetailScreen` with a `BlocBuilder<BagBloc, BagState>` so if a restring occurs or bag updates, the screen immediately reflects updated active specs and invalidates/reloads history.
- Backend schema: Add `installedTension: double?` to `restring_event.spy.yaml`, generate migration, and record `oldJob.installedTension` in `restringRacquet`.

**Never:**
- Never block or crash if `getRestringHistory` fails; display an error state with a `[Retry]` button.
- Never lose navigation context; provide a standard AppBar back button returning cleanly to `VirtualBagScreen`.
- Never mutate or delete historical `RestringEvent` records from the client.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Navigate to Detail | Tap `RacquetCard` in Virtual Bag | Opens `RacquetDetailScreen` with Overview tab selected; shows current specs & gauge | N/A |
| Switch to History Tab | Tap "History" tab | Fetches `getRestringHistory(racquetId)` and displays chronological timeline nodes | Shows loading spinner while in-flight |
| Restring History Present | Racquet with >=1 retired stringbeds | Renders timeline items newest to oldest with date range, description, hours, active days, retired health badge, and tension | N/A |
| Empty Restring History | Brand new racquet with 0 restrings | Renders clean empty state card with explanatory copy | N/A |
| Restring via Detail Screen | Tap `[Restrung Today]` on Overview tab | Opens `RestringSheet`; upon completion, Overview updates to 100% and History tab refreshes | Error SnackBar on failure (from BagBloc) |
| History Fetch Network Error | `getRestringHistory` RPC throws | History tab displays inline error message and a `[Retry]` button | Tap retry re-executes fetch |
| Missing Installed Tension | Past event with `installedTension == null` | Gracefully displays string description and other metrics without crashing; tension badge omitted or displays "—" | Handled defensively |

</frozen-after-approval>

## Code Map

- `string_theory_server/lib/src/models/restring_event.spy.yaml` -- Add `installedTension: double?` field.
- `string_theory_server/migrations/` -- Generate Serverpod migration for `restring_event.installedTension`.
- `string_theory_server/lib/src/endpoints/bag_endpoint.dart` -- In `restringRacquet`, assign `installedTension: oldJob.installedTension` when building `RestringEvent`.
- `string_theory_client/lib/src/protocol/restring_event.dart` -- Updated by `serverpod generate` with `installedTension`.
- `string_theory_flutter/lib/screens/racquet_detail_screen.dart` -- New screen widget with `TabBar` ("Overview", "History"), `BlocBuilder<BagBloc, BagState>` integration, overview stats panel, and restring trigger.
- `string_theory_flutter/lib/widgets/timeline/restring_timeline_tile.dart` -- Dedicated timeline item widget rendering date range, string description, court hours, days active, retired health score badge, and installed tension badge.
- `string_theory_flutter/lib/widgets/bag/bag_racquet_list.dart` -- Wire `RacquetCard(onTap: () => Navigator.of(context).push(...))` to open `RacquetDetailScreen`.
- `string_theory_server/test/integration/bag_endpoint_test.dart` -- Update integration tests to verify `installedTension` persistence and retrieval in `getRestringHistory`.
- `string_theory_flutter/test/screens/racquet_detail_screen_test.dart` -- Unit and widget tests for `RacquetDetailScreen` (overview stats, tab switching, history timeline rendering, empty state, retry on error).
- `string_theory_flutter/test/widgets/racquet_card_test.dart` -- Verify `onTap` callback triggers navigation.

## Tasks & Acceptance

**Execution:**
- [ ] `string_theory_server/lib/src/models/restring_event.spy.yaml`, `bag_endpoint.dart` -- Add `installedTension: double?`, generate code and migration, populate in `restringRacquet`.
- [ ] `string_theory_server/test/integration/bag_endpoint_test.dart` -- Write failing test verifying `installedTension` on `RestringEvent` (red), run tests to turn green.
- [ ] `string_theory_flutter/lib/widgets/timeline/restring_timeline_tile.dart` -- Implement timeline card widget with date range, stats, health badge, and tension badge.
- [ ] `string_theory_flutter/lib/screens/racquet_detail_screen.dart` -- Implement `RacquetDetailScreen` with Overview and History tabs, real-time bloc reactivity, error & retry handling.
- [ ] `string_theory_flutter/lib/widgets/bag/bag_racquet_list.dart` -- Connect `RacquetCard.onTap` to navigate to `RacquetDetailScreen`.
- [ ] `string_theory_flutter/test/screens/racquet_detail_screen_test.dart` -- Widget tests covering overview specs, history timeline rendering, empty states, tab switching, error retry.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` -- Update story status to `review` during build and `done` upon completion.

**Acceptance Criteria:**
- Given a user viewing their Virtual Bag, when tapping any racquet card, then the app navigates into `RacquetDetailScreen` showing the racquet name and Overview tab.
- Given the "Overview" tab, when inspected, then it displays the active string specs, `RadialHealthGauge`, court hours logged, remaining hours, tension decay estimate, and `[Restrung Today]` action.
- Given the "History" tab, when the racquet has past restrings, then it displays a chronological timeline of past string jobs with date ranges (e.g. "Aug 10 – Oct 2"), string description, final court hours, final days active, retired health score badge, and installed tension.
- Given the "History" tab, when the racquet has no past restrings, then it displays an empty state explaining that past restrings will appear after the first restring.
- Given a network error while fetching restring history, then the screen shows an error message and a `[Retry]` button that successfully refetches upon tapping.

## Implementation Notes

## Spec Change Log

## Review Triage Log

## Design Notes

- **Court Midnight Aesthetic**: Uses `CourtMidnightTheme.surface` cards with `surfaceBorder` 1px outlines, `primaryVolt` active tab indicator, and `GoogleFonts.barlowCondensed` headings.
- **Timeline Visual Language**: Nodes connected by subtle 2px vertical lines (`surfaceBorder`), with node bullets colored by the retired stringbed's final health category (Green `#10B981`, Amber `#F59E0B`, Red `#EF4444`).
- **Date Formatting**: Pure Dart date formatting helper (or standard `intl`) without introducing heavy external dependencies.

## Verification

**Commands:**
- `dart test test/integration/bag_endpoint_test.dart` (in `string_theory_server`) -- expected: All server tests pass with 0 errors.
- `flutter test` (in `string_theory_flutter`) -- expected: All widget and unit tests pass with 0 errors.
- `dart analyze` (across both packages) -- expected: 0 warnings and 0 errors.
- `dart format --output=none --set-exit-if-changed .` -- expected: Clean formatting.
