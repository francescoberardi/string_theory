---
name: String Theory — Court Midnight
description: Dark, athletic visual system for String Theory v1, a Flutter string-health tracker for Android and Web on Firebase.
status: final
created: 2026-10-02
updated: 2026-10-24
colors:
  background: '#121516'
  surface: '#1A1E20'
  surface-elevated: '#23282C'
  surface-border: '#2A3034'
  outline: '#6B767B'
  primary: '#C6F10E'
  on-primary: '#000000'
  primary-muted: '#8DAA0A'
  text-primary: '#FFFFFF'
  text-secondary: '#9EAAAF'
  text-tertiary: '#606B70'
  health-optimal: '#10B981'
  health-degraded: '#F59E0B'
  health-critical: '#EF4444'
  health-critical-bg: '#2A1416'
typography:
  display:
    fontFamily: 'Barlow Condensed'
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 38px
  card-title:
    fontFamily: 'Barlow Condensed'
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 26px
  section:
    fontFamily: 'Inter'
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
  body:
    fontFamily: 'Inter'
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-secondary:
    fontFamily: 'Inter'
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  metric-hero:
    fontFamily: 'Barlow Condensed'
    fontSize: 28px
    fontWeight: '800'
    lineHeight: 30px
  data:
    fontFamily: 'JetBrains Mono'
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
rounded:
  md: 12px
  lg: 18px
  full: 9999px
spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  touch-min: 48px
components:
  focus-ring:
    color: '{colors.primary}'
    width: 2px
    offset: 2px
  radial-health-gauge:
    size-card: 64px
    track: '{colors.surface-border}'
    arc-optimal: '{colors.health-optimal}'
    arc-degraded: '{colors.health-degraded}'
    arc-critical: '{colors.health-critical}'
    value: '{typography.metric-hero}'
    animation: 750ms ease-out
  racquet-card:
    background: '{colors.surface}'
    border: '{colors.surface-border}'
    radius: '{rounded.lg}'
    title: '{typography.card-title}'
    specs: '{typography.body-secondary}'
  racquet-card-critical:
    background: '{colors.health-critical-bg}'
    border: '{colors.health-critical}'
  tier-label:
    type: '{typography.body-secondary}'
    optimal: '{colors.health-optimal}'
    caution: '{colors.health-degraded}'
    restring: '{colors.health-critical}'
  badge-primary:
    text: '{colors.primary}'
    border: '{colors.primary}'
    radius: '{rounded.full}'
  sync-pending-marker:
    text: '{colors.text-secondary}'
    type: '{typography.body-secondary}'
  button-primary:
    background: '{colors.primary}'
    text: '{colors.on-primary}'
    radius: '{rounded.md}'
    min-height: '{spacing.touch-min}'
  button-secondary:
    border: '{colors.primary-muted}'
    text: '{colors.primary-muted}'
    radius: '{rounded.md}'
    min-height: '{spacing.touch-min}'
  button-text:
    text: '{colors.primary}'
    min-height: '{spacing.touch-min}'
  button-destructive:
    background: '{colors.health-critical}'
    text: '{colors.on-primary}'
    radius: '{rounded.md}'
    min-height: '{spacing.touch-min}'
  fab:
    background: '{colors.primary}'
    icon: '{colors.on-primary}'
    radius: '{rounded.md}'
  nav-indicator:
    active: '{colors.primary}'
    active-content: '{colors.on-primary}'
    inactive-content: '{colors.text-secondary}'
  choice-chip:
    background: '{colors.surface}'
    border: '{colors.outline}'
    selected-background: '{colors.primary}'
    selected-text: '{colors.on-primary}'
    radius: '{rounded.md}'
  racquet-selector:
    border: '{colors.outline}'
    selected-border: '{colors.primary}'
    selected-border-width: 2px
  text-field:
    border: '{colors.outline}'
    focused-border: '{colors.primary}'
    error-border: '{colors.health-critical}'
    radius: '{rounded.md}'
  sheet:
    background: '{colors.surface-elevated}'
    radius: '{rounded.lg}'
  dialog:
    background: '{colors.surface-elevated}'
    radius: '{rounded.lg}'
  snackbar:
    background: '{colors.surface-elevated}'
    text: '{colors.text-primary}'
    action: '{colors.primary}'
  google-sign-in-button:
    note: 'Google Sign-In branding guidelines, dark theme variant. Google owns the rendered values.'
