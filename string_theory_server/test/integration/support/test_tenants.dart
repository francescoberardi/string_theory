import 'package:serverpod/serverpod.dart' show Namespace, UuidValue;
import 'package:serverpod_test/serverpod_test_public_exports.dart';
import 'package:string_theory_server/src/generated/protocol.dart';

/// Skip reason for Story 6.3 red-phase acceptance scaffolds.
const tddRedPhaseReason =
    'TDD Red Phase: pending Story 6.3 (UUID tenants, decay concurrency)';

/// Fixed auth identities for tenant-isolation tests.
///
/// Serverpod auth issues UUID user identifiers, and Story 6.3 parses them
/// with `UuidValue.withValidation`, so numeric identifiers like `'101'` are
/// not valid tenants.
///
/// Rollback-disabled test groups commit their rows, so each of them uses its
/// own tenant to stay isolated from the others.
abstract final class TestTenants {
  static const a = '6f1e2a7d-4c1d-4f7a-9c43-0b9a5e0e1a01';
  static const b = '6f1e2a7d-4c1d-4f7a-9c43-0b9a5e0e1a02';
  static const c = '6f1e2a7d-4c1d-4f7a-9c43-0b9a5e0e1a03';
  static const d = '6f1e2a7d-4c1d-4f7a-9c43-0b9a5e0e1a04';
  static const e = '6f1e2a7d-4c1d-4f7a-9c43-0b9a5e0e1a05';

  /// Tenant `userId` stored for [a].
  static UuidValue get aUserId => userIdOf(a);

  /// Tenant `userId` stored for [b].
  static UuidValue get bUserId => userIdOf(b);

  /// Tenant `userId` stored for [c].
  static UuidValue get cUserId => userIdOf(c);

  /// Tenant `userId` stored for [d].
  static UuidValue get dUserId => userIdOf(d);

  /// Tenant `userId` stored for [e].
  static UuidValue get eUserId => userIdOf(e);

  /// Tenant `userId` the server stores for [userIdentifier].
  static UuidValue userIdOf(String userIdentifier) =>
      UuidValue.withValidation(userIdentifier);

  /// Authenticates a test session as [userIdentifier].
  static AuthenticationOverride auth(String userIdentifier) =>
      AuthenticationOverride.authenticationInfo(userIdentifier, {});
}

/// Builds a [SessionLog] request for `SessionEndpoint.logSession`.
///
/// The server sets `userId` from the authenticated session, so the value here
/// is the nil UUID placeholder.
SessionLog sessionLogFor(
  int racquetId, {
  int durationMinutes = 90,
  DateTime? startTime,
  String? externalWorkoutId,
}) => SessionLog(
  userId: Namespace.nil.uuidValue,
  racquetId: racquetId,
  startTime: startTime ?? DateTime.now().toUtc(),
  durationMinutes: durationMinutes,
  source: 'HealthKit',
  externalWorkoutId: externalWorkoutId,
);
