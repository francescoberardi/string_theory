# Validation Report — string_theory

- **DESIGN.md:** `_bmad-output/planning-artifacts/ux/ux-string_theory-2026-10-02/DESIGN.md`
- **EXPERIENCE.md:** `_bmad-output/planning-artifacts/ux/ux-string_theory-2026-10-02/EXPERIENCE.md`
- **Run at:** 2026-10-24T10:32

## Overall verdict

**Adequate, not yet a clean contract.** The pair is lean, follows the canonical shape, resolves every token reference, and gives all four PRD journeys a Key Flow with a protagonist and a climax. Seven high rubric findings stand between it and a story-ready contract: no contrast targets, two failing load-bearing pairs, no Material 3 inheritance rule, a racquet card missing FR-6 fields, three health-tier vocabularies, and a deletion-URL decision that contradicts PRD OQ-3.

The accessibility lens raises the two contrast failures to **critical**: `text-tertiary` text, which is the only signal of sync state, and the white-on-crimson destructive button on the Play-compliance path. It adds seven web and screen-reader gaps that the rubric could not see: no focus indicator, bare `L`/`N` shortcuts (WCAG 2.1.4), failures that live only in a 4-second snackbar, invisible text-field and chip outlines, unnamed card actions, Flutter web semantics off by default, and a card layout that cannot reflow at 200% text.


## Category verdicts

- Flow coverage — adequate
- Token completeness — adequate
- Component coverage — thin
- State coverage — adequate
- Visual reference coverage — thin
- Bloat & overspecification — strong
- Inheritance discipline — adequate
- Shape fit — strong

## Findings by severity

### Critical (2)

