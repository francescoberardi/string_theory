# String Theory — 90-Second Hackathon Judge Showcase Script

This demo script provides a step-by-step presentation narrative engineered to showcase **String Theory** to Serverpod Hackathon judges in **about 90 seconds**.

---

## 🧰 Before You Start

- Run `serverpod start` (see the README) so the app opens in the browser.
- For the live-sync beat, prepare **two browser windows side by side, signed in to the same email account**: sign up once (the verification code is in the `serverpod start` output), tap `[⚡ Load Sample Bag]`, then open the app's address (the `http://localhost:<port>` page `serverpod start` opened) in a second window of the same browser, which is already signed in to that account.
- For Step 1, keep a **private window** on the sign-in screen (windows of one browser profile share the sign-in, so a normal window would open straight into the bag).

---

## ⏱️ Demo Timeline Overview

| Timestamp | Phase | Action / Screen | Key Talking Point |
|---|---|---|---|
| **0:00 - 0:10** | **The Problem & Sign-In** | Sign-in screen, tap `[Continue as guest]` | Co-poly strings die silently and hurt elbows. Email or one-tap guest sign-in, backed by Serverpod auth. |
| **0:10 - 0:20** | **Instant Seeding** | Tap `[⚡ Load Sample Bag]` | 1-tap demo bag seeds 3 racquets across Green, Amber, Red health tiers via Serverpod BagEndpoint. |
| **0:20 - 0:30** | **Health Ingestion** | Tap `[🧪 Simulate Workout]` (or press `S`) | Wearable workout ingested in background; instant assignment prompt appears in <3 seconds. |
| **0:30 - 0:45** | **Real-Time Decay** | Assign 90m match to Wilson Blade | Pure Dart `DecayEngine` drops health from 78% to 72% on the device and on the server. |
| **0:45 - 0:55** | **Restring Reset** | Tap `[Restrung Today]` on Head Radical | Dead stringbed (39% Red) resets instantly to 100% Green; previous job archived to historical timeline. |
| **0:55 - 1:05** | **Sessions History** | Open the `Sessions` tab | Every logged session in time order, with its source (simulated, Apple Health, Health Connect, manual). |
| **1:05 - 1:25** | **Live Two-Window Sync** | Prepared email account in two windows: log a session in A | Window B's gauge moves without a reload, over Serverpod streams on a per-user channel. |
| **1:25 - 1:30** | **Wrap-Up** | Resize a window / shortcuts (`L`, `N`, `S`, `Esc`) | Responsive layouts and keyboard accelerators across mobile, tablet, and web. |

---

## 🎬 Step-by-Step Presenter Script

### Step 1: The Problem & Sign-In (0:00 - 0:10)
- **Visual:** Show the **Court Midnight** sign-in screen: email sign-in and sign-up on top, `[Continue as guest]` below. Tap `[Continue as guest]`; the empty bag opens with a `GUEST` badge in the app bar.
- **Presenter Spoken Narrative:**
  > "Tennis players invest hundreds in co-polyester strings, but co-poly loses elasticity and tension within 10 to 15 hours. When dead, harsh vibrations travel directly into the player's elbow, risking injury. String Theory tracks it for you. Sign in with email, or, like we do now, continue as a guest with one tap."

---

### Step 2: Instant Bag Seeding (0:10 - 0:20)
- **Visual:** Tap `[⚡ Load Sample Bag]` on the empty state banner (or from the navigation drawer).
- **Presenter Spoken Narrative:**
  > "With a single tap, our Serverpod endpoint seeds a realistic player bag with three racquets:
  > - **Wilson Blade 98**: Freshly strung at 78% (Green — Optimal tension & pocketing)
  > - **Babolat Pure Drive**: Mid-life at 59% (Amber — Noticeable tension loss)
  > - **Head Radical MP**: Severely decayed at 39% (Red — Dead string alert!)"

---

### Step 3: Apple Health / Health Connect Ingestion (0:20 - 0:30)
- **Visual:** Press keyboard shortcut `S` (or tap `[🧪 Simulate Workout]` in the drawer/app bar).
- **Presenter Spoken Narrative:**
  > "Players finish a tennis session, and Apple Health or Health Connect syncs the workout. In String Theory, an unassigned workout banner immediately prompts the user in under 3 seconds: '90m Tennis Match detected'."

---

### Step 4: Real-Time Decay (0:30 - 0:45)
- **Visual:** Tap **Assign** $\rightarrow$ select the **Wilson Blade 98** $\rightarrow$ Confirm.
- **Presenter Spoken Narrative:**
  > "We assign the session to the Wilson Blade. Watch the radial health gauge: the composite decay calculation (70% court impact + 30% calendar aging) drops the health from 78% down to 72% instantly. Because the pure Dart DecayEngine is shared between client and server, the device and the backend cron jobs produce identical results."

---

### Step 5: 1-Tap Restring Reset & Historical Timeline (0:45 - 0:55)
- **Visual:** On the **Head Radical MP** (39% Red), tap `[Restrung Today]` $\rightarrow$ Confirm restringing $\rightarrow$ Tap card to inspect **Racquet Details & Timeline**.
- **Presenter Spoken Narrative:**
  > "The Head Radical is in the red hazard zone. One tap on 'Restrung Today' resets the stringbed to 100% Green, and the racquet details show the timeline: Serverpod archived the old string job and timestamped the restring."

---

### Step 6: Sessions History (0:55 - 1:05)
- **Visual:** Open the `Sessions` tab (bottom navigation on phones, rail or drawer on wider screens).
- **Presenter Spoken Narrative:**
  > "Every session lands in one history, newest first, with where it came from, including the simulated workout we just assigned."

---

### Step 7: Live Two-Window Sync (1:05 - 1:25)
- **Visual:** Switch to the two prepared windows signed in to the same email account. In window A press `L` (or tap **Log Session**), log a session on the Wilson Blade, and point at window B.
- **Presenter Spoken Narrative:**
  > "Here is one email account open in two windows. I log a session on the left... and the gauge on the right moves on its own, no reload. Serverpod streams push the new score to every client of this user, and only this user: a second account sees its own bag and none of these updates."

---

### Step 8: Wrap-Up (1:25 - 1:30)
- **Visual:** Resize a window or show the shortcuts (`L` to log, `N` for new racquet, `Esc` to dismiss).
- **Presenter Spoken Narrative:**
  > "Mobile, tablet and desktop layouts, keyboard shortcuts, a real backend and a real domain engine. Built for the Serverpod Hackathon."

---

## ⌨️ Desktop Keyboard Accelerators Reference

- `L`: Opens Quick Workout Logger modal
- `N`: Opens Add Racquet modal
- `S`: Triggers simulated workout ingestion
- `Esc`: Dismisses any active modal bottom sheet or dialog

---

## 🛠️ Fallback & Troubleshooting Tips

- **If the server is not running:** signing in needs the server, so `[Continue as guest]` shows an inline error with `Retry` on the sign-in screen. Once signed in, sessions logged while offline are queued and synced when the connection returns.
- **To start over as a new guest:** Settings $\rightarrow$ `[Sign Out]` returns to the sign-in screen (the old guest bag can't be reached again).
- **To reset demo state at any time:** Open the side drawer and tap `[⚡ Load Sample Bag]` again to restore the canonical 3-racquet baseline.