---

# String Theory — Court Midnight

## Brand & Style

String Theory uses a **Court Midnight** visual language: the focused dark of a night match under floodlights, lit by the neon of a fresh tennis ball.

* **Emotional tone:** athletic, precise, preventive, and satisfying.
* **Hero accent:** Electric Volt (`{colors.primary}`) draws the eye to primary actions, selection, and keyboard focus without tiring it.
* **Surfaces:** deep charcoal layers (`{colors.background}` → `{colors.surface}` → `{colors.surface-elevated}`) create depth without heavy borders.
* **Health triad:** the 0–100% Health Score moves through three athletic signal colors: Emerald, Amber, and Crimson. Each tier always comes with a text label.

The theme is dark only. It is implemented as `CourtMidnightTheme` in `string_theory_flutter/lib/theme/court_midnight_theme.dart` through `ThemeData` and `ThemeExtension`s, and widgets never hardcode these values. The front matter is the source of truth if it ever disagrees with a table below.

→ The look at a glance: [`string_theory_mockup.jpg`](string_theory_mockup.jpg). See Components → Racquet Card for what not to copy from it.

## Colors

| Token | Hex | Use |
|---|---|---|
| `background` | `#121516` | App scaffold and window background. |
| `surface` | `#1A1E20` | Racquet cards, navigation bar and rail, unselected chips. |
| `surface-elevated` | `#23282C` | Sheets, dialogs, snackbars. |
| `surface-border` | `#2A3034` | Decorative only: card outlines, dividers, the gauge track. |
| `outline` | `#6B767B` | Interactive boundaries: text fields, unselected chips, the racquet selector. Maps to `colorScheme.outline`. |
| `primary` | `#C6F10E` | Electric Volt: primary buttons, the FAB, selected chips, the active navigation indicator, the focus ring. |
| `on-primary` | `#000000` | Text and icons on `primary` and on `health-critical` fills. |
| `primary-muted` | `#8DAA0A` | Secondary button outline and label. |
| `text-primary` | `#FFFFFF` | Titles, health scores, racquet names, error text. |
| `text-secondary` | `#9EAAAF` | Specs, hours, timestamps, hints, unit labels, the sync-pending marker. |
| `text-tertiary` | `#606B70` | Disabled controls and decorative glyphs only. Never readable text. |
| `health-optimal` | `#10B981` | Score ≥ 70%: arc and `Optimal` label. |
| `health-degraded` | `#F59E0B` | Score 40–69%: arc and `Caution` label. |
| `health-critical` | `#EF4444` | Score < 40%: arc, critical border, `Restring` label. Also the fill of destructive buttons and the error outline on fields. |
| `health-critical-bg` | `#2A1416` | Background tint for critical racquet cards. |

**Crimson's two jobs.** `{colors.health-critical}` marks dead strings and destructive actions. The destructive *fill* appears only on the confirm button inside a Destructive Confirmation Dialog. The triggers that open those dialogs (the Delete Racquet app-bar action and the Settings Delete Account & All Data row) use `text-primary` text with a `health-critical` icon, so no screen shows a Crimson button next to a Crimson gauge.

**Crimson as text.** It is allowed only on `background` and `health-critical-bg`. Elsewhere, error text is `text-primary` preceded by a `health-critical` ⚠ icon.

**Theme constants.** `CourtMidnightTheme` names these tokens `background`, `surface`, `surfaceElevated`, `surfaceBorder`, `primaryVolt` (`primary`), `primaryMuted`, `textPrimary`, `textSecondary`, `textTertiary`, `healthOptimal`, `healthDegraded`, `healthCritical`, and `healthCriticalBg`. `outline`, `on-primary`, and the `focus-ring` are new theme fields, and the shipped `bodySmall` moves from `textTertiary` to `textSecondary`.

### Contrast (WCAG 2.2 AA)

Every pair below meets its target. A new pair needs a ratio added here before it ships.

