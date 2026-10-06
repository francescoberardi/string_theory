# String Theory — 90-Second Hackathon Judge Showcase Script

This demo script provides a step-by-step presentation narrative engineered to showcase the full power of **String Theory** to Serverpod Hackathon judges in **under 90 seconds**.

---

## ⏱️ Demo Timeline Overview

| Timestamp | Phase | Action / Screen | Key Talking Point |
|---|---|---|---|
| **0:00 - 0:15** | **The Problem & Setup** | Fresh Launch / Empty Bag | Co-poly tennis strings die silently, causing arm pain ("tennis elbow"). Serverpod handles real-time decay tracking. |
| **0:15 - 0:30** | **Instant Seeding** | Tap `[⚡ Load Sample Bag]` | 1-tap demo bag seeds 3 racquets across Green, Amber, Red health tiers via Serverpod BagEndpoint. |
| **0:30 - 0:45** | **Health Ingestion** | Tap `[🧪 Simulate Workout]` (or press `S`) | Wearable workout ingested in background; instant assignment prompt appears in <3 seconds. |
| **0:45 - 1:05** | **Real-Time Decay** | Assign 90m match to Wilson Blade | Pure Dart `DecayEngine` drops health from 76% to 67% in real time with WebSocket sync. |
| **1:05 - 1:20** | **Restring Reset** | Tap `[Restrung Today]` on Head Radical | Dead stringbed (34% Red) resets instantly to 100% Green; previous job archived to historical timeline. |
| **1:20 - 1:30** | **Multi-Platform Polish** | Resize browser / Desktop shortcuts (`L`, `N`, `S`, `Esc`) | Responsive NavigationRail & Grid, keyboard accelerators, and hover glows across mobile, tablet, and web. |

---

## 🎬 Step-by-Step Presenter Script

### Step 1: The Problem & Anonymous Onboarding (0:00 - 0:15)
- **Visual:** Launch the app. Notice the **Court Midnight** dark aesthetic and immediate guest token creation.
- **Presenter Spoken Narrative:**
  > "Tennis players invest hundreds in co-polyester strings, but co-poly loses elasticity and tension within 10 to 15 hours. When dead, harsh vibrations travel directly into the player's elbow, risking injury. String Theory solves this with automated tracking powered by Serverpod. Notice how our guest session is immediately initialized with zero login friction."

---

### Step 2: Instant Bag Seeding (0:15 - 0:30)
- **Visual:** Tap `[⚡ Load Sample Bag]` on the empty state banner (or from the navigation drawer).
- **Presenter Spoken Narrative:**
  > "With a single tap, our Serverpod endpoint seeds a realistic player bag with three racquets:
  > - **Wilson Blade 98**: Freshly strung at 76% (Green — Optimal tension & pocketing)
  > - **Babolat Pure Aero**: Mid-life at 48% (Amber — Noticeable tension loss)
  > - **Head Radical MP**: Severely decayed at 34% (Red — Dead string alert!)"

---

### Step 3: Apple Health / Health Connect Ingestion (0:30 - 0:45)
- **Visual:** Press keyboard shortcut `S` (or tap `[🧪 Simulate Workout]` in the drawer/app bar).
- **Presenter Spoken Narrative:**
  > "Players finish a tennis session, and Apple Health or Health Connect syncs the workout. In String Theory, an unassigned workout banner immediately prompts the user in under 3 seconds: '90m Tennis Match detected'."

---

### Step 4: Real-Time Decay & WebSocket Sync (0:45 - 1:05)
- **Visual:** Tap **Assign** $\rightarrow$ select the **Wilson Blade 98** $\rightarrow$ Confirm.
- **Presenter Spoken Narrative:**
  > "We assign the session to the Wilson Blade. Watch the radial health gauge: the composite decay calculation (70% court impact + 30% calendar aging) drops the health from 76% down to 67% in real time. Because the pure Dart DecayEngine is shared between client and server, offline calculations and backend cron jobs produce 100% identical results."

---

### Step 5: 1-Tap Restring Reset & Historical Timeline (1:05 - 1:20)
- **Visual:** On the **Head Radical MP** (34% Red), tap `[Restrung Today]` $\rightarrow$ Confirm restringing $\rightarrow$ Tap card to inspect **Racquet Details & Timeline**.
- **Presenter Spoken Narrative:**
  > "The Head Radical is in the red hazard zone. After a fresh string job, one tap on 'Restrung Today' resets the stringbed to 100% Green. Opening the racquet details reveals the complete timeline: Serverpod archived the old string job and timestamped the restringing event."

---

### Step 6: Multi-Platform Adaptability & Polish (1:20 - 1:30)
- **Visual:** Resize the browser window or demonstrate desktop shortcuts (`L` to log, `N` for new racquet, `Esc` to dismiss). Hover mouse over cards to show the electric volt glow and subtle elevation.
- **Presenter Spoken Narrative:**
  > "String Theory adapts effortlessly across mobile, iPad NavigationRail, and desktop 3-column grids, complete with keyboard shortcuts (`L`, `N`, `S`, `Esc`) and hover micro-interactions. Built for the Serverpod Hackathon: real backend, real domain engine, real court impact."

---

## ⌨️ Desktop Keyboard Accelerators Reference

- `L`: Opens Quick Workout Logger modal
- `N`: Opens Add Racquet modal
- `S`: Triggers simulated workout ingestion
- `Esc`: Dismisses any active modal bottom sheet or dialog

---

## 🛠️ Fallback & Troubleshooting Tips

- **If server is not running:** The app features an offline session queue and optimistic UI caching.
- **To reset demo state at any time:** Open the side drawer and tap `[⚡ Load Sample Bag]` again to restore the canonical 3-racquet baseline.
