# Spine Pair Review — string_theory

## Overall verdict
**Adequate, not yet a clean contract.** The pair is lean, follows the canonical shape, resolves every `{token}` reference, and gives all four PRD journeys a Key Flow with a protagonist and a climax. Seven high findings stand between it and a story-ready contract. DESIGN.md states no contrast targets, and two load-bearing pairs fail WCAG AA: the sync marker and the destructive button. DESIGN.md has no rule for which Material 3 defaults it inherits, and gives no visual spec for about half the components EXPERIENCE.md names. The racquet card drops fields FR-6 requires. Health-tier labels use three different vocabularies. The deletion-URL decision contradicts PRD OQ-3.

## 1. Flow coverage — adequate
Checked: sources = PRD `UJ-1`..`UJ-4` (prd.md L43–87) plus every FR that has a user-facing surface (FR-1..FR-8, FR-10, FR-12, FR-15..FR-17, FR-20). EXPERIENCE.md has Flows 1–4 mapped to UJ-1..UJ-4, plus Flow 5 for FR-7/FR-8. Every flow has a named protagonist, numbered steps and a bolded climax. Flows 2 and 4 have failure paths.

### Findings
- **high** The Racquet Card, and Racquet Detail too, does not show the content FR-6 and the UJ-1 climax require. FR-6 (prd.md L159) requires the bag to show *hours played* and *calendar days elapsed*. The UJ-1 climax (prd.md L51) shows `~1.4 lbs tension drop. 11 court hours remaining before dead zone.` on the bag. DESIGN.md → Racquet Card (L193–198) shows only the gauge, remaining hours, name, brand and tension. The Racquet Detail IA (EXPERIENCE.md L36–37) also omits hours played and days elapsed. Hours played appears only in the gauge's semantics label (L137). Flow 1's climax (L164) replaces the PRD line with the snackbar. *Fix:* add hours played, days elapsed and the tension-loss/remaining line to the Racquet Card visual spec and to Flow 1's climax. Or record the deviation and get PRD sign-off.
- **medium** Flows 1, 3 and 5 have no `Failure:` line, although the architecture defines failures for them. AD-6/AD-14: a session against a racquet deleted on another device is rejected, and a second offline restring of the same job is rejected (EXPERIENCE.md L155–165, L181–192, L206–214). *Fix:* add a one-line failure for each that points to the `Late write rejection` state, with the restring-rejection copy.
- **medium** FR-3 Sign-out has no flow, component row or state. It appears only in the IA (L46), as an entry to Welcome (L54), and in an open question (L219). The destination, any confirmation, and whether a snackbar shows are all uncommitted. *Fix:* add a `Sign Out` row to Component Patterns and a `Signed out` state on Welcome, even if the pending-writes warning stays open.
- **low** Flow titles paraphrase the UJ names. For example, "Marco logs playtime after a match" vs PRD "Marco Logs Playtime in 5 Seconds After a Match", and "A Play Store user deletes their account" vs "Play Store User Exercises Mandatory Account Deletion" (L155, L181, L194). *Fix:* use the PRD titles verbatim.
- **low** The example figures don't satisfy FR-9 (most are inherited from the PRD). Monofilament after 3 weeks gives 92%, not 88% (L176). 19 h and 70 days on mono gives about 6%, not 34% (L183). 84% with 12 h played is impossible at a 20 h max (L137). Widget tests copied from these figures will fail. *Fix:* mark the numbers as illustrative, or recompute them with the engine.

## 2. Token completeness — adequate
Checked: all 14 `colors` (hex present; the theme is declared dark-only at L126, so no light/dark pairs are needed), 7 `typography` roles (each one complete), 5 `rounded`, 6 `spacing`, and 9 `components`. Every `{path}` reference in the frontmatter and the prose resolves (`colors.primary/background/surface/surface-elevated/surface-border/...`, `typography.metric-hero`, `spacing.touch-min`, `rounded.lg/md/full`). The hex values match `court_midnight_theme.dart`. Contrast ratios below were computed with the WCAG 2.x formula.