| Pair | Ratio | Target |
|---|---|---|
| `text-primary` on `background` / `surface` / `surface-elevated` / `health-critical-bg` | 18.4 / 16.8 / 14.9 / 17.4 | 4.5 |
| `text-secondary` on `background` / `surface` / `surface-elevated` / `health-critical-bg` | 7.7 / 7.1 / 6.3 / 7.3 | 4.5 |
| `on-primary` on `primary` | 16.0 | 4.5 |
| `on-primary` on `health-critical` (destructive button) | 5.6 | 4.5 |
| `primary-muted` on `surface-elevated` | 5.6 | 4.5 |
| `primary` on `surface-elevated` (snackbar action, text button) | 11.3 | 4.5 |
| `health-optimal` / `health-degraded` label on `surface` | 6.6 / 7.8 | 4.5 |
| `health-critical` label on `health-critical-bg` / `background` | 4.6 / 4.9 | 4.5 |
| `outline` on `surface` / `background` / `surface-elevated` | 3.6 / 3.9 / 3.2 | 3.0 (non-text) |
| Gauge arcs on `surface` (optimal / degraded / critical) | 6.6 / 7.8 / 4.5 | 3.0 (non-text) |
| `focus-ring` on `background` / `surface` / `surface-elevated` | 14.0 / 12.8 / 11.3 | 3.0 (non-text) |

## Typography

Fonts load through `google_fonts`: Barlow Condensed for display and numbers, Inter for UI text, and JetBrains Mono for data.

| Token | Family | Weight | Size / line height | Use | Theme slot |
|---|---|---|---|---|---|
| `display` | Barlow Condensed | 700 | 32 / 38 | Screen headers ("My Virtual Bag"), the welcome headline | `headlineLarge` |
| `card-title` | Barlow Condensed | 600 | 22 / 26 | Racquet names | `titleLarge` |
| `section` | Inter | 600 | 16 / 22 | Sheet and dialog titles, settings group labels | `titleMedium` |
| `body` | Inter | 400 | 14 / 20 | Descriptions, notes, dialog body | `bodyMedium` |
| `body-secondary` | Inter | 500 | 12 / 16 | Specs, tier labels, timeline meta, the sync-pending marker | `bodySmall` (color `text-secondary`) |
| `metric-hero` | Barlow Condensed | 800 | 28 / 30 | The number in the center of a gauge | `ThemeExtension` field `metricHero` |
| `data` | JetBrains Mono | 400 | 12 / 16 | Tension, hours, timeline dates | `ThemeExtension` field `data` (new) |

Sizes are Flutter logical pixels and scale with the system text size.

## Layout & Spacing

* **Grid:** everything is a multiple of 4. `{spacing.xs}` is badge padding, `{spacing.sm}` is spacing inside cards, `{spacing.md}` is container padding and list gaps, `{spacing.lg}` is the mobile screen margin, and `{spacing.xl}` separates sections.
* **Touch targets:** every button, chip, icon action, and sheet close button is at least `{spacing.touch-min}` × `{spacing.touch-min}`.
* **Bag grid:** 1, 2, or 3 columns by width class (EXPERIENCE.md → Responsive & Platform).

## Elevation & Depth

* **Level 0:** `{colors.background}`.
* **Level 1 (cards):** `{colors.surface}` with a 1px `{colors.surface-border}` outline and no shadow.
* **Level 2 (hover, web only):** `{colors.surface-elevated}` with a soft `{colors.primary}` glow at 12% opacity and 16px blur. Hover never stands in for focus.
* **Level 3 (sheets and dialogs):** `{colors.surface-elevated}` over the M3 default scrim with a 10σ backdrop blur.
* **Keyboard focus:** `{components.focus-ring}`, a 2px `{colors.primary}` outline drawn 2px outside the component and following its radius. On `primary`-filled controls the offset puts the ring on the surrounding surface.

## Shapes

* **Cards, sheets, and dialogs:** `{rounded.lg}`.
* **Buttons, the FAB, chips, and text fields:** `{rounded.md}`.
* **Badges and gauges:** `{rounded.full}`.

## Components

