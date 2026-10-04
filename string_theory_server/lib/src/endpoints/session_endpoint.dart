import 'package:serverpod/serverpod.dart';
import '../domain/decay_engine.dart';
import '../generated/protocol.dart';

/// Endpoint for recording tennis match/practice sessions,
/// incrementing stringbed court hours, and recalculating health scores.
class SessionEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  int _resolveUserId(Session session) {
    final authInfo = session.authenticated;
    if (authInfo == null) {
      throw BagException(
        message: 'User is not authenticated',
        statusCode: 401,
      );
    }
    final parsed = int.tryParse(authInfo.userIdentifier);
    if (parsed != null) {
      return parsed;
    }

    // Deterministic resolution for UUID userIdentifier strings across server restarts
    final cleanHex = authInfo.userIdentifier.replaceAll('-', '');
    final bigIntVal = BigInt.tryParse(cleanHex, radix: 16);
    if (bigIntVal != null) {
      return (bigIntVal.remainder(BigInt.from(0x7FFFFFFFFFFFFFFF))).toInt();
    }

    // Deterministic 64-bit FNV-1a hash fallback for non-UUID strings
    var hash = BigInt.parse('0xcbf29ce484222325');
    final prime = BigInt.parse('0x100000001b3');
    for (final byte in authInfo.userIdentifier.codeUnits) {
      hash = (hash ^ BigInt.from(byte)) * prime;
    }
    return (hash.remainder(BigInt.from(0x7FFFFFFFFFFFFFFF))).abs().toInt();
  }

  /// Records a new playing session, updating the active stringbed court hours
  /// and health score idempotently.
  Future<SessionLog> logSession(Session session, SessionLog log) async {
    final userId = _resolveUserId(session);

    if (log.durationMinutes <= 0) {
      throw BagException(
        message: 'Duration must be greater than zero',
        statusCode: 400,
      );
    }

    final trimmedExternalId =
        (log.externalWorkoutId != null &&
            log.externalWorkoutId!.trim().isNotEmpty)
        ? log.externalWorkoutId!.trim()
        : null;

    try {
      return await _insertSession(session, log, userId, trimmedExternalId);
    } on DatabaseUniqueViolationException catch (e) {
      // A concurrent sync of the same workout committed first. This
      // transaction rolled back, so no hours were counted: return the winner.
      if (trimmedExternalId == null ||
          e.constraintName != 'session_log_external_id_idx') {
        rethrow;
      }
      final existing = await _findByExternalWorkoutId(
        session,
        trimmedExternalId,
        userId,
      );
      if (existing == null) rethrow;
      return existing;
    }
  }

  /// Returns the session already logged under [externalWorkoutId] for
  /// [userId], or null if none exists. Throws a 409 [BagException] if the
  /// workout is registered to another account.
  Future<SessionLog?> _findByExternalWorkoutId(
    Session session,
    String externalWorkoutId,
    int userId, {
    Transaction? transaction,
  }) async {
    final existing = await SessionLog.db.findFirstRow(
      session,
      where: (t) => t.externalWorkoutId.equals(externalWorkoutId),
      transaction: transaction,
    );
    if (existing != null && existing.userId != userId) {
      throw BagException(
        message: 'Workout already registered to another account',
        statusCode: 409,
      );
    }
    return existing;
  }

  Future<SessionLog> _insertSession(
    Session session,
    SessionLog log,
    int userId,
    String? trimmedExternalId,
  ) async {
    return await session.db.transaction((tx) async {
      // 1. Validate racquet ownership and existence
      final racquet = await Racquet.db.findById(
        session,
        log.racquetId,
        include: Racquet.include(
          activeStringJob: StringJob.include(),
        ),
        transaction: tx,
      );

      if (racquet == null || racquet.userId != userId) {
        throw BagException(
          message: 'Racquet not found or unauthorized',
          statusCode: 404,
        );
      }

      // 2. Check idempotency right after validating racquet ownership
      if (trimmedExternalId != null) {
        final existing = await _findByExternalWorkoutId(
          session,
          trimmedExternalId,
          userId,
          transaction: tx,
        );
        if (existing != null) return existing;
      }

      // 3. Only check activeStringJob if inserting a new session
      StringJob? stringJob = racquet.activeStringJob;
      if (stringJob == null && racquet.activeStringJobId != null) {
        stringJob = await StringJob.db.findById(
          session,
          racquet.activeStringJobId!,
          transaction: tx,
        );
      }

      if (stringJob == null || !stringJob.isActive) {
        throw BagException(
          message: 'Racquet has no active string job',
          statusCode: 400,
        );
      }

      // 4. Insert new SessionLog
      final sessionToInsert = log.copyWith(
        id: null,
        userId: userId,
        externalWorkoutId: trimmedExternalId,
        createdAt: DateTime.now().toUtc(),
      );
      final insertedSession = await SessionLog.db.insertRow(
        session,
        sessionToInsert,
        transaction: tx,
      );

      // 5. Increment active string job's totalCourtHours
      final sessionHours = log.durationMinutes / 60.0;
      final newTotalHours = stringJob.totalCourtHours + sessionHours;

      // 6. Recalculate health score using pure Dart DecayEngine
      final newHealthScore = DecayEngine.calculateHealth(
        hoursPlayed: newTotalHours,
        maxRatedHours: stringJob.maxRatedHours,
        stringingDate: stringJob.stringingDate,
        materialCategory: stringJob.materialCategory,
      );

      // 7. Persist updated StringJob
      await StringJob.db.updateRow(
        session,
        stringJob.copyWith(
          totalCourtHours: newTotalHours,
          currentHealthScore: newHealthScore,
        ),
        transaction: tx,
      );

      return insertedSession;
    });
  }

  /// Retrieves session logs for the authenticated user, optionally filtered
  /// by racquet ID, with optional pagination.
  Future<List<SessionLog>> getSessionLogs(
    Session session, {
    int? racquetId,
    int? limit,
    int? offset,
  }) async {
    final userId = _resolveUserId(session);

    if ((limit != null && limit < 0) || (offset != null && offset < 0)) {
      throw BagException(
        message: 'Limit and offset must be non-negative',
        statusCode: 400,
      );
    }

    if (racquetId != null) {
      final racquet = await Racquet.db.findById(session, racquetId);
      if (racquet == null || racquet.userId != userId) {
        throw BagException(
          message: 'Racquet not found or unauthorized',
          statusCode: 404,
        );
      }
    }

    return await SessionLog.db.find(
      session,
      where: (t) => racquetId != null
          ? (t.userId.equals(userId) & t.racquetId.equals(racquetId))
          : t.userId.equals(userId),
      orderBy: (t) => t.startTime.desc(),
      limit: limit,
      offset: offset,
    );
  }
}
