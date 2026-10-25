---
name: String Theory — Experience Spine
status: final
created: 2026-10-02
updated: 2026-10-24
tokens_reference: DESIGN.md
sources:
  - _bmad-output/planning-artifacts/prds/prd-string_theory-2026-10-02/prd.md
  - _bmad-output/planning-artifacts/architecture/architecture-string_theory-2026-10-23/ARCHITECTURE-SPINE.md
---

# String Theory — Experience Spine

## Foundation

String Theory v1 is one Flutter app for **Android** (phones and tablets, Google Play) and **Web** (Firebase Hosting). It uses Material 3 through `CourtMidnightTheme`. This spine specifies only the behavior on top of M3 defaults, and DESIGN.md is the visual identity reference.

Every surface except Welcome and `/privacy.html` requires a user signed in with Google. Screens update live from the user's data, so there is no refresh control. Health figures are recomputed whenever the data changes and when the app returns to the foreground.

**Accessibility target:** WCAG 2.2 AA on Android and web. Flows 1–4 are verified with TalkBack, NVDA + Chrome, and VoiceOver + Safari.

## Information Architecture

The navigation destinations are **Bag**, **Sessions**, and **Settings**. Racquet Detail is pushed on top of the bag. A sheet or dialog never opens on top of another one; the only exception is the discard confirmation over a form.

| Surface | Reached from | Contents | Flow |
|---|---|---|---|
| Welcome / Sign-In | Cold start without a session, sign-out, account deletion | Wordmark, one line on string health and arm protection, `Sign in with Google` | 2, 4 |
| Virtual Bag | Sign-in, cold start with a restored session, navigation | Header, Bag Sync Summary (while writes are pending), Racquet Cards (see Bag Order), Log Session FAB, `[+ Add Racquet]`, empty state | 1, 2, 3 |
| Add Racquet Form | `[+ Add Racquet]`, the empty-state CTA, the `N` key; opens by itself after sign-in when the bag is empty | Racquet name, String material, String brand & model, Stringing date, Tension, Max court hours | 2 |
| Quick-Log Sheet | Log Session FAB, a card's `Log` action, the `L` key | Duration chips, racquet selector, `Save Session` | 1 |
| Restrung Today Sheet | `[Restrung Today]` on a card or on Racquet Detail | Same-setup prompt, `[Keep Same & Reset]`, `[Change Strings]` | 3 |
| Racquet Detail | Tapping a card | Gauge, Tier Label, usage and companion lines, current setup and stringing date, `[Restrung Today]`, Restring History Timeline. App bar: Edit, Set as Primary, Delete Racquet | 3, 5 |
| Edit Racquet Form | Racquet Detail app bar → Edit | Racquet name, Notes | 5 |
| Sessions | Navigation | Session Feed, racquet filter chips | — |
| Settings | Navigation | Account (Google name and email), `[Sign Out]`, Keyboard shortcuts (web), Privacy Policy, `[Delete Account & All Data]`, app version | 4 |
| `/privacy.html` (static, public) | Settings → Privacy Policy, the Play listing's privacy policy URL | Privacy policy and the steps to delete an account | 4 |

**UI labels for PRD terms:**
* **Racquet name** = Frame Name / Model
* **Max court hours** = Manufacturer Max Hours
* **Primary** = Primary in Bag
* **Tier labels:** `Optimal`, `Caution` and `Restring` = the FR-10 tiers Optimal, Degraded and Dead, which stay as the internal names.

## Voice and Tone

These rules cover microcopy. The brand voice lives in DESIGN.md → Brand & Style.

* **Preventive, not alarming.** Present string wear as equipment care and arm health.
  * *Do:* `Strings are losing elasticity (~1.4 lbs tension drop). Restringing recommended soon to protect your elbow.`
  * *Don't:* `DANGER: Stringbed destroyed!`
* **Tier labels:** `Optimal` (≥ 70%), `Caution` (40–69%), `Restring` (< 40%).
* **Brevity first.** People read this walking off court.
  * *Do:* `1h logged • Wilson Blade 98 at 67%`
  * *Don't:* `Your session of sixty minutes has been successfully synchronized to the cloud.`
