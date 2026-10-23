<!-- bmad:context -->
<!-- Verified 2026-10-23 against 41275bf. Managed by bmad-project-context; edits inside this block are replaced on refresh. Keep anything you want preserved outside the markers. -->

## string_theory

Tennis string decay and stringbed health tracker for Android (Google Play Store) and Web (Firebase Hosting). Flutter (`^3.44.4`) + Dart (`^3.12.2`) pub workspace (`string_theory_flutter`, `string_theory_decay_engine`) backed by Firebase (Google-only Auth, Cloud Firestore, App Check, Crashlytics, Performance Monitoring, Analytics, Remote Config, Hosting). Planning and migration specs live in `_bmad-output/`.

## Policy

- Use GitHub Flow: branch from `main`, open a PR targeting `main`, keep history linear (`git pull --rebase origin main` / `git rebase main`), and never create merge commits (`--no-ff` or standard branch merges).
- Format all commit messages as Conventional Commits: `<type>(<scope>): <description>` in imperative, lowercase, no trailing period. Allowed types: `feat`, `fix`, `test`, `refactor`, `chore`, `ci`, `docs`, `perf`. Common scopes: `flutter`, `decay`, `firebase`, `auth`, `bag`, `session`, `restring`, `telemetry`, `security`, `ci`.
- Follow strict Red-Green-Refactor TDD: write failing unit, widget, or BLoC tests first (`test(...)`), write minimal implementation to pass (`feat(...)` / `fix(...)`), then refactor (`refactor(...)`).
- Never add, upgrade, or remove any package dependency in any `pubspec.yaml` without explicit prior approval from the user.
- When introducing an approved tool, SDK, or library, always check whether it provides official MCP servers or agent skills; if available, ask the user whether to install them and provide step-by-step setup instructions.
- Stay on the latest stable Flutter and Dart SDK versions unless blocked by an approved dependency that does not yet support them.
- Never commit secrets (service account JSONs, keystores, signing passwords, deploy tokens, or `.env` files holding secrets) to the repository; store them only in local untracked config and GitHub Actions secrets. Firebase client config (`firebase_options_*.dart`, `google-services.json`) and non-secret extension parameter files (`extensions/*.env`) are public identifiers protected by App Check, security rules, and API-key restrictions, and are committed.
- Never modify `string_theory_server/` or `string_theory_client/` — legacy Serverpod packages slated for removal; all backend work targets Firebase.
- Keep `README.md` accurate to what has shipped on `main` within the same story or an immediate follow-up `docs(...)` commit; never document planned or unverified behavior as working.

## Where things are

- Pure Dart composite decay calculation (70% court hours + 30% calendar shelf-life): `string_theory_decay_engine/lib/`
- Flutter app entry point and BLoC/theme wiring: `string_theory_flutter/lib/main.dart`
- Central design system and theme tokens (`CourtMidnightTheme`): `string_theory_flutter/lib/theme/court_midnight_theme.dart`
- Authoring or modifying `firestore.rules`? Delegate to the `firestore-rules-author` subagent (or follow the `firestore-rules-creation` and `firebase-security-rules-auditor` skills).
- Firebase migration intent and execution checklist: `_bmad-output/brainstorming/brainstorm-firebase-migration-and-store-launch-2026-10-23/`

## Running and verifying

- Run `flutter analyze --fatal-infos` and `dart format --set-exit-if-changed .` from the repo root before finishing changes (enforced by `.github/workflows/analyze.yml` and `.github/workflows/format.yml`).
- Run decay engine unit tests in `string_theory_decay_engine/` with `dart test`, and Flutter unit/widget/BLoC tests in `string_theory_flutter/` with `flutter test`.
- Do not run Patrol E2E tests (`test/patrol/app_patrol_test.dart`) or Serverpod backend tests in CI/local verification — both are retired for the Firebase v1 launch.
- When asked to drive the running Flutter app via MCP, connect to the Dart Tooling Daemon and use `flutter_driver`; `string_theory_flutter/lib/driver.dart` launches with `enableTextEntryEmulation: false` by default, so flip it to `true` and hot-restart only when driver text input is required.

## Conventions that differ from defaults

- Apply DRY and KISS across all layers; prefer simple, flat implementations over speculative abstractions.
- Style all UI components exclusively through `ThemeData` and `ThemeExtension`s in `string_theory_flutter/lib/theme/` — never hardcode colors, text styles, or component decorations inline inside widget files.
- Authentication is Google Sign-In only via Firebase Auth; never implement email/password auth or unauthenticated local/guest mode.
- Firestore data is strictly multi-tenant under `/users/{uid}/**`: embed the active `currentStringJob` and the `pastStringJobs` history array inside each `Racquet` document (no separate `RestringEvent` model), keep `SessionLog` in `/users/{uid}/sessions/{sessionId}`, and use a single Firestore `WriteBatch` when logging a session to create the session document and increment the racquet's `hoursPlayed` atomically.
- Compute live string health scores client-side on read using `DecayEngine` + Firestore `.snapshots()` — do not add scheduled Cloud Functions or server cron jobs for decay calculation.

## Known pitfalls

- On macOS sandboxed agent sessions, `uv` is blocked by sandbox permissions; run workspace Python scripts (`_bmad/scripts/*.py`, skill scripts) with `python3` directly.

<!-- /bmad:context -->
