# String Theory 🎾

**Know when your strings are dead before your elbow does.**

String Theory is a virtual gear bag for tennis players. It tracks how much life is left in the strings of every racquet you own and tells you when to restring. It is built with **Flutter** (mobile, tablet, web, desktop) and **Serverpod 4** for the Serverpod Hackathon, *"Build Something Real"*.

---

## The problem

Co-polyester ("co-poly") strings, the most popular string type among club and competitive players, lose elasticity and tension quickly. Two things wear them out:

- **Court impact hours**: every hour of hitting stretches and notches the strings.
- **Calendar relaxation**: strings lose tension in the bag even when the racquet is never used.

A dead stringbed looks exactly like a fresh one. It loses its pocketing and shock absorption, so more of the impact vibration goes into the player's forearm. That is a known contributor to lateral epicondylitis ("tennis elbow"). Most players have no idea how old their string job is, never mind how worn out it is.

## Who it's for

- **Club and competitive players** who play several times a week, often with two or three racquets, and use co-poly strings.
- **Players coming back from, or trying to avoid, arm injuries**, who need to know when a stringbed has become harsh.
- **Anyone who has asked "when did I last restring this?"**

## What it does

| Feature | What you get |
|---|---|
| 🔐 **Email or guest sign-in** | Sign in or sign up with an email and password (with a verification code), or tap **Continue as guest**. A stored session skips the sign-in screen. Sign out from Settings. |
| 🎒 **Virtual gear bag** | Add every racquet you own, with string category, tension and string date. Smart defaults per string material (co-poly, multifilament, synthetic gut, natural gut, kevlar, hybrid). |
| 💚 **Health Score (0–100%)** | Each string job gets a composite score: **70% court hours + 30% calendar shelf life**. Tiers: **Green ≥ 70%**, **Amber 40–69%**, **Red < 40%** (dead stringbed). Also shows an estimated tension loss. |
| ⌚ **Workout ingestion** | Tennis workouts from Apple Health / Health Connect show up as an "unassigned workout" banner. Assign it to a racquet in a couple of taps. On web and desktop, **🧪 Simulate Workout** creates a realistic one for you. |
| ⚡ **Real-time updates** | Logging a session, restringing, or the nightly decay job pushes the new health score to every client signed in as that user, over WebSocket streams. |
| 🔁 **"Restrung Today"** | One tap resets a racquet to a fresh 100% string job. The old job is archived to the racquet's restring timeline. |
| 📜 **Sessions history** | A dedicated screen with every logged session and its source (Apple Health, Health Connect, simulated or manual). |
| 📴 **Offline queue** | Sessions logged without a connection are queued and synced automatically when the app reconnects. |
| 🖥️ **Responsive & keyboard-friendly** | Bottom navigation on phones, NavigationRail and multi-column grid on tablet and desktop. Shortcuts: `L` log a session, `N` new racquet, `S` simulate a workout, `Esc` close a sheet. |

## How it uses Serverpod and Flutter

```
┌──────────────────────────────┐        RPC + WebSocket streams        ┌───────────────────────────────┐
│ string_theory_flutter        │ ◄───────────────────────────────────► │ string_theory_server          │
│  BLoC state, optimistic UI   │      (generated string_theory_client) │  Serverpod 4.0.3              │
│  health / simulated ingestion│                                       │  endpoints, ORM, FutureCalls  │
└──────────────┬───────────────┘                                       └───────────────┬───────────────┘
               │            string_theory_decay_engine (pure Dart, shared)             │
               └──────────────────────────────────────────────────────────────────────►┘
                                                                                       ▼
                                                                                 PostgreSQL
```