**Inherited from Material 3, styled only by these tokens:** AppBar, NavigationBar, NavigationRail, NavigationDrawer, FloatingActionButton, FilledButton, OutlinedButton, TextButton, ChoiceChip, FilterChip, TextField with OutlineInputBorder, the date picker, modal bottom sheet, AlertDialog, SnackBar, ListTile (settings rows), and progress indicators. Their layout and motion stay at M3 defaults. The entries below are the only brand-specific components, listed in the same order as EXPERIENCE.md → Component Patterns.

### Radial Health Gauge
* A round-capped circular arc on a 6px `{colors.surface-border}` track. The arc is colored `{colors.health-optimal}`, `{colors.health-degraded}`, or `{colors.health-critical}` by tier.
* The center shows the percentage in `{typography.metric-hero}` above an uppercase `HEALTH` micro-label.
* **Size:** `{components.radial-health-gauge.size-card}` on cards, and at least twice that on Racquet Detail. The diameter scales with the text scaler, so the center text never clips.
* **Motion:** value and color tween over 750 ms ease-out. When reduce motion is on, they change without animating.

### Tier Label
* `✓ Optimal`, `~ Caution`, or `⚠ Restring` in `{typography.body-secondary}`, colored by `{components.tier-label}`.

### Racquet Card
* **Left:** the gauge, with the Tier Label below it.
* **Center:**
  * the racquet name (`{typography.card-title}`), which wraps and is never truncated
  * the string line: brand & model, or the material when there's no brand & model, plus `@ {tension} lbs` when a tension is set
  * the usage line: `{hours} h played • {days} days`
  * the companion line: `~{x} lbs tension drop • {n} h left`. The tension part is omitted when no tension is set. At 0 hours left the line reads `Restring recommended`.
  * Every line after the name uses `{typography.body-secondary}` in `{colors.text-secondary}`.
* **Right:** `[Restrung Today]` (`button-secondary`) and `Log` (`button-text` with a timer icon).
* **Critical (< 40%):** `racquet-card-critical`, with a `health-critical` border on a `health-critical-bg` fill. The Tier Label reads `⚠ Restring`. Nothing pulses.
* **Sync pending:** a `Waiting to sync` line (`{components.sync-pending-marker}`) with a cloud-upload icon sits under the usage line. It never changes the card's color or border.
* **Large text:** at a text scale of 130% or more, or whenever the content doesn't fit, the two actions move to a full-width row under the content.

→ Visual reference: [`string_theory_mockup.jpg`](string_theory_mockup.jpg) shows a compact-width bag. Use it for card anatomy and gauge styling only. **Do not copy:**
* the iPhone frame (iOS is out of scope)
* the five-tab navigation (v1 has Bag, Sessions, and Settings)
* match results (`Single Match (Win)`)
* the orange 45% card (45% is Caution, in Amber)
* the `Needs Restring!` and `ACTIVE` labels (use `⚠ Restring` and `Primary`)
* `New Racquet +` (use `+ Add Racquet`)
* glowing resting cards (Level 1 has no shadow)
* the ¾ arc with a knob (the gauge is a full ring)
* racquet photos (no image field exists)
* the missing card actions (cards always show Restrung Today and Log)

DESIGN.md and EXPERIENCE.md win over the mockup on any conflict.

### Primary Badge
* A `Primary` pill (`{components.badge-primary}`): `{colors.primary}` text and a 1px `{colors.primary}` border on a transparent fill. It appears on Racquet Detail only.

### Bag Sync Summary
* A single `{typography.body-secondary}` line in `{colors.text-secondary}` under the bag header, for example `2 changes waiting to sync`. It has no background and no banner chrome.

### Log Session FAB
* A `{components.fab}` with an add icon and the label `Log Session`. It's extended on medium and expanded widths, and icon-only on compact widths.

### Quick-Log Sheet
* A `{components.sheet}` with the title `Log Session` in `{typography.section}` and a Sheet Close Button.
* **Duration row:** four `{components.choice-chip}`s (`30m`, `1h`, `1.5h`, `2h`). The selected chip shows a check icon.
* **Racquet row:** `{components.racquet-selector}` items that wrap onto more lines rather than scrolling sideways. The selected item has a 2px `{colors.primary}` border and a check icon.
* **Action:** a full-width `{components.button-primary}` labeled `Save Session`, pinned to the bottom of the sheet.

