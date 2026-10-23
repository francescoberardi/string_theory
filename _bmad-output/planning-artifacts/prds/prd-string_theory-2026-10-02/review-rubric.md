# PRD Quality Review — String Theory (v1.0 Firebase & Store Launch)

## Overall verdict
The PRD is an exceptionally clean, well-grounded specification that decisively pivots String Theory from a Serverpod prototype to a lean, store-compliant Firebase/Flutter architecture without fluff or speculative abstraction. It provides concrete mathematical models, atomic data operations, and strict Google Play compliance boundaries; it requires only minor reconciliations around secondary metric formulas, MoSCoW requirement enumeration, and schema enum consistency before downstream story generation.

---

## Decision-readiness — Adequate

The PRD clearly articulates major structural decisions rather than burying them: moving from Serverpod to serverless Firebase, mandating Google-only authentication, dropping Health Connect/smartwatch integrations to avoid Play Store permission bottlenecks, and evaluating decay purely client-side to eliminate Cloud Function cron costs. Trade-offs are transparently acknowledged. However, all Open Questions (§9) are marked pre-emptively `[RESOLVED]`, leaving no visible open trade-offs or decision checkpoints for stakeholders, and one secondary metric calculation is left implicit.

### Findings
- **[medium]** Undefined Secondary Metric Calculations (§2.3 UJ-1, §4.3 FR-9, §9 OQ-1) — UJ-1 quotes the app displaying `"~1.4 lbs tension drop. 11 court hours remaining before dead zone"`, and OQ-1 confirms tension loss is a primary user-facing companion metric, but FR-9 only defines the formula for `HealthScore` (0–100%). The mathematical derivation for estimated tension loss (lbs) and remaining hours before reaching the 40% red threshold is never defined. *Fix:* Add explicit conversion formulas to FR-9 or define a dedicated calculation specification in the decay engine for tension loss and remaining hours.
- **[low]** All Open Questions Pre-emptively Closed (§9 OQ-1 to OQ-3) — Marking 100% of open questions as `[RESOLVED]` creates the illusion of zero unresolved tensions. Nuanced edge scenarios (e.g., offline concurrent write conflict resolution across multi-device sessions) are omitted rather than flagged for architectural decision. *Fix:* Acknowledge offline multi-device edge resolution or state the assumed "last-write-wins" Firestore batch semantics explicitly.

---

## Substance over theater — Strong

The PRD is completely free of boilerplate theater. Personas are not decorative matrix slides; they are directly integrated into operational User Journeys (Marco's 5-second log, Elena's onboarding, David's restringing reset, and the Play Store reviewer's account deletion). The Vision and JTBD are deeply grounded in real tennis equipment physics (co-poly static relaxation, ball pocketing breakdown, shock vibration transmission causing lateral epicondylitis). NFRs cite specific, verifiable numbers (60 fps, <500 ms sync latency, <1.5s cold start, schema key bounds) rather than vague adjectives.

### Findings
*No findings. This dimension is strong.*

---

## Strategic coherence — Strong

The PRD is driven by a singular, coherent thesis: recreational tennis players risk chronic arm injuries because string decay is invisible, and existing tracking methods impose too much friction. Every capability directly supports this thesis: Google-only sign-in removes onboarding drop-off; the sub-10s manual quick-logger ensures players actually log sessions post-match; the atomic `WriteBatch` keeps equipment wear synchronized; and the "Restrung Today" 1-tap reset closes the lifecycle loop. Success metrics (SM-1 logging speed, SM-5 restringing completion) and counter-metrics (SM-C1 field clutter limitation, SM-C2 zero joined reads) protect the core value proposition from feature creep.

### Findings
*No findings. This dimension is strong.*

---

## Done-ness clarity — Adequate

Functional requirements across authentication, equipment inventory, decay math, and security rules provide clear boundaries and testable consequences. Developers know exactly what data structures to create and what Firestore operations to run. However, an enumeration oversight in the MoSCoW table and slight ambiguity regarding session metadata fields leave small gaps in scope certainty.