### Findings
- **high** No contrast targets are stated anywhere in DESIGN.md. EXPERIENCE.md → Accessibility Floor says "Visual contrast lives in DESIGN.md" (L132), so that pointer resolves to nothing. *Fix:* add a contrast table for the load-bearing pairs (body/secondary/tertiary text on each surface, `on-primary`/`primary`, button labels, health colors on `surface` and `health-critical-bg`, focus ring), with an AA target for each.
- **high** `text-tertiary` (`#606B70`) carries the sync-pending marker (L141, L161, L198, frontmatter `sync-pending-marker`) at 12 px. Its contrast is 3.07:1 on `surface`, 3.17:1 on `health-critical-bg` and 2.72:1 on `surface-elevated`, all below AA's 4.5:1. The Don'ts (L234) make this text the *only* signal of sync state. *Fix:* render the marker in `text-secondary` (7.06:1), or lighten `text-tertiary` to about `#848F94` (≥ 4.49:1 on every surface).
- **high** The `button-destructive` label is `text-primary` on `health-critical`, which is 3.76:1 and fails AA for a 14 px label (frontmatter L97–101, used by Delete Account / Delete Racquet). *Fix:* use `on-primary` black (5.58:1), or add a darker destructive fill (for example `#C81E1E`, 5.74:1 with white).
- **medium** The Colors rationale contradicts itself. L147 says red-for-dead-strings and red-for-destructive "don't meet on one surface", yet it puts Delete Racquet on Racquet Detail, which also shows a `health-critical` gauge for dead racquets. *Fix:* restate the rule, for example "destructive red appears only inside the confirmation dialog", and specify how the Delete Racquet app-bar item and the Settings Delete Account trigger are styled.
- **medium** Component boundaries fail 1.4.11. `surface-border` is 1.26:1 on `surface`. An unselected `duration-chip` (`surface` on a `surface-elevated` sheet, 1.13:1) has no 3:1 boundary. *Fix:* state a non-text contrast rule for interactive outlines, or give unselected chips a `text-tertiary`-or-lighter border.
- **medium** The prose specifies values that have no tokens: the secondary outlined button (`primary-muted`, L212), the text `Cancel` button, snackbar, dialog, badges (`⚠ Restring`, `Primary`), the navigation active indicator, the inline error text color for the sign-in failure messages, the Level 3 scrim color, the Level 2 glow (12% / 16 px), and the gauge animation duration/curve. *Fix:* add `components` entries (`button-secondary`, `button-text`, `snackbar`, `dialog`, `badge-critical`, `badge-primary`, `nav-indicator`) and a small `motion` note.
- **medium** No token-to-Flutter mapping. The shipped theme names `primary` as `primaryVolt`, maps Barlow and Inter onto Material `TextTheme` slots rather than the 7 named roles, and has no `data`/JetBrains Mono role. A developer mirroring the spine can't tell which `TextTheme` slot or `ThemeExtension` field each token becomes. *Fix:* add a three-column table (token → `CourtMidnightTheme` constant → `TextTheme` slot / `ThemeExtension` field), and note that `data` needs a new extension field.
- **low** `rounded.sm` (6px) and `rounded.xl` (24px) are defined but never used (L60, L63). *Fix:* assign them or remove them.
- **low** The prose mixes `{colors.x}` references with bare names (`health-optimal`, `card-title`, `body-secondary`, `primary-muted`; L190–224). *Fix:* use `{path}` syntax consistently so the references can be machine-extracted.

## 3. Component coverage — thin
Checked: the union of component names across both spines. Rows in both DESIGN.Components and EXPERIENCE.Component Patterns: Radial Health Gauge, Racquet Card, Bag Sync Summary, Quick-Log Sheet, Restrung Today Sheet, destructive Confirmation Dialog, Snackbar, Google Sign-In button (Welcome). EXPERIENCE-only: Add Racquet form, Racquet Detail app bar, Restring history timeline, Session feed (with filter chips). Named but in neither table: FAB `[+ Log Session]`, navigation bar/rail/drawer, tier labels, `Primary` badge, skeleton card, empty-bag illustration, Settings rows, Edit Racquet form. DESIGN-only parts (duration chip, racquet selector, reason chips, sync-pending marker) have their behavior folded into parent rows, which is acceptable.