* **Celebrate maintenance.** `Fresh stringbed mounted! Restrung to 100% health.`
* **Plain about sync.** Say what is waiting, not what failed: `Waiting to sync`, `2 changes waiting to sync`. Never `Offline` or `Network error`.
* **Say what was lost.** `Couldn't save your 1.5h session for Wilson Blade 98 — it was deleted on another device.`
* **Direct about deletion.** List exactly what goes. A bare `Are you sure?` is never enough.

## Component Patterns

These rules cover behavior. Visual specs live in DESIGN.md → Components, which lists the same components in the same order. Bag Order is a behavior-only row.

| Component | Behavioral rules |
|---|---|
| Radial Health Gauge | Animates from the previous value to the new one whenever data or an app resume changes the score. The tier comes from the engine (FR-10). |
| Tier Label | Always visible on cards and on Racquet Detail: `✓ Optimal`, `~ Caution`, `⚠ Restring`. |
| Racquet Card | Tapping the card body opens Racquet Detail.<br>`[Restrung Today]` and `Log` are always visible. They are sibling buttons, never children of the card's tap target.<br>`Log` opens the Quick-Log Sheet with this racquet selected.<br>Shows `Waiting to sync` while this racquet has pending writes.<br>The management actions (Edit, Set as Primary, Delete Racquet) aren't on the card. |
| Bag Order | The primary racquet (per `resolvePrimary`) comes first, then the rest by `createdAt`, oldest first. The Quick-Log racquet selector uses the same order. |
| Primary Badge | Shown on Racquet Detail when the racquet is primary, in place of the Set as Primary action. |
| Bag Sync Summary | Shows `N changes waiting to sync` (`1 change waiting to sync` when N is 1) while any write is pending, and disappears when none are. Not tappable. |
| Log Session FAB | Visible on the bag whenever at least one racquet exists, and hidden on an empty bag.<br>Stays fixed while the list scrolls.<br>On medium and expanded widths it's the extended FAB at the bottom right of the content area. The rail and drawer never hold it. |
| Quick-Log Sheet | `1h` is pre-selected.<br>The racquet is pre-selected from the card that opened the sheet, or otherwise from `resolvePrimary`.<br>`Save Session` closes the sheet as soon as the device accepts the write, then shows the confirmation snackbar.<br>There are no other fields. |
| Restrung Today Sheet | **Prompt:** `Restrung with the same setup ({brand} @ {tension} lbs)?`. When fields are missing, the parenthetical becomes `({brand})`, `({material} @ {tension} lbs)`, or `({material})`.<br>**Keep Same:** `[Keep Same & Reset]` resets immediately with the same specs and today's date, recorded as `manual_restring`.<br>**Change Strings:** `[Change Strings]` expands the string fields (String material, String brand & model, Stringing date, Tension, Max court hours), pre-filled, plus the reason chips. `Routine restring` maps to `manual_restring` (the default), `Strings went dead` to `dead`, and `Strings broke` to `broken`. `Save & Reset` applies the change.<br>**Success:** the sheet closes and shows `Fresh stringbed mounted! Restrung to 100% health.` |
| Sheet Close Button | Present on every sheet, labeled `Close`. It behaves like swipe-down or `Esc`. |
| Add Racquet Form | **Fields:** Racquet name (required); String material (required: Monofilament, Multifilament, Synthetic Gut, Natural Gut); String brand & model (optional, one field); Stringing date (defaults to today); Tension in lbs (optional); Max court hours (pre-filled from the material).<br>**Defaults:** changing the material re-fills Max court hours only if the user hasn't edited that field. Max court hours can't be left empty.<br>**Validation:** bounds come from `schema_bounds` (name 1–100 characters, tension 20–80 lbs, Max court hours above 0 and up to 200). Out-of-range values show an inline message that names the range (`Tension must be between 20 and 80 lbs`). On a failed save, focus moves to the first invalid field.<br>**Save and dismiss:** `Save Racquet` closes the form. Dismissing a form with input asks `Discard this racquet?`. |
| Edit Racquet Form | Racquet name and Notes only, with the same validation. `Save` closes it. Dismissing it with unsaved edits asks `Discard your changes?`. |
| Racquet Detail | **Edit** opens the Edit Racquet Form.<br>**Set as Primary** appears only when the racquet isn't primary.<br>**Delete Racquet** opens the Destructive Confirmation Dialog. |
| Restring History Timeline | Newest first, deduplicated by job id. Each entry reads `Aug 1 – Oct 2 • Luxilon ALU Power • 19.2 court hours • 62 days`. The material replaces the brand & model when none is set. Dead and broken jobs add `Went dead` or `Broke`. When empty: `No past string jobs yet.` |
| Session Feed | Newest first, showing date, duration, and racquet name.<br>Older sessions load as the user scrolls, with a loading row at the end.<br>The filter chips narrow the feed to one racquet.<br>Sessions can't be edited or deleted in v1.<br>A session whose racquet was deleted shows `Deleted racquet`. |
| Skeleton Card | Three appear together on a first uncached load, under a single `Loading your bag` label. |
| Destructive Confirmation Dialog | A title, a body that lists what is removed, `Cancel`, and a confirm button that carries the action name (`Delete Racquet`, `Delete Account`), never `OK`. `Esc` and the scrim both mean Cancel. |
| Settings Rows | **Sign Out:** with no pending writes, it signs the user out at once and returns to Welcome. With pending writes it asks first: `2 changes are still waiting to sync. Sign out anyway?`, with `Stay signed in` and `Sign out`.<br>**Keyboard shortcuts (web only):** a switch, on by default, that enables `L` and `N`. Until the storage decision in Open Questions is made, it resets to on with each visit.<br>**Delete Account & All Data:** opens the Destructive Confirmation Dialog (Flow 4). |
| Welcome / Sign-In Screen | The Google Sign-In button starts the Android account sheet, or the pop-up on web. While sign-in runs, the button shows a `Signing in` progress state and keeps focus. |
| Snackbar | One at a time.<br>Confirmations (logged, restrung) dismiss after about 4 s, because the card shows the same result.<br>Failure and rejection snackbars stay until dismissed and offer `Dismiss`. Deletion failures offer `Retry` instead. |