### Restrung Today Sheet
* A `{components.sheet}` with a Sheet Close Button. It shows the same-setup question in `{typography.body}`, with the setup in `{typography.data}`.
* `[Keep Same & Reset]` is a `button-primary`, and `[Change Strings]` is a `button-secondary`.
* Change Strings expands inline into the String material, String brand & model, Stringing date, Tension, and Max court hours fields. Below them is a `{components.choice-chip}` row: `Routine restring` (selected by default), `Strings went dead`, and `Strings broke`. `Save & Reset` is pinned to the bottom.

### Sheet Close Button
* An M3 icon button (close icon) at the right of every sheet header, at least `{spacing.touch-min}` × `{spacing.touch-min}`.

### Add Racquet Form
* Full-width `{components.text-field}`s in a sheet on compact and medium widths, and in a centered dialog on expanded widths.
* String material is a single-select `{components.choice-chip}` row with four options. The stringing date uses the M3 date picker.
* Required fields carry `(required)` in the label. Helper text uses `{colors.text-secondary}`, for example `Suggested for Monofilament` under Max court hours.
* **Errors:** the field outline turns `{colors.health-critical}`, and the message below it is `text-primary` after a `health-critical` ⚠ icon.

### Edit Racquet Form
* Same container and field styling as the Add Racquet Form, with Racquet name and Notes only.

### Racquet Detail
* An M3 app bar with icon buttons and tooltips for `Edit`, `Set as Primary`, and `Delete Racquet`. The Primary Badge sits next to the racquet name.
* A single column in this order: the gauge and Tier Label, the usage and companion lines, the current setup and stringing date, `[Restrung Today]` (`button-secondary`), then the Restring History Timeline.

### Restring History Timeline
* A vertical list. Each row has two lines: the dates in `{typography.data}`, then the string, hours, and days in `{typography.body-secondary}`. Dead and broken jobs add a `{colors.health-critical}` ⚠ icon and the reason in `{colors.text-secondary}`.

### Session Feed
* M3 list rows on `{colors.background}` showing the date (`{typography.data}`), duration, and racquet name. Above the list is a wrapping `FilterChip` row of racquets.

### Skeleton Card
* A racquet-card-shaped `{colors.surface}` block with `{colors.surface-border}` placeholder bars and a shimmer that stops after 5 s. It's static when reduce motion is on.

### Destructive Confirmation Dialog
* A `{components.dialog}` with a `{typography.section}` title and a `{typography.body}` paragraph listing what will be removed. `Cancel` is a `button-text`, and the confirm button is a `button-destructive`.

### Settings Rows
* M3 `ListTile`s, with group labels in `{typography.section}`.
* The Delete Account & All Data row uses `text-primary` text with a `{colors.health-critical}` delete icon.
* The Keyboard shortcuts row (web only) is a switch tile.

### Welcome / Sign-In Screen
* On `{colors.background}`: the wordmark, a `{typography.display}` headline, and one `{typography.body}` line about string health and arm protection.
* `{components.google-sign-in-button}` is the only call to action and follows Google's dark-variant branding.
* Inline status text sits below the button in `{colors.text-secondary}`. Error text uses `text-primary` after a `health-critical` ⚠ icon.

### Snackbar
* `{components.snackbar}`, with a `{colors.primary}` text action when there is one (`Dismiss` or `Retry`).

## Do's and Don'ts

* ✅ **Do** use Electric Volt sparingly: primary actions, the FAB, selection, the active navigation indicator, and focus.
* ✅ **Do** show a text label with every health color.
* ✅ **Do** draw `{components.focus-ring}` on every focusable element when it has keyboard focus.
* ✅ **Do** add a contrast ratio to the Contrast table before introducing a new color pair.
* ❌ **Don't** use pure black for surfaces. `on-primary` black is only for text and icons on Electric Volt or Crimson fills.
* ❌ **Don't** use `text-tertiary` for anything a user needs to read.
* ❌ **Don't** use `surface-border` for an interactive boundary; use `outline`.
* ❌ **Don't** restyle the Google Sign-In button with brand tokens.
* ❌ **Don't** add fields or an advanced section to the Quick-Log Sheet.
* ❌ **Don't** use pulsing, blinking, or looping animation on cards or badges.
* ❌ **Don't** signal sync state with color.