### Findings
- **high** DESIGN.md never says which components inherit Material 3 defaults. Unlike the shadcn example's "uses these as-is" list, it gives no rule. It also has no visual spec for the Add Racquet form (text fields, material picker control, date picker, inline validation), Racquet Detail layout and app bar, Restring history timeline, Session feed and filter chips, FAB, navigation bar/rail/drawer, tier labels and `Primary` badge, skeleton and empty state, or the Settings rows, including the Delete Account trigger. A story developer must invent visuals for UJ-2's main screen. *Fix:* add an "Inherited from Material 3 via `CourtMidnightTheme`, unchanged" list, and short specs for the brand-specific ones (form, timeline row, session row, badges, FAB).
- **medium** The FAB has no behavioral row. Its visibility (hidden on an empty bag is an [ASSUMPTION]), scroll behavior, and placement when the rail or drawer replaces the bottom bar (medium/expanded) are all unstated (EXPERIENCE.md L32, L107, L144–148). *Fix:* add a `Log Session FAB` row to Component Patterns.
- **medium** No ordering rule for the racquet cards in the bag or the racquets in the Quick-Log selector (primary first? `createdAt`? name?). That's a visible, testable decision (EXPERIENCE.md L28, DESIGN.md L206). *Fix:* commit to one order, for example `resolvePrimary` first and then `createdAt` ascending.
- **low** The gauge diameter and its behavior at 200% text scale are unspecified. `metric-hero` at 28 px inside a fixed ring will clip (DESIGN.md L188–191, EXPERIENCE.md L136). *Fix:* state the diameter per width class and say whether the gauge text scales or is clamped.

## 4. State coverage — adequate
Checked per IA surface. Welcome covers cancelled, failed, popup blocked, signing in and post-deletion. Bag covers restored, uncached load, first sign-in, empty, pending, offline, late rejection, dead and deleted. Settings covers re-auth cancelled, account mismatch, and deletion failed and succeeded. Permission-denied is correctly N/A (no runtime permissions, L150). The gaps are below.

### Findings
- **medium** Sessions has no states: initial load, empty (`no sessions yet`), filtered-empty (racquet chip with zero sessions), and a load-more/paging pattern. Architecture → Deferred leaves the page size to the `sessions` story, but the UX pattern belongs here (L41–43, L61, L94). *Fix:* add four Sessions rows to State Patterns.
- **medium** Racquet Detail has no loading or not-found state, and nothing for a racquet deleted on another device while the detail is open (`watchRacquet(id)` emits nothing). This also covers a web deep link to a deleted id. The only related row covers the user's own delete (L119). *Fix:* add `Racquet removed elsewhere → pop to bag + snackbar` and `Loading`.
- **medium** The Restrung Today prompt `Restrung with the same setup ({brand} @ {tension} lbs)?` (L91) breaks when brand or tension is absent, and both are optional per FR-5 and AD-3. The timeline entry format (L93) has the same problem without a brand. *Fix:* give fallback copy for each missing-field combination.
- **medium** The web focus state is underspecified. Focus reuses the Level 2 treatment, a 12%-opacity Volt glow (DESIGN.md L177), which is unlikely to meet the WCAG 2.2 focus-visible bar. No focus ring token exists. *Fix:* specify a 2 px `primary` focus outline (12.79:1 on `surface`) for keyboard focus, separate from hover.
- **low** For the Add Racquet form, "out-of-range values are blocked inline" (L90) doesn't name the AD-3 bounds (name 1–100, tension 20–80, maxHours >0–200), the error copy, what happens when Max court hours is cleared (AD-15 says it is never null), or whether dismissing with unsaved input asks first. *Fix:* reference `schema_bounds` and add those three rules.
- **low** Under AD-4, a racquet that fails to decode silently disappears from the bag. No user-facing treatment is stated. *Fix:* state explicitly that it is "silent by design", or add a treatment.
- **low** The `L`/`N` shortcuts (L126) have no guard against firing while a text field has focus. *Fix:* add "ignored while a text input has focus".

