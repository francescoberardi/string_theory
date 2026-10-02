- source_spec: `_bmad-output/implementation-artifacts/spec-1-1-anonymous-guest-authentication-token-rehydration.md`
  summary: Align multi-tenant model schemas in Story 1.2 to use UuidValue/String for userId to match Serverpod 4.0.3 AuthUser authUserId rather than legacy int.
  evidence: Serverpod 4.0.3 `serverpod_auth_idp_server` uses `UuidValue` for `session.authenticated?.authUserId` instead of legacy Serverpod 2.x `int`.