### Findings
- **[medium]** Incomplete MoSCoW Must-Have Enumeration (§6) — The MoSCoW table's "Must Have (v1.0)" row omits `FR-7` (Racquet Editing & Deletion), `FR-8` (Primary Racquet Designation), `FR-10` (Health Status Tiers & Color Coding), and `FR-14` (Real-Time Multi-Device Sync) from its itemized list, despite all four being core v1.0 requirements in §4. Downstream story planners relying on MoSCoW could inadvertently drop or de-prioritize these features. *Fix:* Update the MoSCoW Must-Have scope cell to explicitly enumerate `FR-7`, `FR-8`, `FR-10`, and `FR-14`.
- **[low]** Session Metadata Field Scope Ambiguity (§4.4 FR-12, §6, Addendum §1.1) — Addendum §1.1 specifies `notes`, `surface`, and `location` in the Session document schema, while MoSCoW (§6) defers "Enriched SessionLog metadata (court surface, location, notes)" to v1.1 Should-Have, and FR-12 specifies only duration chips and racquet selection. It is ambiguous whether these fields should be exposed in the v1.0 UI or only supported as optional nullables in the Firestore schema. *Fix:* Clarify in FR-12 and Addendum §1.1 that while the Firestore document schema supports optional notes/surface/location, the v1.0 quick-logger UI strictly omits them to satisfy SM-C1.

---

## Scope honesty — Strong

Omissions and boundaries are exceptionally candid. Section 5 lists ten explicit non-goals, dismantling legacy Serverpod dependencies, parking smartwatch integrations, stripping demo hackathon widgets, and postponing in-app billing/ads to v1.1. The trade-offs of mandating Google Sign-In and abandoning local guest mode are faced squarely in the target user and assumptions sections.

### Findings
*No findings. This dimension is strong.*

---

## Downstream usability — Adequate

The PRD provides high downstream value for Winston (Architecture) and Amelia (Development) through clean IDs (`FR-1`–`FR-22`, `UJ-1`–`UJ-4`, `SM-1`–`SM-5`), clear data models, and an accompanying technical Addendum. However, two naming inconsistencies and missing inline assumption anchors impair mechanical traceability.

### Findings
- **[medium]** Restring Retirement Reason Enum Discrepancy (§3, §4.5 FR-16, Addendum §1.1) — In PRD §3 and FR-16, the allowed `endReason` enum values are defined as `"dead"`, `"broken"`, or `"manual_restring"`. In Addendum §1.1 (line 42), the sample JSON uses `"endReason": "restrung"`. This discrepancy will cause test failures or schema validation errors in `firestore.rules`. *Fix:* Standardize on `"manual_restring"` (or `"restrung"`) across PRD §3, FR-16, and Addendum §1.1.
- **[low]** Repository Convention Terminology Drift (§3, AGENTS.md) — The PRD (§3, FR-16) and Addendum establish `pastStringJobs` as the array field name on the `Racquet` document, whereas project rules in `AGENTS.md` refer to `stringHistory`. *Fix:* Align `AGENTS.md` to reference `pastStringJobs` to avoid confusion during code review and rules authoring.

---

## Shape fit — Strong

The PRD shape perfectly matches a brownfield mobile/web consumer product navigating a backend replatform and public store release. It eschews unnecessary enterprise ceremonies while providing deep technical specificity on Firestore data layout, atomic writes, client-side decay calculation, App Check, and Google Play compliance.

### Findings
*No findings. This dimension is strong.*

---

## Mechanical notes

- **Assumptions Index Roundtrip Failure:** Section 10 indexes 4 assumptions referencing sections (`§2.1`, `§4.3 / FR-9`, `§4.4 / FR-12`, `§4.6 / FR-19`), but none of those sections contain the corresponding inline `[ASSUMPTION: ...]` markers.
- **ID Continuity:** Contiguous and unique across all sets: FR-1 through FR-22, UJ-1 through UJ-4, SM-1 through SM-5, SM-C1 through SM-C2, NFR-1 through NFR-8, OQ-1 through OQ-3.
- **Protagonist Naming:** Consistent and contextualized protagonists across all user journeys (Marco, Elena, David, and Play Store Reviewer).
- **Cross-Reference Resolution:** All FR-to-UJ and SM-to-FR cross-references resolve cleanly, with the sole exception of the omitted IDs in the MoSCoW summary table noted under Done-ness clarity.
