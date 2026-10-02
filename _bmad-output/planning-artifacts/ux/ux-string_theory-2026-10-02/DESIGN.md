---
name: String Theory Design System
status: final
created: 2026-10-02
updated: 2026-10-02
mockup: "string_theory_mockup.jpg"
tokens:
  colors:
    background: "#121516"
    surface: "#1A1E20"
    surfaceElevated: "#23282C"
    surfaceBorder: "#2E353B"
    primary: "#C6F10E"
    primaryMuted: "#8DAA0A"
    textPrimary: "#FFFFFF"
    textSecondary: "#9EAAAF"
    textTertiary: "#606B70"
    healthOptimal: "#10B981"
    healthDegraded: "#F59E0B"
    healthCritical: "#EF4444"
    healthCriticalBg: "#2A1416"
  typography:
    fontHeading: "Barlow Condensed"
    fontBody: "Inter"
    fontMono: "JetBrains Mono"
  rounded:
    sm: 6
    md: 12
    lg: 18
    xl: 24
    full: 9999
  spacing:
    xs: 4
    sm: 8
    md: 16
    lg: 24
    xl: 32
---

# String Theory Design System
**Visual Specification & Theme Tokens for Serverpod & Flutter**

## Brand & Style

String Theory embraces a **Court Midnight (High-Performance Athletic)** visual language. It combines the sleek, focused darkness of night matches under stadium floodlights with the high-visibility neon glow of a pressurized tennis ball.

* **Emotional Tone:** Athletic, precise, preventive, satisfying.
* **Hero Accent:** Electric Tennis Volt (`#C6F10E`) commands focus for primary CTAs and active states without visual fatigue.
* **Surface Strategy:** Deep charcoal layers (`#121516` $\rightarrow$ `#1A1E20` $\rightarrow$ `#23282C`) create subtle depth without harsh borders.
* **Health Triad:** The 0–100% Health Score shifts through clear athletic signal colors: Emerald (`#10B981`), Amber (`#F59E0B`), and Crimson (`#EF4444`).

---

## Colors

| Token Name | Hex Code | Purpose & Application |
|---|---|---|
| `background` | `#121516` | Main application scaffold & window background. |
| `surface` | `#1A1E20` | Racquet cards, bottom navigation bar, modals. |
| `surfaceElevated` | `#23282C` | Dialogs, active quick-log sheets, popovers. |
| `surfaceBorder` | `#2E353B` | 1px subtle card outlines and divider lines. |
| `primary` | `#C6F10E` | Electric Volt — primary action buttons, active tab indicators. |
| `primaryMuted` | `#8DAA0A` | Secondary button outlines and subtle accents. |
| `textPrimary` | `#FFFFFF` | Hero titles, health scores, racquet names. |
| `textSecondary` | `#9EAAAF` | String setup specs, court hours, timestamps. |
| `textTertiary` | `#606B70` | Inactive icons, helper hints, unit labels. |
| `healthOptimal` | `#10B981` | Score $\ge 70\%$ — vibrant green radial ring & badge. |
| `healthDegraded` | `#F59E0B` | Score $40\%–69\%$ — amber radial ring & cautionary state. |
| `healthCritical` | `#EF4444` | Score $< 40\%$ — dead stringbed warning, high shock alert. |
| `healthCriticalBg`| `#2A1416` | Background tint for critical health cards. |

---

## Typography

String Theory leverages Google Fonts (`google_fonts` in Flutter):

| Role | Font Family | Weight | Size / Line Height | Usage |
|---|---|---|---|---|
| **Display / H1** | Barlow Condensed | Bold (700) | 32sp / 38sp | Hero screen headers ("My Virtual Bag"). |
| **H2 / Card Title**| Barlow Condensed | SemiBold (600) | 22sp / 26sp | Racquet frame names ("Babolat Pure Aero"). |
| **H3 / Section** | Inter | SemiBold (600) | 16sp / 22sp | Modal titles, accordion labels. |
| **Body Primary** | Inter | Regular (400) | 14sp / 20sp | Session notes, descriptions. |
| **Body Secondary**| Inter | Medium (500) | 12sp / 16sp | String specs, court surface tags. |
| **Metric Hero** | Barlow Condensed | ExtraBold (800) | 28sp / 30sp | Center numbers in radial gauges (`84%`). |
| **Data / Mono** | JetBrains Mono | Regular (400) | 12sp / 16sp | Tension numbers, timers, workout IDs. |

---

## Layout & Spacing

* **8-Point Spatial Grid:** All margins, paddings, and gaps scale on multiples of 4 and 8:
  * `xs`: 4px (badge inner padding, icon offsets)
  * `sm`: 8px (element spacing inside cards)
  * `md`: 16px (standard container padding, list spacing)
  * `lg`: 24px (screen margins on mobile)
  * `xl`: 32px (section breaks, hero spacing)
* **Touch Targets:** Minimum 48x48dp for all interactive buttons and chip filters to ensure easy tapping with sweaty hands.

---

## Elevation & Depth

* **Level 0 (Flat):** Main background `#121516`.
* **Level 1 (Cards):** Surface `#1A1E20` with 1px border `#2E353B`, 0px shadow.
* **Level 2 (Hover / Active):** `#23282C` with subtle glow (`BoxShadow(color: primary.withOpacity(0.12), blurRadius: 16)`).
* **Level 3 (Modals & Sheets):** `#23282C` with 24px blur backdrop filter (`BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10))`).

---

## Shapes & Radii

* **Cards & Sheets:** `18px` (`rounded.lg`) — smooth modern rounded rectangles.
* **Buttons & Chips:** `12px` (`rounded.md`) — tactile, pill-adjacent corners.
* **Badges & Gauges:** `9999px` (`rounded.full`) — circular indicators.

---

## Components

### 1. The Radial Health Gauge
* **Structure:** Circular arc (`CustomPaint` or `CircularProgressIndicator` with stroke cap round).
* **Track:** 6px dark track (`#2E353B`).
* **Active Indicator:** 6px glowing arc colored by health state (`healthOptimal`, `healthDegraded`, `healthCritical`).
* **Center Payload:** Large Barlow Condensed percentage (e.g. `84%`) with micro-label `HEALTH` in uppercase.

### 2. Racquet Card
* **Layout:** Horizontal split card:
  * *Left:* Radial Health Gauge + remaining court hours.
  * *Center:* Racquet Name, String Model, installed tension.
  * *Right:* Racquet frame silhouette / badge + "Restrung" CTA.
* **Urgency States:** If health drops below 40%, the card border transitions to `healthCritical` with a pulsing warning icon `⚠️`.

### 3. Progressive Disclosure Quick-Log Sheet
* **Top:** Detected workout duration chip (e.g. `[1h 30m]`).
* **Center:** 1-tap horizontal carousel of registered racquets.
* **Bottom:** Expandable "Advanced options" accordion revealing surface selector and notes.

---

## Do's and Don'ts

* ✅ **DO** use Electric Volt (`#C6F10E`) sparingly for primary actions and active states.
* ✅ **DO** ensure gauge color transitions smoothly using animated tweens (60fps).
* ❌ **DON'T** use pure black `#000000` for backgrounds—deep graphite `#121516` reduces eye strain and enables layered card elevation.
* ❌ **DON'T** clutter the primary quick-log dialog with required fields; keep "Advanced options" collapsed by default.