## State Patterns

| State | Surface | Treatment |
|---|---|---|
| No connectivity | Everywhere | No banner. Logging, adding, editing, and restringing all work and show as pending. Sign-in and account deletion need the network and say so when they fail. |
| Cold start, session restored | Bag | Renders straight from the local cache (target < 1.5 s), with no welcome screen. |
| First load, nothing cached | Bag | Three Skeleton Cards under a single `Loading your bag` label. |
| First sign-in, empty bag | Bag | The Add Racquet Form opens by itself and announces its title. Dismissing it leaves the empty state. |
| Empty bag | Bag | Empty-bag illustration and `[Add Your First Racquet]`. The FAB is hidden. |
| Write pending | Racquet Card and bag header | `Waiting to sync` on the card, plus the Bag Sync Summary. The action counts as done, and nothing blocks. |
| Late write rejection | Bag | A persistent snackbar names the racquet and what didn't save. The card shows the server state. |
| Racquet that fails to load | Bag | Left out of the bag silently, by design. The failure is reported to Crashlytics. |
| Dead strings (< 40%) | Racquet Card | Critical treatment and `⚠ Restring`. In v1 this in-app critical treatment takes the place of notifications. |
| Loading | Racquet Detail | A skeleton of the detail layout until the racquet arrives. |
| Removed elsewhere | Racquet Detail | Returns to the bag, and the snackbar says `Wilson Blade 98 was deleted on another device.` |
| Racquet deleted here | Racquet Detail → Bag | Returns to the bag. If it was primary, `resolvePrimary` picks the next default with no prompt. |
| Loading | Sessions | A progress row while the first page arrives. |
| No sessions | Sessions | `No sessions yet. Log one from your bag.` |
| Filter matches nothing | Sessions | `No sessions with Wilson Blade 98 yet.` The filter chips stay visible. |
| Signed out | Welcome | The plain welcome screen. |
| Sign-in canceled | Welcome | Silent return. |
| Sign-in failed | Welcome | Inline: `Couldn't sign in. Check your connection and try again.` It stays until the next attempt. |
| Web pop-up blocked | Welcome | Inline: `Allow pop-ups for this site to sign in with Google.` |
| Re-authentication canceled | Settings | The dialog closes, the user stays signed in, and a persistent snackbar says `Account not deleted.` |
| Re-authentication with another account | Settings | Persistent snackbar: `That's a different Google account. Account not deleted.` |
| Deletion failed | Settings | Inline under the Delete Account & All Data row, and in a persistent snackbar with `Retry`: `Couldn't delete your account. Check your connection and try again.` The bag keeps working. |
| Deletion succeeded | Welcome | The user is signed out. `Your account and all data were deleted.` stays on the welcome screen for that visit and is announced. |

