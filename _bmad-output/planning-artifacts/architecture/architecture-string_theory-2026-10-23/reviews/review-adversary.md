---
lens: adversary
target: ../ARCHITECTURE-SPINE.md
rationale: ../.memlog.md
date: 2026-10-23
verdict: not build-ready — the shape is sound, but 4 high-severity holes let independent stories obey every AD and still ship code that loses or hides user data offline
---

# Adversarial Review: String Theory v1 (Firebase) Architecture Spine

## Verdict

The paradigm and most ADs are sound, and the obvious traps are already closed: no `serverTimestamp` inside arrays, no transactions, `stringJobId` on sessions, and conflict-tolerant primary resolution. The holes are in the seams the spine leaves open: (a) what a pending local write looks like to a mapper, (b) when a mutation counts as "done" while offline, (c) how a single-table schema becomes per-mutation rules, (d) how Android builds pick a Firebase project, and (e) who owns cross-BLoC concerns (listener teardown, telemetry, derived racquet state). Every finding below is a pair of units that each follow every AD to the letter and still build things that don't fit together.

Severity scale: **High** means silent data loss/hiding, a crash, or a blocked core flow in a normal scenario. **Medium** means wrong data or broken UX in a plausible scenario. **Low** means an edge case or a consistency risk.

---

## Findings: incompatible pairs

### F1 — Pending server timestamps vs required `createdAt` / `updatedAt` [HIGH]

- **Unit A (bag / add-racquet story):** follows the Time convention ("Server timestamps are used only for top-level createdAt/updatedAt") and writes `createdAt: FieldValue.serverTimestamp()`, `updatedAt: FieldValue.serverTimestamp()`.
- **Unit B (racquet mapper story):** follows AD-3, where `createdAt` and `updatedAt` are both **required** `timestamp`, so a missing or `null` value is a decode failure. AD-4 sets the decode-failure policy: report and "leave that racquet out of the stream".
- **Clash:** with latency compensation, the local snapshot of a pending write returns `null` for every unresolved server timestamp. The new racquet's first snapshot fails to decode, so the racquet is **hidden**. Offline it stays hidden until sync, which breaks FR-5 ("appears immediately") and NFR-4. Every `logSession`, `restring` and `updateRacquet` also re-pends `updatedAt`, so racquets that already exist **flicker out of the bag** on every offline mutation. AD-8's comparator ("earliest `createdAt`") either throws or misorders on `null`. Sessions have the same problem with `createdAt` (server), and so does the user doc.
- **Fix (tighten AD-3 + Time convention):** "Fields written with `serverTimestamp()` are *pending-nullable on read*. Mappers decode a `null` server-timestamp field as the estimated local time: use the SDK's `ServerTimestampBehavior.estimate` where the FlutterFire API exposes it on the read path, otherwise substitute `clock.now()`. That is never a decode failure. Domain `createdAt` and `updatedAt` are non-null. AD-8 orders ties and estimates by document id after `createdAt`." Add a repository test: add a racquet offline in `fake_cloud_firestore` (or the emulator, with the network disabled) and expect it in the stream at once.

### F2 — "Done" means local enqueue or server ack? Offline mutations hang or vanish [HIGH]

