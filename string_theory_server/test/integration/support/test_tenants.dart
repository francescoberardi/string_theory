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
abstract final class TestTenants {
  static const a = '6f1e2a7d-4c1d-4f7a-9c43-0b9a5e0e1a01';
  static const b = '6f1e2a7d-4c1d-4f7a-9c43-0b9a5e0e1a02';

  /// Authenticates a test session as [userIdentifier].
  static AuthenticationOverride auth(String userIdentifier) =>
      AuthenticationOverride.authenticationInfo(userIdentifier, {});
}

/// Builds a [SessionLog] request for `SessionEndpoint.logSession`.
///
/// The server sets `userId` from the authenticated session, so the value here
/// is a placeholder. Story 6.3 changes its type to `UuidValue`; update it here
/// only.
SessionLog sessionLogFor(
  int racquetId, {
  int durationMinutes = 90,
  DateTime? startTime,
  String? externalWorkoutId,
}) => SessionLog(
  userId: 0,
  racquetId: racquetId,
  startTime: startTime ?? DateTime.now().toUtc(),
  durationMinutes: durationMinutes,
  source: 'HealthKit',
  externalWorkoutId: externalWorkoutId,
);
