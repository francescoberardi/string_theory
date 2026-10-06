---
title: 'Story 5.2: Keyboard Shortcuts & Desktop Mouse Hover States'
type: 'feature'
created: '2026-10-06'
status: 'done'
baseline_commit: '986e37110287fb744f64f1b277e410843de09293'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-5-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Navigating the app on web or desktop requires clicking or tapping small UI buttons, lacking desktop accelerator keys (`L`, `N`, `S`, `Esc`) and visual affordances like hover elevation and border glow micro-interactions on racquet cards.

**Approach:** Implement global desktop/web keyboard shortcuts (`L` -> Log Session, `N` -> New Racquet, `S` -> Simulate Workout, `Esc` -> close active dialog/sheet) scoped to ignore typing in text inputs, and add interactive mouse hover effects to `RacquetCard` with subtle elevation and electric volt border glow.

## Boundaries & Constraints

**Always:**
- Wire global keyboard accelerators `L`, `N`, `S`, `Esc` on `VirtualBagScreen` using Flutter's `Shortcuts` and `Actions` (or `CallbackShortcuts`).
- Ensure shortcuts `L`, `N`, `S` do NOT fire when a text editing field (e.g. search, add racquet form, workout notes) currently has primary focus.
- When `Esc` is pressed, close any active modal bottom sheet or dialog route via `Navigator.maybePop(context)`.
- When `L` is pressed, open `WorkoutAssignmentSheet` in manual log mode (or prompt if bag is empty / unstrung).
- When `N` is pressed, open `AddRacquetModal`.
- When `S` is pressed, trigger workout simulation via `HealthSyncService.simulateWorkout()` (if supported by active service).
- In `RacquetCard`, support cursor hover states (`MouseRegion` / `InkWell.onHover`): slightly elevate or translate card, and brighten border to volt glow (`primaryVolt.withValues(alpha: 0.6)`) or intensified critical border when in critical health.
- Maintain full compatibility with touch devices, mobile viewports, and existing widget tests.

**Never:**
- Do not trigger keyboard shortcuts when typing letters inside `TextField` or `TextFormField`.
- Do not break existing modal bottom sheet behaviors on mobile or tablet.
- Do not modify backend models, endpoints, or database tables.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Keyboard 'L' pressed on Bag screen | User presses key 'L' with racquets loaded | Manual `WorkoutAssignmentSheet` opens immediately. | If bag has no racquets or unstrung racquets, display standard warning SnackBar. |
| Keyboard 'N' pressed on Bag screen | User presses key 'N' | `AddRacquetModal` opens immediately. | N/A |
| Keyboard 'S' pressed on Bag screen | User presses key 'S' with simulation supported | `simulateWorkout()` triggered on `HealthSyncService`. | Ignore silently if simulation not supported or unavailable. |
| Keyboard 'Esc' pressed with modal open | User presses 'Escape' key while modal/sheet is open | Modal/sheet dismissed cleanly (`Navigator.pop`). | N/A |
| Keyboard shortcut inside text input | User types 'l', 'n', or 's' inside `AddRacquetModal` name input | Character typed into field without triggering root shortcuts. | Handled via Flutter focus checking (`FocusManager.instance.primaryFocus`). |
| Mouse hover over RacquetCard | Desktop cursor hovers over card | Card border glows with volt accent (`primaryVolt`), cursor changes to click pointer, card elevates subtly. | Reverts smoothly on mouse exit. |

</frozen-after-approval>

## Code Map

- `string_theory_flutter/lib/screens/virtual_bag_screen.dart` -- Global keyboard shortcut listener/wrapper with `CallbackShortcuts` or `FocusableActionDetector` handling `L`, `N`, `S`, and `Escape`, guarded against active text editing focus.
- `string_theory_flutter/lib/widgets/racquet_card.dart` -- Add stateful or `MouseRegion` hover detection to elevate container and render volt border glow (`primaryVolt`) on hover.
- `string_theory_flutter/test/widgets/racquet_card_test.dart` -- Unit/widget tests verifying hover border glow and elevation changes on pointer hover event.
- `string_theory_flutter/test/virtual_bag_screen_test.dart` -- Widget tests verifying keyboard shortcuts `L`, `N`, `S`, `Escape`, and ensuring focused text fields don't accidentally dispatch shortcuts.

## Tasks & Acceptance

**Execution:**
- [x] `string_theory_flutter/lib/widgets/racquet_card.dart` -- Add mouse hover state handling (e.g. `_isHovered` or `InkWell(onHover: ...)`) applying enhanced border glow (`primaryVolt` with glow / elevated shadow) and pointer cursor on desktop/web.
- [x] `string_theory_flutter/lib/screens/virtual_bag_screen.dart` -- Wrap screen body or Scaffold in `CallbackShortcuts` / `Focus` mapping `LogicalKeyboardKey.keyL`, `keyN`, `keyS`, and `escape` to respective modal/simulation/pop actions, bypassing when `primaryFocus` is a text input.
- [x] `string_theory_flutter/test/widgets/racquet_card_test.dart` -- Add widget tests simulating mouse hover enter/exit on `RacquetCard` and asserting border styling changes.
- [x] `string_theory_flutter/test/virtual_bag_screen_test.dart` -- Add widget tests simulating keyboard presses `L`, `N`, `S`, and `Escape`, verifying sheet opening, modal opening, simulation triggering, and modal dismissal.

**Acceptance Criteria:**
- Given the app running on web or desktop,
- When the player hovers the cursor over a racquet card,
- Then the card elevates slightly and the border glow brightens,
- And pressing `L` opens the Quick Logger,
- And pressing `N` opens the Add Racquet modal,
- And pressing `S` triggers the workout simulator,
- And pressing `Esc` closes any open dialog or sheet.

## Implementation Notes
- Added `CallbackShortcuts` and autofocus `Focus` node wrapper at `VirtualBagScreen` root mapping `LogicalKeyboardKey.keyL`, `keyN`, `keyS`, and `escape`.
- Added `_isTextEditingActive()` guard using `FocusManager.instance.primaryFocus` inspecting `EditableText` ancestor widget to ensure typing in text fields doesn't trigger global actions.
- Refactored `RacquetCard` to stateful with `MouseRegion` and `InkWell.onHover`, smoothly animating border color to `primaryVolt.withValues(alpha: 0.6)` with elevated box shadow and pointer cursor.
- Added unit/widget tests covering mouse pointer enter/exit styling transitions and all keyboard accelerators + text editing suppression.

## Spec Change Log

## Review Triage Log

## Design Notes

- **Keyboard Handling Pattern**:
  Use `CallbackShortcuts` at the root of `VirtualBagScreen` with `Focus` or check `FocusManager.instance.primaryFocus?.context?.widget is EditableText` (or `primaryFocus is FocusNode && primaryFocus.context?.findAncestorWidgetOfExactType<EditableText>() != null`) so letter shortcuts don't intercept form typing.
- **Escape Key Handling**:
  `LogicalKeyboardKey.escape`: invoke `Navigator.maybePop(context)` so active sheets, dialogs, or sub-routes close cleanly.
- **Card Hover Animation**:
  Use `AnimatedContainer` or `StatefulWidget` in `RacquetCard` with a 150ms ease curve for border color transition (`surfaceBorder` -> `primaryVolt.withValues(alpha: 0.6)`) and subtle `BoxShadow` glow.