- **Unit A (repository author):** implements AD-5 literally, `Future<void> logSession(...) => batch.commit();`, and maps `FirebaseException` to typed failures (Errors convention).
- **Unit B (session_log / restring / bag BLoC author):** `await repo.logSession(...)`, then emits `success`, closes the sheet and fires `session_logged` (Telemetry convention). Errors go to `failure`.
- **Clash:** on Android, `commit()` / `update()` futures **do not resolve while offline**. They resolve only when the server acknowledges. Offline, the logger sheet spins forever, analytics never fire, and SM-1 (logging in ≤10 s) fails exactly where NFR-4 says logging must still work. A second developer who avoids this with `unawaited(...)` loses every error path. When the queued write is **later rejected by rules** at sync (see F3 for writes that pass the client but fail rules), the SDK quietly rolls the local cache back. The racquet's hours drop, or the restring reverts, and no one is told, because the BLoC that made the call may be closed. AD-5's stated aim ("offline writes that can never commit") is met only for transactions.
- **Fix (new AD-5b, "Mutation completion semantics"):** "Repository mutation methods complete when the write is accepted into the local cache, not when the server acknowledges it. They start `commit()` without awaiting it and attach a single error sink: the repository reports late server rejections to Crashlytics (see F7) and exposes them on a `Stream<MutationFailure>` that the bag screen surfaces as a snackbar. BLoCs emit success and fire analytics on local acceptance. Every AD-3 bound lives in one `lib/domain/schema_bounds.dart`, which domain constructors and form validators enforce before any write. A rules rejection therefore means a bug, never a user typo." Pending state for any 'saving offline' UI comes from `SnapshotMetadata.hasPendingWrites`, mapped onto the domain model as `bool isPendingSync` (AD-2 forbids exposing the Firestore type).

### F3 — One schema table cannot be implemented as rules for four update shapes [HIGH]

AD-3 says mappers and rules "both implement exactly this table". But rules see **diffs per mutation**, and AD-5 has four different racquet update shapes. Each pair below obeys AD-3 and AD-5 and still fails:

| Pair | Unit A (repository, per AD-5) | Unit B (rules author, per AD-3) | Result |
| --- | --- | --- | --- |
| a | `setPrimary` batch writes only `isPrimary` (AD-5 lists no `updatedAt` for it) | "`updatedAt` timestamp (server) ✓", enforced as `request.resource.data.updatedAt == request.time` on every update | The entire setPrimary batch is rejected (offline: silently, see F2) |
| b | `setPrimary` batch `update`s "every other racquet", read from cache; one was deleted on another device | n/a (Firestore semantics) | `update` on a missing doc returns NOT_FOUND, so the **whole batch** fails. The same applies to `logSession` against a racquet deleted elsewhere: the session is lost too |
| c | `restring` arrayUnion's the 101st archived job | `pastStringJobs` "list ≤100" → `size() <= 100` | Restring rejected forever for that racquet. arrayUnion and arrayRemove can't touch one field in one update, so the AD-5 shape has no way to trim |
| d | `restring` appends a StringJob map | "StringJob map ≤10 keys, bounds…" applies to list elements | Rules **cannot loop over list elements**. Author B1 validates only `is list`, which leaves an NFR-7 abuse hole (500 KB brand strings in history). Author B2 tries a fixed-index check and rejects the first restring because `pastStringJobs` is *absent* when empty (AD-3 "left out when empty") |
| e | `restring` sets archived `endedAt = Timestamp.now()` (client clock, AD-3) | sanity rule `endedAt <= request.time` | A device whose clock runs a few seconds fast has every restring rejected |
| f | `updateRacquet` clears notes by writing `notes: ''` or `null` | `notes` string ≤500, never null; "left out when empty" | `null` is rejected. `''` passes the rules but breaks the "left out" contract the mappers rely on |

(Probes that **held**: `FieldValue.increment` passes a whole-document `request.resource` check, because rules see the post-increment value. `arrayUnion` of a map never dedupes wrongly, because each archived job carries a unique `id` and `endedAt`.)

- **Fix (tighten AD-3 into a per-mutation rule matrix, and amend AD-5):**
  - "`firestore.rules` validates each racquet `update` as exactly one AD-5 shape, matched on `request.resource.data.diff(resource.data).affectedKeys()`. Every shape, `setPrimary` included, writes `updatedAt` and is checked with `== request.time`."
  - "`pastStringJobs` is append-only. A restring rule reads `old = resource.data.get('pastStringJobs', [])`, requires `new.size() == old.size() + 1`, validates only `new[old.size()]` against the StringJob table, and requires that element's `id` to equal `resource.data.currentStringJob.id`." Decide what happens at the cap: either drop the 100 cap (a racquet doc with 1,000 jobs is still well under 1 MiB), or define a second shape that rewrites the whole trimmed array. The cap and the arrayUnion shape can't both stay as written.
  - "Rules never compare client-clock fields (`strungAt`, `endedAt`, `playedAt`) to `request.time`."
  - "Clearing an optional field uses `FieldValue.delete()`."
  - "`setPrimary` writes only the target racquet and the racquets currently flagged `true`, not every racquet. AD-8 already tolerates leftovers."
  - Add one rules test per AD-5 shape, plus a negative test per shape.

