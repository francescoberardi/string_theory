# Sprint Change Proposal — Story 6.6: Real Email Sign-In for Multi-Window Testing

- **Date:** 2026-10-13
- **Author:** Francesco (with Developer agent, Correct Course workflow)
- **Mode:** Batch
- **Scope classification:** Moderate (new story, Epic 6 reorder, PRD/Architecture/UX amendments)
- **Status:** Approved by Francesco on 2026-10-13. Edits 4.1–4.5 applied.

---

## 1. Issue Summary

**Trigger.** Reviewers can't test String Theory's headline Serverpod feature, live WebSocket sync of health scores, the way it's best shown: one account open in two windows. Nor can they check that tenants are isolated with a second account. Every launch signs in as an anonymous guest automatically, so the app has no way to sign in as a known user. The README already promises this work as "🚧 Coming in Story 6.6", but the story doesn't exist in `epics.md` or `sprint-status.yaml`.

**Category:** a new requirement from the stakeholder (the judge demo), plus a gap where a feature only pretends to work (FR-2).

**Evidence (from the code on `main` at `c5d31b0`):**

| # | Finding | Location |
|---|---|---|
| E1 | The server already has email sign-in turned on (`ServerpodCloudEmailIdpConfig`, `EmailIdpEndpoint`). In development, verification codes are logged to the console. | `string_theory_server/lib/server.dart:21-30`, `lib/src/auth/email_idp_endpoint.dart` |
| E2 | The client signs in as a guest unconditionally at startup. There's no sign-in screen. | `string_theory_flutter/lib/client.dart:28-37`, `services/auth_service.dart:39-45` |
| E3 | "Continue with Email" and "Continue with Google" in Settings only show a "preview enabled" toast. FR-2 isn't implemented. | `string_theory_flutter/lib/screens/settings_screen.dart:71-86` |
| E4 | The Settings sign-out removes the token, but nothing sends the user to a sign-in screen afterwards. "Re-authenticate Guest" silently abandons the current bag. | `settings_screen.dart:122-200` |
| E5 | `sign_in_screen.dart` and `greetings_screen.dart` are unused Serverpod template code. | `string_theory_flutter/lib/screens/` |
| E6 | `config/passwords.yaml` is gitignored and there's no example or generator. A fresh clone can't start without hand-writing six secrets. | `.gitignore:49`, `README.md:94-97` |
| E7 | Serverpod 4.0.3 ships `AccountMerger.merge()` and `AccountMergeConfig(applicationMergeHandler:)`. The IdP accounts (anonymous, email) are moved automatically, and the app supplies a handler for its own tables. Nothing triggers a merge automatically; the app must call it. | `serverpod_auth_core_server-4.0.3/lib/src/auth_user/business/account_merger.dart`, `account_merge_config.dart` |
| E8 | `docs/DEMO_SCRIPT.md` doesn't mention the Sessions history screen (6.4) or live sync between windows (3.2 / 6.3). | `docs/DEMO_SCRIPT.md` |
| E9 | On web, `FlutterAuthSessionManager` keeps the token in browser storage, which is shared across tabs of the same browser profile. Two tabs probably share one identity; the story must verify this, not assume it. | `client.dart:29-31` |

---

## 2. Impact Analysis

### Checklist status