**[Accessibility]** — `text-tertiary` (#606B70) carries load-bearing 12px text and fails 1.4.3 on every surface (2.72–3.35:1). (§ DESIGN.md § Colors table, frontmatter `components.sync-pending-marker.text`, § Components → Racquet Card "Sync pending" and Bag Sync Summary, § Do's and Don'ts last bullet)
`text-tertiary` (#606B70) carries load-bearing 12px text and fails 1.4.3 on every surface (2.72–3.35:1). That text is the `Waiting to sync` marker on cards (Flow 1), the bag sync summary, hints/placeholders in the Add Racquet form (Flow 2) and unit labels. The Do/Don't "the pending marker is text in `text-tertiary`" locks the failure in, and the shipped `bodySmall` uses `textTertiary` too.
Fix: (in palette):* switch `sync-pending-marker.text`, the Bag Sync Summary, hints and unit labels to `text-secondary` (6.25–7.71:1). Narrow `text-tertiary`'s use to "disabled controls and purely decorative glyphs only", and update the Don't to "the pending marker is text in `text-secondary`, never a color change". *Fix (token change):* raise `text-tertiary` to #8A969B (≥ 4.90:1 on all four surfaces) if a third text tier must stay distinct. This also changes the shipped `bodySmall`.

**[Accessibility]** — The destructive button label (`text-primary` white on `health-critical`) is 3.76:1 and fails 1.4.3 on `Delete Account` (Flow 4, the Play-compliance path) and `Delete Racquet`. (§ DESIGN.md frontmatter `components.button-destructive.text`, § Components → Confirmation Dialog.)
The destructive button label (`text-primary` white on `health-critical`) is 3.76:1 and fails 1.4.3 on `Delete Account` (Flow 4, the Play-compliance path) and `Delete Racquet`. It also contradicts the PRD's "high-contrast confirmation modal" (prd.md line 84).
Fix: (in palette):* set `button-destructive.text` to `{colors.on-primary}` (#000000, 5.58:1), or add an `on-destructive` alias pointing at the same value. Dark text on light red matches the M3 dark-scheme `onError` convention. *Fix (token change):* add a separate `destructive` #DC2626 with white text (4.83:1, fill 3.08:1 against the dialog). That keeps `health-critical` for arcs and borders and decouples the two meanings the Colors section already worries about.

### High (14)

**[Rubric — Flow coverage]** — The Racquet Card, and Racquet Detail too, does not show the content FR-6 and the UJ-1 climax require.
The Racquet Card, and Racquet Detail too, does not show the content FR-6 and the UJ-1 climax require. FR-6 (prd.md L159) requires the bag to show *hours played* and *calendar days elapsed*. The UJ-1 climax (prd.md L51) shows `~1.4 lbs tension drop. 11 court hours remaining before dead zone.` on the bag. DESIGN.md → Racquet Card (L193–198) shows only the gauge, remaining hours, name, brand and tension. The Racquet Detail IA (EXPERIENCE.md L36–37) also omits hours played and days elapsed. Hours played appears only in the gauge's semantics label (L137). Flow 1's climax (L164) replaces the PRD line with the snackbar.
Fix: add hours played, days elapsed and the tension-loss/remaining line to the Racquet Card visual spec and to Flow 1's climax. Or record the deviation and get PRD sign-off.

**[Rubric — Token completeness]** — No contrast targets are stated anywhere in DESIGN.md.
No contrast targets are stated anywhere in DESIGN.md. EXPERIENCE.md → Accessibility Floor says "Visual contrast lives in DESIGN.md" (L132), so that pointer resolves to nothing.
Fix: add a contrast table for the load-bearing pairs (body/secondary/tertiary text on each surface, `on-primary`/`primary`, button labels, health colors on `surface` and `health-critical-bg`, focus ring), with an AA target for each.

**[Rubric — Token completeness]** — `text-tertiary` (`#606B70`) carries the sync-pending marker (L141, L161, L198, frontmatter `sync-pending-marker`) at 12 px.
`text-tertiary` (`#606B70`) carries the sync-pending marker (L141, L161, L198, frontmatter `sync-pending-marker`) at 12 px. Its contrast is 3.07:1 on `surface`, 3.17:1 on `health-critical-bg` and 2.72:1 on `surface-elevated`, all below AA's 4.5:1. The Don'ts (L234) make this text the *only* signal of sync state.
Fix: render the marker in `text-secondary` (7.06:1), or lighten `text-tertiary` to about `#848F94` (≥ 4.49:1 on every surface).

**[Rubric — Token completeness]** — The `button-destructive` label is `text-primary` on `health-critical`, which is 3.76:1 and fails AA for a 14 px label (§ frontmatter L97–101, used by Delete Account / Delete Racquet)
The `button-destructive` label is `text-primary` on `health-critical`, which is 3.76:1 and fails AA for a 14 px label
Fix: use `on-primary` black (5.58:1), or add a darker destructive fill (for example `#C81E1E`, 5.74:1 with white).

**[Rubric — Component coverage]** — DESIGN.md never says which components inherit Material 3 defaults.
DESIGN.md never says which components inherit Material 3 defaults. Unlike the shadcn example's "uses these as-is" list, it gives no rule. It also has no visual spec for the Add Racquet form (text fields, material picker control, date picker, inline validation), Racquet Detail layout and app bar, Restring history timeline, Session feed and filter chips, FAB, navigation bar/rail/drawer, tier labels and `Primary` badge, skeleton and empty state, or the Settings rows, including the Delete Account trigger. A story developer must invent visuals for UJ-2's main screen.
Fix: add an "Inherited from Material 3 via `CourtMidnightTheme`, unchanged" list, and short specs for the brand-specific ones (form, timeline row, session row, badges, FAB).

**[Rubric — Inheritance discipline]** — The health-tier labels use three vocabularies.
The health-tier labels use three vocabularies. FR-10 and EXPERIENCE → Radial Health Gauge (L88) say Optimal / Degraded / Dead. The Accessibility Floor (L135) says `✓ Optimal`, `~ Caution`, `⚠ Restring`. DESIGN.md says "caution state" (L143) and a `⚠ Restring` badge (L197). No surface visually renders the Optimal or Caution label, so the "never color alone" rule has no visual home.
Fix: pick one label set, map it to the engine's `tier` enum, and say where each label renders (gauge micro-label or card badge) for all three tiers.

**[Rubric — Inheritance discipline]** — The Play Console deletion URL contradicts the PRD.
The Play Console deletion URL contradicts the PRD. EXPERIENCE.md points the Data Safety URL at static `/privacy.html`, which links into the app (L63, L151, L198). PRD OQ-3 (prd.md L305) says that URL points to the hosted Flutter Web app, which runs the deletion. FR-20 and UJ-4 leave this ambiguous.
Fix: decide with the PM and either update OQ-3 or change the spine. If `/privacy.html` stays, name the exact in-app link target, for example `/settings`.

**[Accessibility]** — No real focus indicator exists.
No real focus indicator exists. Keyboard focus shares the Level 2 hover treatment: a 12% Volt glow (1.36–1.68:1) plus a `surface` → `surface-elevated` shift (1.13:1). That fails 2.4.7 and 1.4.11, and focus can't be told apart from hover. No focus token exists. (DESIGN.md § Elevation & Depth Level 2; EXPERIENCE.md § Interaction Primitives "Hover (web)", § Accessibility Floor.)
Fix: (in palette):* add a `focus-ring` component token to DESIGN frontmatter (2px solid `{colors.primary}`, 2px offset, radius following the component; 11.33–13.97:1 on every surface). On `primary`-filled controls, the offset puts the ring on the background, or use a `text-primary` ring. Split Level 2 into "Hover (web): glow" and "Focus (keyboard): focus-ring". Add to the Accessibility Floor: "every focusable element shows `focus-ring` on keyboard focus; hover styling never substitutes for it". Text fields keep the M3 focused border in `primary`.

**[Accessibility]** — The single-character shortcuts `L` and `N` fail 2.1.4 Character Key Shortcuts (Level A).
The single-character shortcuts `L` and `N` fail 2.1.4 Character Key Shortcuts (Level A). They are global at expanded width, with no way to turn them off or remap them, and they don't depend on focus. Speech-input users and stray keypresses will open sheets. The spine also doesn't say they are suppressed while a text field has focus, and at 200% browser zoom the layout drops to medium width, so the shortcuts silently vanish. (EXPERIENCE.md § Interaction Primitives "Keyboard (web, expanded width)", § Information Architecture → Settings.)
Fix: scope the shortcuts to "bag route on top, no modal open, no editable field focused". Add a Settings row `Keyboard shortcuts` (on/off, default on) to the IA tree, or use modifier combos (`Alt+Shift+L`, `Alt+Shift+N`; avoid the browser-reserved `Ctrl+L` / `Ctrl+N`). Show the shortcut in the FAB and Add Racquet tooltips so it can be found. `Esc` is not a character key and can stay.

**[Accessibility]** — Important failure messages exist only in a ~4 s auto-dismissing snackbar. (§ EXPERIENCE.md § Component Patterns → Snackbar; § State Patterns → Late write rejection, Re-authentication cancelled / other account, Deletion failed.)
Important failure messages exist only in a ~4 s auto-dismissing snackbar. The late write rejection arrives after the fact (Flow 1 ends with Marco pocketing his phone), and the card then silently reverts, so the user never learns the session was lost. Re-authentication failures and `Couldn't delete your account…` also disappear before slower readers, 200%-text users or magnifier users can read them (2.2.1 Timing Adjustable; 3.3.1 Error Identification). Flutter keeps action snackbars open only while TalkBack is on (`accessibleNavigation`), which doesn't cover sighted users.
Fix: split the Snackbar rule. Confirmations (`1h logged…`, `Fresh stringbed mounted!…`) stay at ~4 s, because the same information is visible on the card. Rejection and failure snackbars persist until dismissed, with a `Dismiss` action (or `Retry` for deletion). Rejection copy names what was lost (`Couldn't save your 1.5h session for Wilson Blade 98 — it was deleted on another device.`). Also show deletion failures as an inline message under `[Delete Account & All Data]`, matching the sign-in failure pattern.

**[Accessibility]** — Text-field and outline boundaries are invisible.
Text-field and outline boundaries are invisible. The spines define no input border. The shipped theme maps `colorScheme.outline` to `surface-border`, so M3 outlined text fields, outlined chips and unselected chip borders come out at 1.11–1.37:1. The Add Racquet form fields (Flow 2 onboarding) and unselected duration/reason chips then fail 1.4.11 component identification. (DESIGN.md § Colors (`surface-border` "1px card outlines, dividers"), frontmatter `components.duration-chip.border`; § Shapes "text fields".)
Fix: (in palette):* use `text-secondary` (5.62–7.71:1) for text-field borders and unselected chip outlines. Keep `surface-border` for decorative dividers, the gauge track and card outlines only. *Fix (new token):* add `outline: '#6B767B'` (3.19–3.93:1) to DESIGN frontmatter for interactive boundaries and map `colorScheme.outline` to it.

**[Accessibility]** — Racquet card actions have no specified accessible names or structure. (§ EXPERIENCE.md § Component Patterns → Racquet Card, § Accessibility Floor; DESIGN.md § Components → Racquet Card "Right".)
Racquet card actions have no specified accessible names or structure. The quick-log action is never given a visible label or semantics name (if it's icon-only, that fails 1.1.1/4.1.2). `[Restrung Today]` repeats on every card, so a screen-reader button list hears "Restrung Today" N times with no racquet context (2.4.6). A tappable card containing buttons produces nested interactive semantics on Flutter web (a button inside a button).
Fix: in DESIGN Racquet Card, name the quick-log action (`Log` with an icon, or icon plus tooltip `Log session`). In the EXPERIENCE Accessibility Floor, add: "each card is one semantics container: an `Open details` node that merges name, string setup and the gauge label, followed by sibling buttons `Log session for {racquet}` and `Restrung today: {racquet}`; card buttons are never children of the card's tap target".

**[Accessibility]** — Flutter web semantics are off by default. (§ EXPERIENCE.md § Responsive & Platform → Web bullet.)
Flutter web semantics are off by default. Without opting in, screen-reader users must first find Flutter's hidden "Enable accessibility" placeholder before anything is exposed. The spines also don't mention per-route page titles (2.4.2, Level A) or the document language (3.1.1, Level A).
Fix: add to the Web bullet: "On web, the app calls `SemanticsBinding.instance.ensureSemantics()` at startup; every route sets a `Title` (`My Virtual Bag — String Theory`, `Wilson Blade 98 — String Theory`, …); `index.html` declares `lang="en"`." Verify with NVDA+Chrome and VoiceOver+Safari as part of the web release checklist.

**[Accessibility]** — The card and gauge layout can't meet the stated 200% text-scale rule. (§ DESIGN.md § Components → Racquet Card, Radial Health Gauge; EXPERIENCE.md § Accessibility Floor "up to 200% without clipping".)
The card and gauge layout can't meet the stated 200% text-scale rule. The card is a three-zone horizontal row (gauge, text, two actions), and the gauge is a fixed ring with `metric-hero` 28px (56px at 200%) above a `HEALTH` micro-label. At compact width this clips or overflows on the core bag screen (Flows 1 and 3, 1.4.4), and no reflow behaviour is defined.
Fix: add a large-text rule to DESIGN Racquet Card. At text scale ≥ 1.3, or when the card is narrower than its content, the actions move to a full-width row under the content, the racquet name wraps (never ellipsized) and the gauge diameter scales with the text scaler. Add an Accessibility Floor line naming the surfaces checked at 200%: bag card, gauge, Quick-Log sheet, Restrung Today sheet, destructive dialog, bottom navigation labels, snackbar.

### Medium (24)

**[Rubric — Flow coverage]** — Flows 1, 3 and 5 have no `Failure:` line, although the architecture defines failures for them. (§ EXPERIENCE.md L155–165, L181–192, L206–214)
Flows 1, 3 and 5 have no `Failure:` line, although the architecture defines failures for them. AD-6/AD-14: a session against a racquet deleted on another device is rejected, and a second offline restring of the same job is rejected
Fix: add a one-line failure for each that points to the `Late write rejection` state, with the restring-rejection copy.

**[Rubric — Flow coverage]** — FR-3 Sign-out has no flow, component row or state.
FR-3 Sign-out has no flow, component row or state. It appears only in the IA (L46), as an entry to Welcome (L54), and in an open question (L219). The destination, any confirmation, and whether a snackbar shows are all uncommitted.
Fix: add a `Sign Out` row to Component Patterns and a `Signed out` state on Welcome, even if the pending-writes warning stays open.

**[Rubric — Token completeness]** — The Colors rationale contradicts itself.
The Colors rationale contradicts itself. L147 says red-for-dead-strings and red-for-destructive "don't meet on one surface", yet it puts Delete Racquet on Racquet Detail, which also shows a `health-critical` gauge for dead racquets.
Fix: restate the rule, for example "destructive red appears only inside the confirmation dialog", and specify how the Delete Racquet app-bar item and the Settings Delete Account trigger are styled.

**[Rubric — Token completeness]** — Component boundaries fail 1.4.11.
Component boundaries fail 1.4.11. `surface-border` is 1.26:1 on `surface`. An unselected `duration-chip` (`surface` on a `surface-elevated` sheet, 1.13:1) has no 3:1 boundary.
Fix: state a non-text contrast rule for interactive outlines, or give unselected chips a `text-tertiary`-or-lighter border.

**[Rubric — Token completeness]** — The prose specifies values that have no tokens:
The prose specifies values that have no tokens: the secondary outlined button (`primary-muted`, L212), the text `Cancel` button, snackbar, dialog, badges (`⚠ Restring`, `Primary`), the navigation active indicator, the inline error text color for the sign-in failure messages, the Level 3 scrim color, the Level 2 glow (12% / 16 px), and the gauge animation duration/curve.
Fix: add `components` entries (`button-secondary`, `button-text`, `snackbar`, `dialog`, `badge-critical`, `badge-primary`, `nav-indicator`) and a small `motion` note.

**[Rubric — Token completeness]** — No token-to-Flutter mapping.
No token-to-Flutter mapping. The shipped theme names `primary` as `primaryVolt`, maps Barlow and Inter onto Material `TextTheme` slots rather than the 7 named roles, and has no `data`/JetBrains Mono role. A developer mirroring the spine can't tell which `TextTheme` slot or `ThemeExtension` field each token becomes.
Fix: add a three-column table (token → `CourtMidnightTheme` constant → `TextTheme` slot / `ThemeExtension` field), and note that `data` needs a new extension field.

**[Rubric — Component coverage]** — The FAB has no behavioral row. (§ EXPERIENCE.md L32, L107, L144–148)
The FAB has no behavioral row. Its visibility (hidden on an empty bag is an [ASSUMPTION]), scroll behavior, and placement when the rail or drawer replaces the bottom bar (medium/expanded) are all unstated
Fix: add a `Log Session FAB` row to Component Patterns.

**[Rubric — Component coverage]** — No ordering rule for the racquet cards in the bag or the racquets in the Quick-Log selector (primary first? `createdAt`? name?). (§ EXPERIENCE.md L28, DESIGN.md L206)
No ordering rule for the racquet cards in the bag or the racquets in the Quick-Log selector (primary first? `createdAt`? name?). That's a visible, testable decision
Fix: commit to one order, for example `resolvePrimary` first and then `createdAt` ascending.

**[Rubric — State coverage]** — Sessions has no states: (§ L41–43, L61, L94)
Sessions has no states: initial load, empty (`no sessions yet`), filtered-empty (racquet chip with zero sessions), and a load-more/paging pattern. Architecture → Deferred leaves the page size to the `sessions` story, but the UX pattern belongs here
Fix: add four Sessions rows to State Patterns.

**[Rubric — State coverage]** — Racquet Detail has no loading or not-found state, and nothing for a racquet deleted on another device while the detail is open (`watchRacquet(id)` emits nothing). (§ L119)
Racquet Detail has no loading or not-found state, and nothing for a racquet deleted on another device while the detail is open (`watchRacquet(id)` emits nothing). This also covers a web deep link to a deleted id. The only related row covers the user's own delete
Fix: add `Racquet removed elsewhere → pop to bag + snackbar` and `Loading`.

**[Rubric — State coverage]** — The Restrung Today prompt `Restrung with the same setup ({brand} @ {tension} lbs)?` (L91) breaks when brand or tension is absent, and both are optional per FR-5 and AD-3.
The Restrung Today prompt `Restrung with the same setup ({brand} @ {tension} lbs)?` (L91) breaks when brand or tension is absent, and both are optional per FR-5 and AD-3. The timeline entry format (L93) has the same problem without a brand.
Fix: give fallback copy for each missing-field combination.

**[Rubric — State coverage]** — The web focus state is underspecified.
The web focus state is underspecified. Focus reuses the Level 2 treatment, a 12%-opacity Volt glow (DESIGN.md L177), which is unlikely to meet the WCAG 2.2 focus-visible bar. No focus ring token exists.
Fix: specify a 2 px `primary` focus outline (12.79:1 on `surface`) for keyboard focus, separate from hover.

**[Rubric — Visual reference coverage]** — The mockup is linked only at the end of each file, not inline at the sections it illustrates (DESIGN → Racquet Card and Radial Health Gauge; EXPERIENCE → IA / Virtual Bag), and neither link says what it shows.
The mockup is linked only at the end of each file, not inline at the sections it illustrates (DESIGN → Racquet Card and Radial Health Gauge; EXPERIENCE → IA / Virtual Bag), and neither link says what it shows.
Fix: move the link to DESIGN → Components → Racquet Card as "bag screen, compact width: card anatomy and gauge styling only".

**[Rubric — Visual reference coverage]** — The stated caveat is wrong and the real divergences aren't listed.
The stated caveat is wrong and the real divergences aren't listed. DESIGN.md L236 says the image "may still show the removed Simulate Workout action", but it doesn't show that action. Here is what the image actually shows that a consumer could copy:
Fix: 

**[Rubric — Inheritance discipline]** — Navigation and breakpoints drift from the decision log and Material 3.
Navigation and breakpoints drift from the decision log and Material 3. `.memlog.md` L7 decided "NavigationRail on tablet/web", but the spine uses a persistent drawer at expanded width (L148), and no memlog entry records the change. The 600/1024 dp breakpoints also differ from Material 3 window classes (600/840) without rationale, so Flutter adaptive defaults will disagree.
Fix: log the drawer decision, and either adopt the M3 840 dp breakpoint or state why 1024.

**[Accessibility]** — Health tiers are only partly independent of color. (§ DESIGN.md § Components → Racquet Card, Radial Health Gauge; EXPERIENCE.md § Accessibility Floor, § Component Patterns → Radial Health Gauge.)
Health tiers are only partly independent of color. EXPERIENCE requires `✓ Optimal`, `~ Caution`, `⚠ Restring`, but the DESIGN card spec shows only the critical `⚠ Restring` badge, so the 40–69 tier in Flow 1 (76% green → 67% amber) is signalled by color and number alone. Tier names also drift: FR-10 says Optimal/Degraded/Dead, the labels say Caution/Restring, and DESIGN's Colors table says "caution state". The gauge semantics label omits the tier, and TalkBack reads `~` as "tilde".
Fix: in DESIGN, show a tier label on every card and on Racquet Detail, in its tier color (passes on `surface` and `health-critical-bg`, except `health-critical` text on `surface`; see the next finding). Reconcile the label set with FR-10 in one place. Extend the gauge label: `…string health 67 percent, Caution, …`. Specify that semantics labels drop the `✓ ~ ⚠` glyphs.

**[Accessibility]** — Critical and error text color is unspecified. (§ DESIGN.md § Colors.)
Critical and error text color is unspecified. `health-critical` as text fails on `surface` (4.46:1) and `surface-elevated` (3.95:1), and the M3 default `error` (#CF6679, not overridden in the shipped theme) fails on `surface-elevated` (4.13:1). Inline form errors in the expanded-width Add Racquet dialog and any critical tier label inside a `surface` container would fail 1.4.3.
Fix: (in palette):* allow `health-critical` as text only on `background` and `health-critical-bg`. *Fix (new token):* add `health-critical-text: '#F87171'` (5.38–6.27:1) for error and critical text on any surface, and map `colorScheme.error` to it.

**[Accessibility]** — Selected state for chips and the racquet selector relies on fill or outline only. (§ DESIGN.md § Components → Quick-Log Sheet, Restrung Today Sheet; EXPERIENCE.md § Accessibility Floor.)
Selected state for chips and the racquet selector relies on fill or outline only. Their semantics are unspecified, and the reason chips and Sessions filter chips have no selected-state visual at all. The `[ASSUMPTION]` primary outline has no stated thickness. The horizontal racquet selector hides off-screen racquets, which is worse at 200%. `1.5h` is read literally.
Fix: in DESIGN, use the M3 `ChoiceChip` with its check icon for every single-select row (duration, reason, Sessions filter). The racquet selector gets a 2px `primary` outline plus a check icon, and wraps to multiple lines instead of scrolling horizontally. In the EXPERIENCE Accessibility Floor, add: chips expose `selected` and `inMutuallyExclusiveGroup`; duration chips have semantics labels `30 minutes`, `1 hour`, `1 and a half hours`, `2 hours`; the 48dp target applies to each chip; chip rows `Wrap`.

**[Accessibility]** — Live stream updates have no screen-reader rule. (§ EXPERIENCE.md § Component Patterns → Radial Health Gauge, Bag sync summary; § Accessibility Floor.)
Live stream updates have no screen-reader rule. Gauges animate on every snapshot (other device, app resume). If the semantics label is bound to the animated value, TalkBack re-reads the focused card through the tween, and cross-device changes may or may not announce.
Fix: add to the Accessibility Floor: "Gauge semantics use the settled target value, never the animated value. Cards, gauges and the bag sync summary are not live regions. Only user-initiated outcomes are announced (via the snackbar). The bag sync summary is part of the bag header's semantics so it can be read on demand."

**[Accessibility]** — Focus return is unspecified. (§ EXPERIENCE.md § Accessibility Floor; § State Patterns → First sign-in, Racquet deleted, Deletion succeeded.)
Focus return is unspecified. The spines don't say where keyboard or accessibility focus goes after a sheet or dialog closes, after Racquet Detail closes on delete (the card is gone), after account deletion (new route), or when the Add Racquet form auto-opens and is dismissed on first sign-in.
Fix: add a focus-destination list. Sheets and dialogs return focus to their trigger (FAB, card button, app-bar action). After a racquet is deleted, focus goes to the bag header. After account deletion, focus goes to the welcome headline, with the deletion message announced. A dismissed auto-opened Add Racquet form moves focus to `[Add Your First Racquet]`. The auto-opened form announces its title on open.

**[Accessibility]** — The destructive dialog's "focus to Cancel first" can make screen readers skip the consequence text. (§ EXPERIENCE.md § Accessibility Floor, § Component Patterns → Destructive confirmation dialog.)
The destructive dialog's "focus to Cancel first" can make screen readers skip the consequence text. If accessibility focus lands on `Cancel`, TalkBack users may never hear `This permanently deletes…`.
Fix: separate the two kinds of focus. Keyboard focus defaults to `Cancel` (safe default, and `Esc` = Cancel). Screen-reader reading order starts at the dialog title, which names the route, then body, Cancel, confirm. Also say in the Delete Account body that Google may ask to confirm the account next, so the re-auth sheet isn't a surprise.

**[Accessibility]** — Auth and deletion state messages have no announcement rule. (§ EXPERIENCE.md § State Patterns → Sign-in failed, Web popup blocked, Deletion succeeded; § Component Patterns → Google Sign-In button.)
Auth and deletion state messages have no announcement rule. The inline `Couldn't sign in…`, the popup-blocked message and `Your account and all data were deleted.` (shown "once") aren't specified as announced. On web, disabling the Google button while it has focus can drop focus to the document. If the web build uses Google's GIS-rendered button, it lives in an iframe platform view whose keyboard and screen-reader behaviour Flutter doesn't control.
Fix: inline auth messages are polite live regions and stay visible until the next sign-in attempt. "Shows once" means it stays on screen for that visit and is not a toast. The progress indicator has the semantics label `Signing in`. Focus stays on the button while it's busy. Add a web verification item for the button: Tab reaches it, Enter/Space activates it, and it's announced as "Sign in with Google, button".

**[Accessibility]** — Sheets have no visible close control. (§ DESIGN.md § Components → Quick-Log Sheet, Restrung Today Sheet; EXPERIENCE.md § Interaction Primitives, § Accessibility Floor "Sheets scroll".)
Sheets have no visible close control. Dismissal is swipe, scrim tap or `Esc`. The swipe is a dragging movement whose scrim alternative isn't obvious (2.5.7), TalkBack users get no visible exit, and at 200% the full-width `Save Session` / `Save & Reset` can scroll out of view, especially once `[Change Strings]` expands with the keyboard open.
Fix: add a 48dp `Close` icon button (semantics `Close`) in each sheet header. In EXPERIENCE, add: "sheets scroll with the keyboard inset; the primary action stays pinned at the bottom of the sheet".

**[Accessibility]** — Form error behaviour is too thin for 3.3.1–3.3.3. (§ EXPERIENCE.md § Component Patterns → Add Racquet form.)
Form error behaviour is too thin for 3.3.1–3.3.3. "Out-of-range values are blocked inline" doesn't say the error is text, names the allowed range, or is announced. How "required" is shown is unspecified. The silent auto-refill of Max court hours when the material changes isn't explained.
Fix: add that errors appear as text under the field, name the range (`Tension must be between {min} and {max} lbs`) and are announced. On a failed save, focus moves to the first invalid field. Required fields say `(required)` in the label text. Max court hours shows the helper text `Suggested for Monofilament`.

### Low (26)

**[Rubric — Flow coverage]** — Flow titles paraphrase the UJ names. (§ L155, L181, L194)
Flow titles paraphrase the UJ names. For example, "Marco logs playtime after a match" vs PRD "Marco Logs Playtime in 5 Seconds After a Match", and "A Play Store user deletes their account" vs "Play Store User Exercises Mandatory Account Deletion"
Fix: use the PRD titles verbatim.

**[Rubric — Flow coverage]** — The example figures don't satisfy FR-9 (most are inherited from the PRD).
The example figures don't satisfy FR-9 (most are inherited from the PRD). Monofilament after 3 weeks gives 92%, not 88% (L176). 19 h and 70 days on mono gives about 6%, not 34% (L183). 84% with 12 h played is impossible at a 20 h max (L137). Widget tests copied from these figures will fail.
Fix: mark the numbers as illustrative, or recompute them with the engine.

**[Rubric — Token completeness]** — `rounded.sm` (6px) and `rounded.xl` (24px) are defined but never used (§ L60, L63)
`rounded.sm` (6px) and `rounded.xl` (24px) are defined but never used
Fix: assign them or remove them.

**[Rubric — Token completeness]** — The prose mixes `{colors.x}` references with bare names (§ `health-optimal`, `card-title`, `body-secondary`, `primary-muted`; L190–224)
The prose mixes `{colors.x}` references with bare names
Fix: use `{path}` syntax consistently so the references can be machine-extracted.

**[Rubric — Component coverage]** — The gauge diameter and its behavior at 200% text scale are unspecified. (§ DESIGN.md L188–191, EXPERIENCE.md L136)
The gauge diameter and its behavior at 200% text scale are unspecified. `metric-hero` at 28 px inside a fixed ring will clip
Fix: state the diameter per width class and say whether the gauge text scales or is clamped.

**[Rubric — State coverage]** — For the Add Racquet form, "out-of-range values are blocked inline" (L90) doesn't name the AD-3 bounds (name 1–100, tension 20–80, maxHours >0–200), the error copy, what happens when Max court hours is cleared (AD-15 says it is never null), or whether dismissing with unsaved input asks first.
For the Add Racquet form, "out-of-range values are blocked inline" (L90) doesn't name the AD-3 bounds (name 1–100, tension 20–80, maxHours >0–200), the error copy, what happens when Max court hours is cleared (AD-15 says it is never null), or whether dismissing with unsaved input asks first.
Fix: reference `schema_bounds` and add those three rules.

**[Rubric — State coverage]** — Under AD-4, a racquet that fails to decode silently disappears from the bag.
Under AD-4, a racquet that fails to decode silently disappears from the bag. No user-facing treatment is stated.
Fix: state explicitly that it is "silent by design", or add a treatment.

**[Rubric — State coverage]** — The `L`/`N` shortcuts (L126) have no guard against firing while a text field has focus.
The `L`/`N` shortcuts (L126) have no guard against firing while a text field has focus.
Fix: add "ignored while a text input has focus".

**[Rubric — Bloat & overspecification]** — The IA is given twice: (§ L52–63)
The IA is given twice: a text tree (L22–50) and a table
Fix: keep the table and fold the tree's only extras (app-bar actions, Settings items) into the Purpose column, or keep the tree and drop the duplicate rows.

**[Rubric — Bloat & overspecification]** — Leftover changelog text belongs in `.memlog.md`, not the contract: (§ DESIGN.md L236)
Leftover changelog text belongs in `.memlog.md`, not the contract: "The old `S` (Simulate) shortcut is removed." (EXPERIENCE.md L126), "`surface-border` follows the shipped theme value" (DESIGN.md L149), and the Simulate Workout caveat
Fix: delete them; the memlog already records them.

**[Rubric — Bloat & overspecification]** — Some lines restate the sources: (§ L150, NFR-6)
Some lines restate the sources: the Foundation paragraph on Firestore and live streams (L18), and the Android manifest permissions
Fix: keep only the behavioral consequence ("no refresh control", "no permission prompt").

**[Rubric — Inheritance discipline]** — Field and action labels differ from the PRD glossary:
Field and action labels differ from the PRD glossary: "Racquet name" vs "Frame Name / Model", "Max court hours" vs "Manufacturer Max Hours", "Primary" vs "Primary in Bag", and "Delete Account & All Data" vs FR-4's "Delete Account & Data" (the PRD contradicts itself here).
Fix: add one line saying these are deliberate UI labels for the glossary terms.

**[Rubric — Inheritance discipline]** — Component names differ between the files:
Component names differ between the files: "Quick-Log Sheet" vs "Quick-Log sheet", "Confirmation Dialog (destructive)" vs "Destructive confirmation dialog", "Welcome / Sign-In Screen" vs "Google Sign-In button".
Fix: use identical names in both files.

**[Rubric — Inheritance discipline]** — FR-17 says "chronological", but EXPERIENCE says "Newest first" (§ L93)
FR-17 says "chronological", but EXPERIENCE says "Newest first"
Fix: confirm reverse-chronological with the PM, or note the interpretation.

**[Rubric — Inheritance discipline]** — The reason chip → `endReason` mapping is implied, not stated (§ `Routine restring`→`manual_restring`, `Strings went dead`→`dead`, `Strings broke`→`broken`; L91, DESIGN L213)
The reason chip → `endReason` mapping is implied, not stated
Fix: state the mapping and the timeline label for each value.

**[Rubric — Inheritance discipline]** — "the next racquet becomes the default automatically" (L119) is vaguer than AD-8.
"the next racquet becomes the default automatically" (L119) is vaguer than AD-8.
Fix: say "chosen by `resolvePrimary`".

**[Rubric — Inheritance discipline]** — EXPERIENCE gives touch targets as a literal "48 × 48 dp" (L134) instead of `{spacing.touch-min}`.
EXPERIENCE gives touch targets as a literal "48 × 48 dp" (L134) instead of `{spacing.touch-min}`.
Fix: reference the token.

**[Rubric — Shape fit]** — Inspiration & Anti-patterns is omitted, although `.memlog.md` records rejects (L14 type-to-confirm, L18 the advanced-options accordion and the Working Offline banner).
Inspiration & Anti-patterns is omitted, although `.memlog.md` records rejects (L14 type-to-confirm, L18 the advanced-options accordion and the Working Offline banner). The Banned list (L128) covers only some of them.
Fix: add a three-bullet "Rejected" list so future editors don't bring them back.

**[Rubric — Shape fit]** — The visual-reference lines sit after the last canonical section in both files, and DESIGN frontmatter carries non-spec keys (`status`, `created`, `updated`, `mockup`).
The visual-reference lines sit after the last canonical section in both files, and DESIGN frontmatter carries non-spec keys (`status`, `created`, `updated`, `mockup`).
Fix: move the references inline (see §5). The extra keys are harmless.

**[Accessibility]** — Card outlines (1.26–1.37:1), the card/background step (1.09:1) and the gauge track (1.26:1) are below 3:1. (§ DESIGN.md § Elevation & Depth Level 1, § Components → Radial Health Gauge.)
Card outlines (1.26–1.37:1), the card/background step (1.09:1) and the gauge track (1.26:1) are below 3:1. They aren't strictly required, because card content and the % value identify the card and its state, but low-vision users lose the card's tap area in the 2–3 column grids.
Fix: optional. If the `outline` token from the high finding is adopted, consider it for card borders at medium and expanded widths. Otherwise leave as is.

**[Accessibility]** — Motion: (§ EXPERIENCE.md § Accessibility Floor, § State Patterns → First snapshot loading; DESIGN.md § Do's and Don'ts "animate gauge… at 60 fps".)
Motion: the reduce-motion `[ASSUMPTION]` is right but covers only the gauge. The skeleton shimmer `[ASSUMPTION]` can run past 5 s on a slow first load (2.2.2). No rule forbids a future pulsing critical badge. 2.3.3 is AAA and so not required.
Fix: adopt the assumption. Extend it to sheet and dialog transitions, the snackbar slide, the gauge color tween and the shimmer (static skeleton under `MediaQuery.disableAnimations`). Stop the shimmer after 5 s in all cases. Give the skeleton the semantics label `Loading your bag`. Add a Don't: "no pulsing, blinking or looping animation on cards or badges". Verify that Flutter web honours `prefers-reduced-motion`; if it doesn't, add a Settings toggle.

**[Accessibility]** — Screen titles and section labels have no heading semantics, so screen-reader heading navigation (1.3.1, 2.4.6) has nothing to land on on the bag, detail and settings screens. (§ EXPERIENCE.md § Accessibility Floor.)
Screen titles and section labels have no heading semantics, so screen-reader heading navigation (1.3.1, 2.4.6) has nothing to land on on the bag, detail and settings screens.
Fix: add "screen titles (`display`), sheet and dialog titles and settings group labels (`section`) are marked as headers".

**[Accessibility]** — Smaller 200% risks: (§ EXPERIENCE.md § Component Patterns → Restring history timeline; § Responsive & Platform.)
Smaller 200% risks: M3 navigation bar labels, multi-line rejection snackbars and the restring timeline row (`Aug 1 – Oct 2 • Luxilon ALU Power • 19.2 court hours • 62 days`) will wrap heavily. The timeline row also reads as one undifferentiated string.
Fix: allow timeline entries to wrap into two lines (dates / string / hours and days). Give each entry a semantics label in full words (`August 1 to October 2, Luxilon ALU Power, 19.2 court hours, 62 days`).

**[Accessibility]** — The "Sign-out with pending writes" open question has a cognitive-safety answer: (§ EXPERIENCE.md § Open Questions.)
The "Sign-out with pending writes" open question has a cognitive-safety answer: a silent sign-out with queued writes risks unseen data loss on shared devices.
Fix: recommend a confirmation listing the count (`2 changes are still waiting to sync. Sign out anyway?`, with `Stay signed in` / `Sign out`).

**[Accessibility]** — The PRD has no accessibility NFR, so the WCAG 2.2 AA target isn't traceable to acceptance criteria. (§ prd.md, NFR section; EXPERIENCE.md § Accessibility Floor.)
The PRD has no accessibility NFR, so the WCAG 2.2 AA target isn't traceable to acceptance criteria. The spines can't fix that on their own.
Fix: add one line to the Accessibility Floor ("Target: WCAG 2.2 AA on Android and web; TalkBack and NVDA/VoiceOver verified on Flows 1–4"), and raise a PRD NFR through the PM.

**[Accessibility]** — Flutter web renders text to canvas, so user text-spacing overrides (1.4.12) and user stylesheets don't apply. (§ EXPERIENCE.md § Responsive & Platform → Web.)
Flutter web renders text to canvas, so user text-spacing overrides (1.4.12) and user stylesheets don't apply. This is a platform limitation and not fixable in the spine.
Fix: record it as a known limitation in the Web bullet, and rely on the 200% text-scale and browser-zoom (1.4.4/1.4.10) behaviour instead.

## Reviewer files

- `review-rubric.md`
- `review-accessibility.md`