## Interaction Primitives

* Tap to act. The card body opens Racquet Detail, and card buttons act directly.
* Sheets close by swipe-down, the scrim, the Sheet Close Button, or `Esc`.
* Pull-to-refresh isn't offered.
* **Keyboard (web):**
  * `L` opens the Quick-Log Sheet, and `N` opens the Add Racquet Form.
  * Both work only on the bag, only while no sheet or dialog is open and no text field has focus, and only while the Keyboard shortcuts switch is on.
  * The tooltips on the FAB and `[+ Add Racquet]` show the keys.
  * `Esc` closes the top sheet or dialog.
* **Hover (web):** the Level 2 treatment from DESIGN.md. It never replaces the focus ring.

## Accessibility Floor

These rules cover behavior. Visual contrast lives in DESIGN.md → Colors → Contrast.

**Perception**
* **Targets:** every interactive element, including each chip, is at least `{spacing.touch-min}` × `{spacing.touch-min}`.
* **Not color alone:** every health color comes with its Tier Label. Selected chips and racquet-selector items show a check icon.
* **Text scaling (200%):**
  * Text scales up to 200% without clipping.
  * Surfaces to verify: Racquet Card, gauge, Quick-Log Sheet, Restrung Today Sheet, Destructive Confirmation Dialog, navigation labels, Snackbar, and Restring History Timeline.
  * Chip rows wrap, and sheets scroll with the keyboard inset while keeping their primary action pinned.
* **Reduce motion:** when it's on, the gauge, sheet and dialog transitions, the snackbar slide, and the shimmer are all static.

**Screen-reader semantics**
* **Card semantics:** each card is one container.
  * The card's `Open details` action label merges the name, string line, and gauge label.
  * Two sibling buttons follow: `Log session for {racquet}` and `Restrung today: {racquet}`.
* **Gauge label:** for example, `Wilson Blade 98: string health 82 percent, Optimal, 4 hours played, 12 hours remaining until dead zone`.
  * Pending writes add `, waiting to sync`.
  * The label always uses the settled value, never the animating one.
  * Semantics labels drop the `✓ ~ ⚠` glyphs.
* **No live regions:** cards, gauges, and the Bag Sync Summary aren't live regions. Only outcomes of actions the user started are announced, through the snackbar. The Bag Sync Summary is part of the bag header, so it can be read on demand.
* **Chip semantics:** chips expose their selected state in a mutually exclusive group. Duration chips read `30 minutes`, `1 hour`, `1 and a half hours`, and `2 hours`.
* **Timeline semantics:** each entry reads in full words, for example `August 1 to October 2, Luxilon ALU Power, 19.2 court hours, 62 days`.
* **Headings:** screen titles, sheet and dialog titles, and settings group labels are headings.
* **Inline auth messages:** polite announcements that stay visible until the next attempt.

**Keyboard and focus**
* **Focus ring:** keyboard focus always shows `{components.focus-ring}`, and focus order follows reading order.
* **Focus return:**
  * Closing a sheet or dialog returns focus to the control that opened it.
  * After a racquet is deleted, focus moves to the bag header.
  * After account deletion, focus moves to the welcome headline.
  * Dismissing the auto-opened Add Racquet Form moves focus to `[Add Your First Racquet]`.
* **Destructive dialog:** keyboard focus starts on `Cancel`. The screen-reader reading order is title, body, Cancel, confirm. The Delete Account body also says Google may ask the user to confirm their account.

## Responsive & Platform