### F4 — `--dart-define=FLAVOR` vs Android's per-project native config [HIGH for dev workflow, MEDIUM for prod risk]

- **Unit A (bootstrap story):** follows AD-12, `Firebase.initializeApp(options: FLAVOR == 'dev' ? DevOptions : ProdOptions)`, and commits one `android/app/google-services.json` (AD-12 names it in the singular).
- **Unit B (auth story):** follows AD-9 and calls `GoogleSignIn.instance.initialize()` with no `serverClientId`. That is the documented default, and on Android it reads `default_web_client_id` from the **google-services.json resources**, which a dart-define cannot switch.
- **Clash:** the dev build gets an ID token whose audience belongs to the *other* project, so `signInWithCredential` against the dev project fails with invalid credential/audience. Every developer's Android dev sign-in is broken, or it works only because both point at prod (the "testing against real user data" AD-12 is meant to prevent). Play Integrity (App Check), Crashlytics mapping upload and OAuth SHA-1 registration are also tied to the native package/project, not the Dart options. A third ambiguity: what does a bare `flutter run` with no define use? A `String.fromEnvironment('FLAVOR')` that defaults to `prod` sends debug builds into enforced-App-Check prod.
- **Fix (tighten AD-12):** "Android uses Gradle `productFlavors` `dev` (`applicationIdSuffix ".dev"`) and `prod`, with `android/app/src/{dev,prod}/google-services.json`. Builds are `flutter build|run --flavor X --dart-define=FLAVOR=X` (or `--dart-define-from-file=env/X.json`). `main()` fails fast if `FLAVOR` is missing, or on Android if it differs from Flutter's `appFlavor`. There is no default flavor. `AuthRepository` passes `serverClientId` explicitly from the selected flavor's config. Each project registers the debug and release SHA-1/SHA-256 for its own application id." The Deploy convention also needs `.firebaserc` aliases matching the flavor names.

### F5 — Account deletion and sign-out: nobody can cancel other BLoCs' listeners [MEDIUM-HIGH]

- **Unit A (settings / auth story):** follows AD-10, "client cancels every Firestore subscription and then calls `currentUser.delete()`". It can't reach them: the BLoC-state convention says "No BLoC reads or changes another BLoC's state", and each BLoC "subscribes to repository streams itself". The only global lever is `FirebaseFirestore.instance.terminate()` (+ `clearPersistence()`, which FR-3 "clears local memory caches" seems to invite).
- **Unit B (bag / session_log story):** keeps its subscription for the BLoC's lifetime, which is correct under the BLoC convention.
- **Clashes:**
  1. If A cancels and deletion then fails (`requires-recent-login`, and the user dismisses the re-auth popup), B's BLoCs are left subscribed to dead streams and the bag freezes while the user is still signed in. If A uses `terminate()`, every later Firestore call throws.
  2. Sign-out with `clearPersistence()` while offline **destroys queued sessions** (NFR-4). Without it, FR-3's "clears caches" is unmet. The two stories will each pick one.
  3. **Multi-device resurrection:** after `delete()`, a second signed-in device keeps a valid ID token for up to about 1 h, and rules don't check revocation. Its queued or live writes recreate `/users/{uid}/racquets/...` *after* the extension's recursive purge, so personal data outlives the deletion (NFR-8 / GDPR).