## 5. Visual reference coverage — thin
Checked: `mockups/` and `wireframes/` are absent, and `imports/` is empty. The one file is `string_theory_mockup.jpg`. It is linked once per spine (DESIGN.md L236, EXPERIENCE.md L221), and each file states once that the spines win on conflict. No orphans.

### Findings
- **medium** The mockup is linked only at the end of each file, not inline at the sections it illustrates (DESIGN → Racquet Card and Radial Health Gauge; EXPERIENCE → IA / Virtual Bag), and neither link says what it shows. *Fix:* move the link to DESIGN → Components → Racquet Card as "bag screen, compact width: card anatomy and gauge styling only".
- **medium** The stated caveat is wrong and the real divergences aren't listed. DESIGN.md L236 says the image "may still show the removed Simulate Workout action", but it doesn't show that action. Here is what the image actually shows that a consumer could copy:
  - an iPhone frame, although iOS is out of scope
  - a 5-tab nav (Home/Bag/Activities/Insights/Profile) vs Bag/Sessions/Settings
  - `Recent: Single Match (Win)`, although match results are a PRD non-goal
  - a 45% card drawn orange with `Needs Restring!`, although FR-10 makes it Degraded/amber, and orange is not in the palette
  - no `[Restrung Today]` or quick-log actions on the cards
  - `New Racquet +` vs `[+ Add Racquet]`, and `ACTIVE` vs `Primary`
  - glowing resting cards vs Level 1 "no shadow"
  - a ¾-arc gauge with a knob
  - racquet photos, although AD-3 has no image field

  *Fix:* replace the caveat with this do-not-copy list.

## 6. Bloat & overspecification — strong
Both files are tight. The tables carry the load, and the DESIGN prose stays short. There is little source restatement.

### Findings
- **low** The IA is given twice: a text tree (L22–50) and a table (L52–63). *Fix:* keep the table and fold the tree's only extras (app-bar actions, Settings items) into the Purpose column, or keep the tree and drop the duplicate rows.
- **low** Leftover changelog text belongs in `.memlog.md`, not the contract: "The old `S` (Simulate) shortcut is removed." (EXPERIENCE.md L126), "`surface-border` follows the shipped theme value" (DESIGN.md L149), and the Simulate Workout caveat (DESIGN.md L236). *Fix:* delete them; the memlog already records them.
- **low** Some lines restate the sources: the Foundation paragraph on Firestore and live streams (L18), and the Android manifest permissions (L150, NFR-6). *Fix:* keep only the behavioral consequence ("no refresh control", "no permission prompt").

## 7. Inheritance discipline — adequate
Checked: `sources` resolve (both files exist; status `final`). UJ names are compared in §1. FR-10 thresholds match (≥70 / 40–69 / <40). Materials match AD-4 exactly. Racquet edit = name+notes matches AD-5. Sessions kept on racquet delete matches AD-5. The re-auth order matches AD-10. Late-rejection snackbar on the bag matches AD-14. The Analytics consent open question is carried over from the architecture spine.