| Width | Navigation | Bag layout | Forms and sheets |
|---|---|---|---|
| Compact (< 600dp) | Bottom navigation bar | 1 column | Modal bottom sheets |
| Medium (600–1024dp) | `NavigationRail` | 2-column grid | Modal bottom sheets |
| Expanded (> 1024dp) | Persistent navigation drawer | 3-column grid | Centered dialogs |

The breakpoints follow the shipped `VirtualBagScreen` (600 and 1024) rather than M3's 840.

* **Android:** Google sign-in uses the system account sheet, and Privacy Policy opens in the browser. The app never shows a permission prompt.
* **Web:**
  * Google sign-in uses a pop-up. Tabs share one offline cache and stay in sync.
  * The app turns on Flutter semantics at startup and declares `lang="en"`. Every route sets its own page title, such as `My Virtual Bag — String Theory` and `Wilson Blade 98 — String Theory`.
  * User text-spacing overrides don't apply to Flutter's canvas text. This is a known limitation, so 200% text scale and browser zoom are supported instead.
* **Play Console:** the account-deletion URL points to the hosted web app (PRD OQ-3), where the user signs in and uses Settings → Delete Account & All Data. The privacy policy URL is `/privacy.html`, which repeats those steps and links to the app.

## Inspiration & Anti-patterns

There are no external inspiration products. The only visual reference is the mockup linked from DESIGN.md.

* **Rejected — type-to-confirm deletion:** a single clear dialog is enough, and the extra friction adds nothing for the Play review path.
* **Rejected — required metadata or advanced options in the logger (split time, surface, notes):** they break the sub-10-second promise (PRD SM-C1).
* **Rejected — a "Working Offline" banner:** offline is normal on court, and per-card `Waiting to sync` lines say what matters without alarm.
* **Rejected — demo or simulator controls and the sample bag:** removed with the hackathon build (PRD non-goals).
* **Rejected — workout auto-detection and notification permission prompts:** no health or notification permissions in v1 (PRD non-goals, NFR-6).

## Key Flows

The percentages are illustrative, and tests take their expected values from `RacquetHealth.of`. Upstream Notes for the PRD lists the known mismatches.

### Flow 1 — Marco Logs Playtime in 5 Seconds After a Match (UJ-1)

Marco (34), an intermediate club player, has just finished a 90-minute doubles match. He's signed in, and his phone is in his tennis bag.

1. Marco opens String Theory to the Virtual Bag.
2. He taps the Log Session FAB.
3. The Quick-Log Sheet opens with `1h` selected and his primary racquet, Wilson Blade 98, highlighted.
4. He taps `1.5h`.
5. He taps `Save Session`, and the sheet closes at once, even with weak signal.
6. **Climax:** the Blade's gauge sweeps from 76% to 67% and its label changes from `Optimal` to `Caution`. The card reads `~1.4 lbs tension drop • 11 h left`, and the snackbar reads `1.5h logged • Wilson Blade 98 at 67%`.
7. Marco pockets his phone. Three taps, under 5 seconds.

**Failure:** with no signal, the card shows `Waiting to sync` until it syncs. If the racquet was deleted on another device, a persistent snackbar says the 1.5h session wasn't saved.

### Flow 2 — Elena Onboards and Adds Her First Racquet (UJ-2)

Elena (28) is a recreational player recovering from wrist soreness, and her coach recommended the app. This is her first launch, on Android or web.

1. The welcome screen explains string health and arm protection and shows `Sign in with Google`.
2. She taps it and picks her account in one tap.
3. Her bag is empty, so the Add Racquet Form opens by itself.
4. She types `Babolat Pure Drive` as the racquet name and picks `Monofilament`, and Max court hours fills in as 20. She enters `Babolat RPM Blast 1.25` as the string brand & model and sets the stringing date to three weeks ago.
5. She taps `Save Racquet`.
6. **Climax:** the form closes on her bag. The Pure Drive card's gauge animates up to 88% `Optimal`, with three weeks of shelf life already counted.
7. Her bag is saved to her account and appears on any device she signs in on.

**Failure:** if she cancels the Google sheet, she returns to Welcome silently. With no connection she sees `Couldn't sign in…` and can retry.

