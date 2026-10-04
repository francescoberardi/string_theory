- source_spec: `_bmad-output/implementation-artifacts/spec-1-1-anonymous-guest-authentication-token-rehydration.md`
  summary: Align multi-tenant model schemas in Story 1.2 to use UuidValue/String for userId to match Serverpod 4.0.3 AuthUser authUserId rather than legacy int.
  evidence: Serverpod 4.0.3 `serverpod_auth_idp_server` uses `UuidValue` for `session.authenticated?.authUserId` instead of legacy Serverpod 2.x `int`.

- source_spec: `_bmad-output/implementation-artifacts/spec-2-1-pure-dart-decayengine-domain-calculation-unit-tests.md`
  summary: Add a shared health-tier classification (green/amber/red) to DecayEngine so the gauge UI and server cron do not duplicate thresholds.
  evidence: Reviewer noted no tier API exists; real gap, but tiers are consumed by Story 2.2 (gauge) and not required by Story 2.1 ACs.
- source_spec: `_bmad-output/implementation-artifacts/spec-2-1-pure-dart-decayengine-domain-calculation-unit-tests.md`
  summary: Eliminate the duplicated DecayEngine between string_theory_server and string_theory_flutter via a single shared source.
  evidence: The two files are identical apart from imports, so formulas can drift; consolidating needs a new shared package, which is beyond Story 2.1's scope.
