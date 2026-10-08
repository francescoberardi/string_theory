import 'package:serverpod/serverpod.dart';
import '../domain/decay_engine.dart';
import '../generated/protocol.dart';
import '../messaging/bag_channels.dart';
import '../util/tenant_resolver.dart';

/// Endpoint for recording tennis match/practice sessions,
/// incrementing stringbed court hours, and recalculating health scores.
class SessionEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Records a new playing session, updating the active stringbed court hours
  /// and health score idempotently.
  Future<SessionLog> logSession(Session session, SessionLog log) async {
    final userId = resolveUserId(session);

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

    final SessionLog logged;
    final StringJob? updatedJob;
    try {
      (logged, updatedJob) = await _insertSession(
        session,
        log,
        userId,
        trimmedExternalId,
      );
    } on DatabaseUniqueViolationException catch (e) {
      // A concurrent sync of the same workout committed first. This
      // transaction rolled back, so no hours were counted: return the winner.
      if (trimmedExternalId == null ||
          e.constraintName != 'session_log_user_external_id_idx') {
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

    // Publish only after the transaction committed and a new row was inserted.
    if (updatedJob != null) {
      await _publishSessionLogged(
        session,
        userId,
        logged.racquetId,
        updatedJob,
      );
    }
    return logged;
  }

  /// Posts a [BagChannels.sessionLogged] message to the user's bag channel.
  /// A publish failure is logged and never fails the request.
  Future<void> _publishSessionLogged(
    Session session,
    UuidValue userId,
    int racquetId,
    StringJob updatedJob,
  ) async {
    try {
      final posted = await session.messages.postMessage(
        BagChannels.forUser(userId),
        BagStreamMessage(
          eventType: BagChannels.sessionLogged,
          racquetId: racquetId,
          healthScore: updatedJob.currentHealthScore,
          totalCourtHours: updatedJob.totalCourtHours,
          timestamp: DateTime.now().toUtc(),
        ),
      );
      if (!posted) {
        session.log(
          'Failed to publish sessionLogged for racquet $racquetId: '
          'postMessage returned false',
          level: LogLevel.warning,
        );
      }
    } catch (e, stackTrace) {
      session.log(
        'Failed to publish sessionLogged for racquet $racquetId: $e',
        level: LogLevel.warning,
        exception: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Returns the session already logged under [externalWorkoutId] for
  /// [userId], or null if none exists. Workout IDs are unique per tenant, so
  /// another account logging the same ID never matches.
  Future<SessionLog?> _findByExternalWorkoutId(
    Session session,
    String externalWorkoutId,
    UuidValue userId, {
    Transaction? transaction,
  }) {
    return SessionLog.db.findFirstRow(
      session,
      where: (t) =>
          t.userId.equals(userId) &
          t.externalWorkoutId.equals(externalWorkoutId),
      transaction: transaction,
    );
  }

  /// Inserts [log] and updates the active string job in one transaction.
  ///
  /// Returns the session log and the updated [StringJob]; `updatedJob` is null
  /// when an existing log was returned idempotently.
  Future<(SessionLog log, StringJob? updatedJob)> _insertSession(
    Session session,
    SessionLog log,
    UuidValue userId,
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
        if (existing != null) return (existing, null);
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
      final updatedJob = await StringJob.db.updateRow(
        session,
        stringJob.copyWith(
          totalCourtHours: newTotalHours,
          currentHealthScore: newHealthScore,
        ),
        transaction: tx,
      );

      return (insertedSession, updatedJob);
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
    final userId = resolveUserId(session);

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