### Flow 3 — David Gets Restrung and Resets the Gauge (UJ-3)

David (42), a weekend warrior, has a Head Radical at 34% (`⚠ Restring`) after 19 hours and 70 days. He has just collected it from the pro shop with fresh Head Lynx.

1. David opens the app, and the Head Radical card is in its critical treatment.
2. He taps `[Restrung Today]`.
3. The sheet asks `Restrung with the same setup (Head Lynx 1.25 @ 52 lbs)?`
4. He taps `[Keep Same & Reset]`.
5. **Climax:** the gauge sweeps up to 100% `Optimal`, the critical treatment lifts, and the snackbar reads `Fresh stringbed mounted! Restrung to 100% health.`
6. Later, on Racquet Detail, the timeline shows `Aug 13 – Oct 22 • Head Lynx 1.25 • 19 court hours • 70 days`.

**Variant:** if the strings broke and he switched brands, he taps `[Change Strings]`, edits the fields, picks `Strings broke`, and taps `Save & Reset`.

**Failure:** if the same job was already restrung offline on another device, a persistent snackbar says this restring wasn't saved, and the card shows the other device's restring.

### Flow 4 — Play Store User Exercises Mandatory Account Deletion (UJ-4)

The user is signed in on Android or the hosted web app, or is a Google Play reviewer arriving from the Play Console.

1. They open Settings. A reviewer following the Play Console deletion URL lands on the web app, signs in, and opens Settings.
2. They tap `[Delete Account & All Data]`.
3. The dialog reads: `This permanently deletes your account, all racquets, string history and sessions. Google may ask you to confirm your account. This can't be undone.` The buttons are `Cancel` and `Delete Account`.
4. They tap `Delete Account` and, if Google asks, confirm the same account.
5. **Climax:** they land on Welcome with `Your account and all data were deleted.` Everything under their account is purged on the server.

**Failure:** if they cancel the Google confirmation, they stay signed in and see `Account not deleted.` If they pick another account, they see `That's a different Google account. Account not deleted.` With no connection, they get the inline and snackbar error with `Retry`.

### Flow 5 — Marco Retires an Old Frame (no UJ)

Marco (34), from Flow 1, has replaced his old Wilson Blade, saved as `Wilson Blade 98 (old)`, with a new one.

1. He opens the new Blade's Racquet Detail and taps `Set as Primary`.
2. Back on the bag, he opens the old frame's Racquet Detail and taps `Delete Racquet`.
3. The dialog reads `Delete Wilson Blade 98 (old)? Its string history is removed. Sessions you logged stay in your history.`, with `Cancel` and `Delete Racquet`.
4. **Climax:** he's back on the bag with focus on the header. The old card is gone, and the new Blade leads the list as the primary racquet.

**Failure:** if the racquet was already deleted on another device, Racquet Detail returns to the bag with `Wilson Blade 98 (old) was deleted on another device.`

## Open Questions

* **Web Analytics consent (EU visitors).** Does the web app need a consent banner or Consent Mode before Analytics collects data? This is carried over from the architecture spine. It doesn't block the Android launch, but it must be decided before the web URL is announced. If a banner is needed, it gets a surface here.
* **Where the Keyboard shortcuts setting lives (architecture).** The architecture removes `shared_preferences`, and the AD-3 user document has no settings field. Before the shortcuts story, the architecture needs to choose between browser storage (a dependency that needs approval) and a field on `/users/{uid}` (an AD-3 change). Until then, the Keyboard shortcuts switch resets to on with each visit.

## Upstream Notes for the PRD

These notes are for the PM. The spines don't change the PRD.

* The UJ-2 (88%) and UJ-3 (34%) figures don't match the FR-9 formula with the default constants. Monofilament gives 92% after 21 days (UJ-2) and about 6% after 19 h and 70 days (UJ-3).
* The PRD has no accessibility NFR. The WCAG 2.2 AA target in Foundation should become one.
* FR-4 says `[Delete Account & Data]`, but UJ-4 says `[Delete Account & All Data]`. The spines use the UJ-4 label.
* FR-17 says "chronological". The spines read that as newest first.