### Findings
- **high** The health-tier labels use three vocabularies. FR-10 and EXPERIENCE → Radial Health Gauge (L88) say Optimal / Degraded / Dead. The Accessibility Floor (L135) says `✓ Optimal`, `~ Caution`, `⚠ Restring`. DESIGN.md says "caution state" (L143) and a `⚠ Restring` badge (L197). No surface visually renders the Optimal or Caution label, so the "never color alone" rule has no visual home. *Fix:* pick one label set, map it to the engine's `tier` enum, and say where each label renders (gauge micro-label or card badge) for all three tiers.
- **high** The Play Console deletion URL contradicts the PRD. EXPERIENCE.md points the Data Safety URL at static `/privacy.html`, which links into the app (L63, L151, L198). PRD OQ-3 (prd.md L305) says that URL points to the hosted Flutter Web app, which runs the deletion. FR-20 and UJ-4 leave this ambiguous. *Fix:* decide with the PM and either update OQ-3 or change the spine. If `/privacy.html` stays, name the exact in-app link target, for example `/settings`.
- **medium** Navigation and breakpoints drift from the decision log and Material 3. `.memlog.md` L7 decided "NavigationRail on tablet/web", but the spine uses a persistent drawer at expanded width (L148), and no memlog entry records the change. The 600/1024 dp breakpoints also differ from Material 3 window classes (600/840) without rationale, so Flutter adaptive defaults will disagree. *Fix:* log the drawer decision, and either adopt the M3 840 dp breakpoint or state why 1024.
- **low** Field and action labels differ from the PRD glossary: "Racquet name" vs "Frame Name / Model", "Max court hours" vs "Manufacturer Max Hours", "Primary" vs "Primary in Bag", and "Delete Account & All Data" vs FR-4's "Delete Account & Data" (the PRD contradicts itself here). *Fix:* add one line saying these are deliberate UI labels for the glossary terms.
- **low** Component names differ between the files: "Quick-Log Sheet" vs "Quick-Log sheet", "Confirmation Dialog (destructive)" vs "Destructive confirmation dialog", "Welcome / Sign-In Screen" vs "Google Sign-In button". *Fix:* use identical names in both files.
- **low** FR-17 says "chronological", but EXPERIENCE says "Newest first" (L93). *Fix:* confirm reverse-chronological with the PM, or note the interpretation.
- **low** The reason chip → `endReason` mapping is implied, not stated (`Routine restring`→`manual_restring`, `Strings went dead`→`dead`, `Strings broke`→`broken`; L91, DESIGN L213). *Fix:* state the mapping and the timeline label for each value.
- **low** "the next racquet becomes the default automatically" (L119) is vaguer than AD-8. *Fix:* say "chosen by `resolvePrimary`".
- **low** EXPERIENCE gives touch targets as a literal "48 × 48 dp" (L134) instead of `{spacing.touch-min}`. *Fix:* reference the token.

## 8. Shape fit — strong
DESIGN.md sections are in canonical order (Brand & Style → Colors → Typography → Layout & Spacing → Elevation & Depth → Shapes → Components → Do's and Don'ts). EXPERIENCE.md has every required default. Responsive & Platform is present, as required for Android plus web across 3 width classes. The invented Open Questions section earns its place.

### Findings
- **low** Inspiration & Anti-patterns is omitted, although `.memlog.md` records rejects (L14 type-to-confirm, L18 the advanced-options accordion and the Working Offline banner). The Banned list (L128) covers only some of them. *Fix:* add a three-bullet "Rejected" list so future editors don't bring them back.
- **low** The visual-reference lines sit after the last canonical section in both files, and DESIGN frontmatter carries non-spec keys (`status`, `created`, `updated`, `mockup`). *Fix:* move the references inline (see §5). The extra keys are harmless.

## Mechanical notes
- **Cross-refs:** every `{path}` in DESIGN.md resolves. The DESIGN L171 → EXPERIENCE "Responsive & Platform", EXPERIENCE L127 → DESIGN "Level 2", and EXPERIENCE L88 → "PRD's FR-10" cross-refs resolve. **Broken:** EXPERIENCE L132 "Visual contrast lives in DESIGN.md": no contrast content exists.
- **Orphan tokens:** `rounded.sm` and `rounded.xl`.
- **Specs with no frontmatter entry:** Snackbar, Bag Sync Summary, Quick-Log Sheet, Restrung Today Sheet, Confirmation Dialog and Welcome have prose specs but no `components` key. `sheet`, `duration-chip` and `button-*` partly cover them.
- **Name inconsistencies:** see §7: component casing and wording, and the tier vocabulary (Degraded/Dead vs Caution/Restring).
- **Frontmatter:** EXPERIENCE `sources` holds 2 entries and both resolve. DESIGN has no `sources` key, which the spec doesn't require. Both files are `status: draft` and carry 9 open [ASSUMPTION]s (memlog L23). None blocks a downstream consumer by itself; the reason-chip labels and the `Deleted racquet` label are copy only.
- **Mermaid:** none in either spine. The IA uses a `text` tree, which renders correctly.
- **Theme parity:** all 14 color hexes match `court_midnight_theme.dart`. The shipped `TextTheme` has no JetBrains Mono / `data` role and none of the named type roles, so that work belongs in a theme story.