**Serverpod**
- **Endpoints**: `BagEndpoint` (racquets, string jobs, transactional restrings, restring history, demo seeding, dev time-warp), `SessionEndpoint` (idempotent session logging keyed on the external workout id, session history) and `AccountEndpoint` (the signed-in account's email).
- **ORM & migrations**: `Racquet`, `StringJob`, `SessionLog` and `RestringEvent` are `.spy.yaml` models backed by PostgreSQL tables. Every table is scoped to the signed-in user's id (native UUID), so users never see each other's data.
- **Streams**: `BagEndpoint.bagUpdates` streams `BagStreamMessage` events (`sessionLogged`, `restrung`, `decayed`) from a per-user message channel. Every open client for that user updates live.
- **Scheduled FutureCalls**: `DailyDecayFutureCall` recalculates calendar decay for all active string jobs every day. It runs in batches, under a PostgreSQL advisory lock so only one run happens at a time, and with optimistic score writes.
- **Authentication**: `serverpod_auth_idp` with JWT tokens and two identity providers, **email** (sign-up with a verification code) and **anonymous guest**. The app opens on a sign-in screen built on `EmailSignInWidget`; signing out closes the bag stream, clears the bag state and the offline queue, and returns to that screen.

**Flutter**
- **`flutter_bloc`** for state, with optimistic updates computed on the device by the same `DecayEngine` the server uses, then reconciled with the server's authoritative result.
- **`health`** package for Apple Health / Health Connect, behind a strategy interface with a simulated implementation for web, desktop and demos.
- **Patrol finders + Flutter Driver** for end-to-end tests.

**Shared domain**: `string_theory_decay_engine` is a pure Dart package with no dependencies that both apps import, so a health score is calculated exactly the same way on the device and on the server.

## Repository layout

```
string_theory_server/        Serverpod backend (endpoints, models, future calls, migrations, tests)
string_theory_client/        Generated Serverpod client — do not edit
string_theory_flutter/       Flutter app (mobile, tablet, web, desktop)
string_theory_decay_engine/  Shared pure-Dart decay & health-score engine
docs/DEMO_SCRIPT.md          90-second showcase walkthrough
```

---

## Run it locally

### Prerequisites

- **Flutter** (stable channel; CI uses 3.44.4) with the Dart SDK `^3.12.2` it bundles
- **Serverpod CLI 4.x**: `dart install serverpod_cli`
- A browser (Chrome recommended)

Docker is **not** needed: in development Serverpod starts and manages an embedded PostgreSQL itself (`database.dataPath` in `config/development.yaml`).

### Start

```bash
git clone <this-repo> string_theory
cd string_theory
flutter pub get                 # resolves the whole Dart workspace

cd string_theory_server
tool/init_passwords.sh          # creates config/passwords.yaml (gitignored) with random secrets
serverpod start
```

`tool/init_passwords.sh` writes random `development` and `test` secrets (database, service secret, email pepper and JWT keys). It never overwrites an existing `config/passwords.yaml`.

`serverpod start` boots the database, applies pending migrations, starts the API server on `http://localhost:8080`, and opens the Flutter web app in your default browser. Press `Q` in the terminal to stop.

### Run the tests

```bash
# Server: endpoint, ORM, future call and stream tests (embedded test database, no Docker)
cd string_theory_server && dart test

# Shared decay engine
cd string_theory_decay_engine && dart test

# Flutter: unit, BLoC and widget tests, plus the headless Patrol E2E suite
cd string_theory_flutter && flutter test
```

CI (`.github/workflows/`) runs analyze, format, the generator drift check, all of the above, a UUID migration check against a populated database, and a web build on every push and pull request to `main`.

## Test it (for reviewers)

The app opens on a **sign-in screen**. For a quick look, tap **Continue as guest** and follow the **[90-second demo script](docs/DEMO_SCRIPT.md)**: load the sample bag, simulate a workout, assign it, restring a dead racquet, and look at the timeline and the sessions history.

To check live sync and tenant isolation, use email accounts:

1. **Sign up.** On the sign-in screen tap **Sign up**, enter an email (any address works locally, nothing is sent) and accept the terms. In development the server logs the verification code instead of emailing it: find the line `Registration code for <email>: <CODE>` in the `serverpod start` output and enter the code, then choose a password. You land on an empty bag. Settings (gear icon) shows the account email.
2. **Same account, second window.** Open `http://localhost:8080` in a second browser window and sign in with the same email and password. In window A tap **Load Sample Bag**, then reload window B once so it shows the same racquets (adding racquets is not pushed live). Now log a session in window A (`L`, or **Log Session**): the racquet's health gauge in window B updates without a reload. Restrings and the nightly decay job are pushed the same way.
3. **Second account.** Open a **private window** (or a second browser profile) and sign up with a different email. Its bag is empty, and sessions logged in the first account never show up there.
4. **Sign out** from Settings: you return to the sign-in screen. Signing out as a guest warns you first, because a guest bag can't be reached again after sign-out.

<!-- AC-11: record here whether two tabs of the same browser profile share one identity, once observed in a running browser. -->

---

Built for the Serverpod Hackathon with Flutter, Serverpod and a slightly sore elbow.