| Item | Status | Note |
|---|---|---|
| 1.1 Trigger story | [x] | No story found the gap during implementation. It comes from the demo need and the README's "Coming in Story 6.6" promise. |
| 1.2 Core problem | [x] | New requirement + a fake feature (FR-2). |
| 1.3 Evidence | [x] | E1–E9. |
| 2.1 Current epic (6) | [x] | Epic 6 can still be finished. Add 6.6 and schedule it before 6.5. |
| 2.2 Epic-level changes | [!] | Epic 6 description + requirement list grow (FR-2 amended, FR-20, TD-15, TD-16). |
| 2.3 Remaining epics | [x] | Only 6.5 remains. Its TD-14 rewrites `auth_service_test.dart`, which 6.6 also changes, so running 6.6 first means 6.5 builds on the final `AuthService`. |
| 2.4 Obsolete / new epics | [N/A] | None. |
| 2.5 Resequencing | [!] | 6.6 runs before 6.5. |
| 3.1 PRD | [!] | FR-2 wording (data moves to the email account's `userId`), Google deferred, new FR-20 for sign-in/sign-out. |
| 3.2 Architecture | [!] | AD-3 amended (UUID `userId` from 6.3, account-merge rule); new `GuestClaim` table and `AccountEndpoint`. |
| 3.3 UX | [!] | Sitemap: sign-in screen added; Settings link entry is email only. |
| 3.4 Other artifacts | [!] | README, DEMO_SCRIPT, the Patrol E2E test and the widget/auth tests that assume an automatic guest; the new passwords bootstrap script. CI env vars stay as they are. |
| 4.1 Direct adjustment | Viable | Effort Medium-High, risk Medium. |
| 4.2 Rollback | Not viable | Nothing to revert. |
| 4.3 MVP review | Not viable | The MVP grows slightly (FR-2 becomes real). Only Google linking is cut. |

### Epic impact
- **Epic 6** gains Story 6.6 (new), scheduled before 6.5. The epic stays `in-progress`.

### Story impact
- **6.5**: no AC change. It now depends on 6.6 (it builds on 6.6's `AuthService` and test fakes).
- Done stories (1.1, 5.3, 5.4) are historical records and stay unedited. Their behavior (automatic guest at launch) is replaced by 6.6.

### Technical impact
- **Server:** new `GuestClaim` table (migration), new `AccountEndpoint` (`createGuestClaim`, `claimGuestBag`), an `AccountMergeConfig` with the app's merge handler in `initializeAuthServices`.
- **Flutter:** auth gate in `main.dart`, a new sign-in screen (built on the template), changes to `AuthService` and Settings, and the template screens removed.
- **Tests:** the Patrol E2E suite, `widget_test.dart`, `settings_screen_test.dart` and `auth_service_test.dart` currently assume an automatic guest and must tap "Continue as guest" instead.
- **Tooling:** `string_theory_server/tool/init_passwords.sh`.

---

## 3. Recommended Approach

**Direct Adjustment:** add Story 6.6 to Epic 6, before 6.5.

**Decisions taken in this session:**
1. **Guest → email is true linking.** The guest's bag moves to the email account, using Serverpod's `AccountMerger` with an app-supplied `applicationMergeHandler`.
2. **Google button removed.** Google linking is deferred to post-hackathon. No fake buttons ship.
3. **A fresh launch shows the sign-in screen** (email + "Continue as guest"), which matches PRD UJ-2. A stored session still skips it, so NFR-3 cold start holds for returning users.

**Linking design (summary):**
- While still signed in as the guest, the client calls `AccountEndpoint.createGuestClaim()`. The server stores a hashed one-time secret bound to the guest's `authUserId`, valid for 15 minutes, and returns the plain secret.
- The user then signs up or signs in with email (Serverpod `EmailIdp` flow, verification code from the server log in development).
- Now authenticated as the email user, the client calls `claimGuestBag(secret)`. The server checks the secret, its expiry and that the bound user is anonymous-only. In one transaction it runs `AccountMerger.merge(userToKeepId: emailUser, userToRemoveId: guest)`. The merge handler moves `Racquet`, `StringJob`, `SessionLog` and `RestringEvent` rows to the email user. It drops guest `SessionLog` rows that would break the `(userId, externalWorkoutId)` unique index. If the email account already has a primary racquet, it clears `isPrimary` on the guest's racquets. Finally it deletes the claim and publishes a `BagStreamMessage` to the email user's channel.
- The proof is needed because once the client switches identity, the server can no longer see that the caller used to be the guest. The secret proves it without trusting a client-supplied user id.

**Why this approach:** the server already supports email sign-in (E1) and Serverpod already supports merging (E7). The new code is one table, one endpoint, one merge handler and the Flutter wiring. It makes FR-2 real instead of cutting it, and it enables the two-window demo, the strongest showcase of FR-14.

**Effort:** Medium-High. 6.6 is the largest Epic 6 story.
**Risk:** Medium. The merge runs in one transaction and is covered by endpoint tests. The main risk is the trunk-based "< 1 day branch" rule. **Mitigation:** build the linking ACs (AC-6 to AC-8) last, in their own commits. If the story runs over a day, split them off as Story 6.7 without touching the rest.
**Timeline:** pushes 6.5 back by about one story.

---

## 4. Detailed Change Proposals

### 4.1 Epics — `_bmad-output/planning-artifacts/epics.md`

**Section: Requirements Inventory → Functional Requirements**

OLD:
```
- **FR-2**: The user can at any time link an email/password or Google identity to their guest account from the Settings screen without losing data.
```
NEW:
```
- **FR-2**: The user can at any time link an email/password identity to their guest account from the Settings screen without losing data: the guest's racquets, string jobs, sessions and restring history move to the email account. (Google linking deferred to post-hackathon.)
- **FR-20**: On launch without a stored session, the app shows a sign-in screen offering email/password sign-in or sign-up and a "Continue as guest" action; a signed-in user can sign out from Settings and returns to the sign-in screen.
```
Rationale: FR-2 matches the merge design and the decision to drop Google. FR-20 covers the new sign-in and sign-out flow.

**Section: Technical Debt & Production Hardening Requirements** (append)

NEW:
```
- **TD-15**: A fresh clone can create `string_theory_server/config/passwords.yaml` with one documented command that generates random development and test secrets and never overwrites an existing file.
- **TD-16**: Multi-window session behavior on web is verified and documented: whether two tabs of one browser profile share an identity, and how a reviewer opens a second, independent account.
```

**Section: FR Coverage Map**

OLD:
```
- **FR-2**: Epic 1 — Account Linking / Upgrade (link email or Google identity)
...
- **TD-1 through TD-14**: Epic 6 — Technical Debt, Concurrency & Production Polish
```
NEW:
```
- **FR-2**: Epic 1 (stub) & Epic 6 — Account Linking / Upgrade (link email identity, guest data merged)
...
- **FR-20**: Epic 6 — Email sign-in screen, Continue as guest, real sign-out
- **TD-1 through TD-16**: Epic 6 — Technical Debt, Concurrency & Production Polish
```

**Section: Epic List → Epic 6 and the Epic 6 header paragraph**

OLD (end of description):
```
... delivers a dedicated Sessions history screen, and establishes CI parity and deterministic authentication tests.
**Requirements covered:** TD-1, ..., TD-14
```
NEW:
```
... delivers a dedicated Sessions history screen, adds real email sign-in with guest-account linking so the app can be tested across windows and accounts, and establishes CI parity and deterministic authentication tests.
**Requirements covered:** FR-2, FR-20, TD-1, ..., TD-16
```

**Section: Epic 6 → insert new story between 6.4 and 6.5**

The story keeps the ID 6.6 (the README already uses it) and is placed before 6.5 in the file and in the sprint order.

```markdown
### Story 6.6: Real Email Sign-In for Multi-Window Testing

As a hackathon judge and tennis player,
I want to sign in with an email account (or continue as a guest), link my guest bag to an email later, and sign out for real,
So that I can open the same account in two windows and watch health scores sync live, and confirm a second account gets its own empty bag.

**Requirements Covered:** FR-2, FR-20, TD-15, TD-16

**Acceptance Criteria:**

*Sign-in screen & auth gate*
- **AC-1** — **Given** no stored session, **When** the app launches, **Then** it shows a sign-in screen in the Court Midnight theme with email/password sign-in and sign-up (Serverpod `EmailIdp` flow, including the verification-code step) and a prominent `[Continue as guest]` action; the bag is not shown until the user is authenticated.
- **AC-2** — **Given** a stored valid session, **When** the app launches, **Then** the sign-in screen is skipped and the Virtual Bag opens directly (NFR-3 unchanged).
- **AC-3** — **Given** `[Continue as guest]`, **When** tapped, **Then** an anonymous session is created exactly once (existing in-flight dedupe kept) and the bag opens; offline failure shows a retry message on the sign-in screen instead of the old post-launch SnackBar.
- **AC-4** — **Given** a fresh email sign-up, **When** the account is created, **Then** the user lands on an empty bag (no racquets from any other tenant).

*Sign-out*
- **AC-5** — **Given** any signed-in user (guest or email), **When** they confirm Sign Out in Settings, **Then** the device token is removed, the bag stream subscription is closed, the BagBloc state is cleared, and the app returns to the sign-in screen. The guest sign-out dialog warns that the guest bag becomes unreachable unless linked first. The "Re-authenticate Guest" action is removed.

*Guest → email linking (FR-2)*
- **AC-6** — **Given** a guest with a bag, **When** they tap `[Continue with Email]` in Settings and complete email sign-up or sign-in, **Then** the guest's `Racquet`, `StringJob`, `SessionLog` and `RestringEvent` rows are owned by the email account, and the bag shows the same racquets and health scores as before. Racquet IDs are unchanged, so queued offline sessions still apply.
- **AC-7** — **Given** the server, **When** linking runs, **Then** it goes through `AccountEndpoint.createGuestClaim()` (while authenticated as the guest) and `AccountEndpoint.claimGuestBag(secret)` (as the email user). Serverpod's `AccountMerger.merge` runs inside one transaction with an `applicationMergeHandler` registered in `initializeAuthServices`. The claim secret is single-use, stored hashed, expires after 15 minutes, and is valid only if its user is still anonymous-only. Reused, expired, foreign or unauthenticated claims are rejected with no rows changed.
- **AC-8** — **Given** the email account already has racquets, **When** a guest bag is merged in, **Then** guest racquets are appended, the email account's primary racquet is kept (guest `isPrimary` cleared), guest `SessionLog` rows conflicting on `(userId, externalWorkoutId)` are dropped, and a `BagStreamMessage` is published to the email user's channel so other open windows refresh.
- **AC-9** — **Given** Settings, **When** rendered, **Then** the "Continue with Google" option is gone; for an email user, Settings shows the account email instead of the guest banner and link option.

*Fresh-clone setup*
- **AC-10** — **Given** a fresh clone, **When** the developer runs `string_theory_server/tool/init_passwords.sh`, **Then** `config/passwords.yaml` is created with random `development` and `test` values for every key `server.dart` and `config/test.yaml` need (`database`, `serviceSecret`, `emailSecretHashPepper`, `jwtHmacSha512PrivateKey`, `jwtRefreshTokenHashPepper`), it refuses to overwrite an existing file, and `serverpod start` then boots. CI env vars in `tests.yml` are unchanged.

*Multi-window behavior*
- **AC-11** — **Given** web, **When** the app is opened in two tabs of the same browser profile, **Then** the story records (by running it, not assuming it) whether the tabs share one identity. If they do, signing out in one tab sends the other to the sign-in screen on its next authenticated call (401 path from 6.1), never to the offline queue. The README states the result and tells reviewers to use a private window or second browser profile for the second account.
- **AC-12** — **Given** one email account open in two windows, **When** a session is logged in window A, **Then** window B's gauge updates live without reload; **And** a second email account in a separate profile sees an empty bag and receives no updates from the first.

*Cleanup*
- **AC-13** — The unused template screens `sign_in_screen.dart` and `greetings_screen.dart` are replaced by the new sign-in screen or deleted. No dead auth UI remains.

**Tests (TDD, red first):**
- Server (`dart test`): `AccountEndpoint` tests for successful merge of all four tables, single use, expiry, foreign or non-anonymous claim rejection, unauthenticated rejection, unique-index conflict drop, primary-racquet conflict, `BagStreamMessage` published to the keeper's channel only, and rollback leaving rows untouched on failure.
- Flutter unit/BLoC: `AuthService` (no automatic guest at `initialize`, `continueAsGuest`, `signOut` clears state, the linking sequence calls claim before and after the identity switch), and clearing BagBloc on sign-out.
- Flutter widget: auth gate (no token → sign-in screen, token → bag), sign-in screen guest path and email path entry, Settings (no Google option, email button starts the linking flow, the email user sees their email).
- Patrol E2E: update the existing suite to tap `[Continue as guest]`; add a guest → email linking happy path if the embedded server setup allows it, otherwise cover it with widget tests and note why.

**Definition of Done:**
- All ACs met, all tests green locally and in CI, `dart analyze` and `dart format` clean, migration created and applied through MCP.
- **README "Test it (for reviewers)"** rewritten from what shipped (the "🚧 Coming in Story 6.6" note removed). It covers: (1) sign up with an email and get the verification code from the `serverpod start` output; (2) open the same account in a second window and watch a logged session update both; (3) sign in with a second email in a private window or second profile and confirm the bag is empty; (4) the AC-11 tab-sharing result.
- **README "Start"** replaces the hand-written passwords note with `tool/init_passwords.sh`.
- **DEMO_SCRIPT refresh:** Step 1 shows the sign-in screen and `[Continue as guest]`; a Sessions history beat is added (Story 6.4); a live two-window sync beat is added (Stories 3.2 and 6.3); timings still fit about 90 seconds or the header is honestly updated.
- README and DEMO_SCRIPT checked and updated where affected, describing only behavior verified on `main`.
```

### 4.2 PRD — `prds/prd-string_theory-2026-10-02/prd.md`

**§4.1 FR-2**

OLD:
```
* **FR-2: Account Linking (Upgrade)**
  The user can at any time link an email/password or Google identity to their guest account from the Settings screen.
  *Consequences (testable):* Upon linking, existing Racquets and SessionLogs remain attached to the same `userId` in PostgreSQL.
```
NEW:
```
* **FR-2: Account Linking (Upgrade)**
  The user can at any time link an email/password identity to their guest account from the Settings screen. (Google linking deferred to v1.1.)
  *Consequences (testable):* Upon linking, the guest's Racquets, StringJobs, SessionLogs and RestringEvents are reassigned to the email account's `userId` in a single transaction; the bag shows the same racquets and health scores.
```
Rationale: Serverpod's email sign-up always creates a new auth user, so the guest's data moves to it. "Same `userId`" can't hold; "same data" can.

**§4.1, add after FR-3**
```
* **FR-20: Sign-In Screen & Sign-Out**
  Without a stored session, the app opens on a sign-in screen offering email/password sign-in or sign-up and `[Continue as Guest]`. Signing out from Settings returns to that screen.
  *Consequences (testable):* Two windows signed into the same email account share one bag and receive live updates; a second email account starts with an empty bag.
```

**§ Scope table, Auth row**

OLD: `| **Auth** | Serverpod Anonymous Guest + Email/Google linking | Apple Sign-In on Web, Enterprise SSO |`
NEW: `| **Auth** | Serverpod Anonymous Guest + Email sign-in & guest→email linking | Google linking, Apple Sign-In on Web, Enterprise SSO |`

### 4.3 Architecture — `ARCHITECTURE-SPINE.md`, AD-3

OLD:
```
* **Binds:** `FR-1`, `FR-2`, `NFR-8`, `NFR-9`
* **Rule:** All database tables (`Racquet`, `StringJob`, `SessionLog`, `RestringEvent`) must include an indexed `userId: int` column. Serverpod endpoints must strictly filter by `session.authenticated.userId` on every operation without relying on indirect joins.
```
NEW:
```
* **Binds:** `FR-1`, `FR-2`, `FR-20`, `NFR-8`, `NFR-9`
* **Rule:** All database tables (`Racquet`, `StringJob`, `SessionLog`, `RestringEvent`) must include an indexed `userId: UuidValue` column (since Story 6.3). Serverpod endpoints must strictly filter by `session.authenticated.authUserId` on every operation without relying on indirect joins.
* **Ownership transfer:** The only path that changes a row's `userId` is guest→email linking: `AccountEndpoint.claimGuestBag` verifies a hashed, single-use, 15-minute `GuestClaim` bound to an anonymous-only user, then calls Serverpod `AccountMerger.merge` inside one transaction; the app's `applicationMergeHandler` (registered via `AccountMergeConfig` in `initializeAuthServices`) reassigns the four tables, resolving `(userId, externalWorkoutId)` and primary-racquet conflicts in favour of the kept account.
```
Rationale: AD-3 still says `int` (out of date since 6.3), and it needs the single sanctioned way to transfer ownership.

### 4.4 UX — `EXPERIENCE.md`, sitemap

OLD:
```
└── ⚙️ Settings & Account
    ├── Anonymous Guest Account Banner -> [Link Google / Email]
```
NEW (add a top-level entry before the bag, and change the Settings line):
```
├── 🔑 Sign-In Screen (no stored session)
│   ├── Email Sign-In / Sign-Up (verification code)
│   └── [Continue as Guest]
...
└── ⚙️ Settings & Account
    ├── Guest: Account Banner -> [Continue with Email] (links & keeps bag) · Email user: account email
    ├── [Sign Out] -> Sign-In Screen
```

### 4.5 Sprint status — `implementation-artifacts/sprint-status.yaml`

OLD:
```
  6-4-dedicated-sessions-history-screen-domain-model-extraction: done
  6-5-ci-environment-parity-deterministic-auth-testing: backlog
```
NEW:
```
  6-4-dedicated-sessions-history-screen-domain-model-extraction: done
  6-6-real-email-sign-in-multi-window-testing: backlog
  6-5-ci-environment-parity-deterministic-auth-testing: backlog
```
Rationale: the order in the file is the sprint order, so 6.6 runs first. Epic 6 stays `in-progress`.

### 4.6 README / DEMO_SCRIPT
No edits now. Per Living Docs, they describe only what has shipped, so they're updated in Story 6.6's Definition of Done (see 4.1).

---

## 5. Implementation Handoff

**Scope:** Moderate. It reorganizes the backlog and amends the planning docs, then hands the story to a developer.

| Role | Responsibility |
|---|---|
| Developer agent (this session, on approval) | Apply edits 4.1–4.5 to the planning artifacts and commit as `docs(planning): add story 6.6 email sign-in and guest linking`. |
| Developer agent (`bmad-build`) | Create `spec-6-6-...md` from the story, implement it TDD-first, linking ACs last (split to 6.7 if the story runs over a day), and update the README and DEMO_SCRIPT per the DoD. |
| Francesco | Run `serverpod start`; manually check AC-11 and AC-12 in two windows and a private window. |

**Success criteria:**
- A reviewer on a fresh clone runs one setup command, signs up with email, sees live sync across two windows, and sees an empty bag on a second account.
- A guest who links to email keeps every racquet and health score.
- No fake auth buttons remain. CI is green. The README and DEMO_SCRIPT match `main`.