- **Fix (tighten AD-10, and add a line to the BLoC-state convention):** "Repositories expose streams scoped to an `AuthSession`. Every repository stream completes, without error, when the auth uid changes or becomes null (`authStateChanges` drives a `takeUntil`). BLoCs never cancel anything themselves. Deletion: call `delete()` first. Repository streams end when auth state goes null, and permission-denied errors that arrive after the uid changes are dropped at the repository, so they are never reported. Sign-out never calls `clearPersistence()` while `hasPendingWrites`. FR-3's 'clear caches' means in-memory BLoC state only. Rules allow writes under `/users/{uid}/**` only while `exists(/users/{uid})`. This blocks writes after the purge, and it requires the user doc from F8 to exist before the auth gate opens."

### F6 — Restring "Keep Same" vs "Change Strings": who owns `maxHours`, `endReason`, the brand string and the new date [MEDIUM]

- **Unit A (add-racquet form, bag epic):** FR-5 makes Max Hours optional and "pre-filled with category defaults". AD-4 says defaults come "from `string_theory_decay_engine` only". But per the AD-1 layer table, **UI may not import the engine**, so A either breaks AD-1 (as the current `restring_sheet.dart` does with `StringCategoryDefaults`) or leaves `maxHours` null and expects someone downstream to fill it.
- **Unit B (restring sheet, restring epic):** fills the default in the BLoC, and **re-applies** it when the material changes, overwriting a custom value (or doesn't, depending on the developer).
- **Unit C (mapper):** AD-3 requires `maxHours`. The data layer's import list excludes the engine, so the mapper can't fill a default either. A null reaching the mapper is a crash or a decode failure.
- **Same-shaped gaps in the restring flow:**
  - `endReason`: FR-16 makes it "user-selected", while FR-15 makes Keep Same "1-tap". One story adds a reason picker, which breaks 1-tap. Another hard-codes `manual_restring`, which makes String Lab's dead/broken data meaningless.
  - Brand: AD-3 merges "brand + model in one string ≤80", but the existing sheet has separate brand and model fields. A developer who validates each field at ≤80 and concatenates can produce 161 chars, which the rules reject offline without telling anyone (F2/F3).
  - New `strungAt`: Keep Same uses `clock.now()` (an instant). Change Strings uses a date picker, which gives local or UTC midnight. The same action yields health that differs by up to a day's calendar penalty, and timeline dates are off by one in negative UTC offsets.
- **Fix (new AD-14, "String job construction"):** "`StringJob.maxHours` is non-null in the domain. `lib/domain/string_material.dart` re-exports `defaultMaxHours` and `shelfLifeDays` from the engine. This is the only lookup, and UI and BLoCs read it through the domain. Forms prefill `maxHours` from it, and changing the material re-prefills only if the user hasn't edited the field. Keep Same copies `material`, `brand`, `tensionLbs` and `maxHours` verbatim, sets `strungAt = clock.now()` and `endReason = manual_restring`. Change Strings defaults `endReason` to `manual_restring`, shows an optional dead/broken choice, and the picked date is stored as that local date at 12:00 local converted to UTC. The UI has one brand/model text field, validated against `schema_bounds.brandMax`."

### F7 — AD-4 makes the data layer report to Crashlytics, but AD-1 forbids it [MEDIUM]

- **Unit A (mapper story):** AD-4 requires an unknown material to be reported "to Crashlytics" with the racquet left out of the stream. But `lib/data` may import only domain + Firebase data SDKs, and telemetry is "accessed only through `lib/services/` wrappers" reachable from BLoCs (AD-1 diagram).
- **Unit B (bag BLoC):** the racquet was dropped before it got to the BLoC, so the BLoC can't report it. The BLoC does report every failure state it receives.
- **Clash:** one developer injects the Crashlytics service into the repository, which breaks the import rule. Another skips the report, which breaks AD-4. Meanwhile BLoC-side reporting of permission-denied errors contradicts AD-10. Analytics `sign_in` has the same split: AuthRepository knows `isNewUser` and the BLoC doesn't.
- **Fix (tighten AD-1 and the Telemetry convention):** "`lib/domain/` defines `ErrorReporter` and `AnalyticsSink` interfaces, and `lib/services/` implements them. Repositories may depend on `ErrorReporter` and are the **only** reporters of decode failures and unexpected `FirebaseException`s (including the late write rejections from F2). BLoCs are the only callers of `AnalyticsSink` and never call `ErrorReporter`. Expected errors (permission-denied after sign-out, offline `unavailable`) are never reported."

### F8 — User-doc creation: "after first sign-in" with `merge: true` vs immutable `createdAt` [MEDIUM]

- **Unit A (AuthRepository):** "After the first successful sign-in" has no detector named, so the simplest code that follows AD-9 writes `set({email, displayName, createdAt: serverTimestamp()}, merge: true)` after *every* `signIn()`. A cold-start session restore (FR-2) never writes at all.
- **Unit B (rules author):** makes `createdAt` immutable on update, which is a normal hardening step.
- **Clash:** the second sign-in's user-doc write is rejected. If AuthRepository surfaces that as a sign-in failure, the user can't sign in again. If A instead writes only when `additionalUserInfo.isNewUser` and the app is killed between auth and the write, `/users/{uid}` **never** exists. That is harmless today but fatal once F5's `exists()` gate is adopted.
- **Fix (tighten AD-9):** "Before the route gate opens, on every auth state with a non-null user (sign-in *and* restore), `AuthRepository.ensureUserDoc()` runs: `set` with `createdAt` if the doc is absent from the cache or server, otherwise `update` of `email`/`displayName` only. Rules make `createdAt` immutable. Sign-out also calls `GoogleSignIn.instance.signOut()` on Android, so FR-3 account switching shows the picker."

### F9 — Three BLoCs subscribe to racquets and two repositories write them: derived state and field paths diverge [MEDIUM]

- **Units:** `bag` (list, health, primary badge), `session_log` (picker, primary preselection, current `stringJobId`), and `restring` (owns FR-17 detail/timeline per the capability map, so it shows a gauge too). Each "subscribes to repository streams itself". Separately, `logSession` lives in `session_repository` but writes the **racquet** doc (`currentStringJob.hoursPlayed`, `updatedAt`), while `racquet_repository` owns the racquet mapper.
- **Clashes:**
  - AD-8's primary resolution is implemented twice: bag shows a star on racquet X while the logger preselects Y (one resolves by `createdAt`, the other by list order).
  - Health is computed by two BLoCs with independent `clock.now()` and `resumed` handlers, so detail and bag screens straddle a tier boundary (69 vs 70). That is exactly the disagreement AD-7 is meant to prevent.
  - `session_repository` hard-codes `'currentStringJob.hoursPlayed'` while `racquet_repository`'s mapper renames a field: a silent increment into a dead path. AD-3's "change both in the same PR" names mappers and rules, not a second repository.
  - Repository signatures are unspecified: `logSession(racquetId, hours)` must *read* the racquet to find `stringJobId`, while `logSession(Racquet, hours)` trusts BLoC state. `restring(racquetId, …)` vs `restring(Racquet, …)` has the same split.

  (Read cost is not duplicated, because Firestore multiplexes identical queries. The risk is logic drift, not billing.)
- **Fix (new AD-15, "Racquet read model"):** "`RacquetRepository` exposes exactly `watchRacquets()` and `watchRacquet(id)`. `lib/domain/` owns the pure derivations `resolvePrimary(List<Racquet>)` and `RacquetHealth.of(StringJob, DateTime now)`, and BLoCs call these, never their own versions. Every racquet-doc field path lives in `lib/data/racquet_fields.dart`, shared by both repositories and quoted in the rules header. Mutation methods take the domain `Racquet` the user acted on (`logSession(Racquet, hours)`, `restring(Racquet, newJob, reason)`). That pins the archived job and `stringJobId` to what the user saw, and AD-6 covers the race. Lifecycle `resumed` is delivered as an event from one `AppLifecycleListener` in the app shell to every BLoC that shows health."

### F10 — int vs double on the wire [LOW-MEDIUM]

- **Unit A:** the restring writer creates the new job with `hoursPlayed: 0` and `maxHours: 20` (Dart `int` literals, stored as Firestore integers). `FieldValue.increment(1)` keeps the field an integer.
- **Unit B:** the mapper reads `data['hoursPlayed'] as double`. A rules author may also write `is float`.
- **Clash:** on Android the cast throws, so under AD-4's policy the racquet is dropped from the stream. Web hides the bug because JS numbers are untyped. Rules `is float` rejects the write.
- **Fix (AD-3 note):** "Numbers are `number` on the wire. Rules use `is number`. Writers always send `double`, mappers decode with `(v as num).toDouble()`, and the `increment` operand is always a `double`."

---

## Lower-severity notes

- **AD-6 is one-directional.** It covers a late session landing on the *new* job, but not a session committed by device B between device A's cached read and A's restring. That session's hours are in neither the archived `hoursPlayed` nor the new job. FR-17's timeline (archived `hoursPlayed`) and String Lab (`stringJobId` sums) will then disagree. State which one is canonical for display.
- **Two offline restrings of the same racquet** on two devices archive the same `id` twice with different `endedAt`, and arrayUnion doesn't dedupe them. Readers should dedupe history by `id` (keeping the latest `endedAt`), and the F3 rule (`new[old.size()].id == resource.currentStringJob.id`) rejects the second one once the first has synced.
- **AD-11 step order:** a throw in step 1 or 2 (for example, the reCAPTCHA script failing to load on web) happens before the Crashlytics hooks exist. Wrap steps 1–2 in a guarded zone, or note that it's accepted.
- **Bounds that reject real-world data in a batch:** `hoursPlayed ≤ 1000` makes the whole `logSession` batch, session included, fail at the limit. `durationHours ≤ 24` vs the addendum's `≥0.1` minimum (AD-3 says `>0`) is a third rule source. Reconcile them in `schema_bounds.dart` (F2).
- **Existing developer/judge controls** (`FastForwardRacquetAge`, `SeedSampleBag` in `settings_screen.dart`/`bag_bloc.dart`) write `strungAt` and bulk racquets. No AD-5 shape covers them, and the memlog says "no demo actions". State in the spine that they are removed, so the migration story doesn't port them as a seventh write shape.
- **Re-authentication account mismatch:** on Android the re-auth picker can return a *different* Google account (`user-mismatch`). AD-10 should define the outcome: abort deletion with a typed failure.
- **No BLoC is named** for sessions history (`sessions_screen.dart`) or for Settings/deletion. Assign them in the BLoC naming convention so two stories don't each create one.

## Summary of proposed AD changes

| ID | Change | Closes |
| --- | --- | --- |
| AD-3 (tighten) | Pending server timestamps decode as estimates; per-mutation rule matrix using `affectedKeys()`; append-only `pastStringJobs` validated by index; resolve the cap; no client-clock comparisons in rules; `FieldValue.delete()` for clearing; `number` typing | F1, F3, F10 |
| AD-5 (tighten) + new AD-5b | `setPrimary` writes `updatedAt` and touches only flagged racquets; mutations complete on local acceptance; one late-rejection sink; shared `schema_bounds.dart` | F2, F3 |
| AD-12 (tighten) | Gradle flavors + per-flavor `google-services.json` + explicit `serverClientId`; no default flavor; fail fast on mismatch | F4 |
| AD-10 (tighten) | Auth-scoped repository streams end themselves; delete first; no `clearPersistence` with pending writes; rules `exists(/users/{uid})` gate | F5 |
| new AD-14 | String job construction: `maxHours` default via domain, Keep Same / Change Strings field rules, `endReason` default, single brand field, `strungAt` precision | F6 |
| AD-1 + Telemetry (tighten) | `ErrorReporter` / `AnalyticsSink` domain interfaces; repositories own error reporting, BLoCs own analytics | F7 |
| AD-9 (tighten) | `ensureUserDoc()` on every non-null auth state before the gate; immutable `createdAt`; Google sign-out on Android | F8 |
| new AD-15 | Racquet read model: two repository streams, pure domain derivations, shared field-path constants, mutation signatures take `Racquet`, one lifecycle source | F9 |
