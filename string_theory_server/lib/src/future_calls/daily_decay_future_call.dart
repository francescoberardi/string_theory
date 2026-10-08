import 'package:serverpod/serverpod.dart';

import '../domain/decay_engine.dart';
import '../generated/protocol.dart';

/// Serverpod FutureCall that executes daily tension relaxation and health decay
/// across all active [StringJob] records in the database.
class DailyDecayFutureCall extends FutureCall {
  /// Entry point called by Serverpod's FutureCall scheduler.
  ///
  /// Returns quietly when another decay run holds the lock.
  Future<void> execute(Session session) async {
    try {
      await DailyDecayService.performDecayCalculation(session);
    } on DecayRunInProgressException {
      session.log(
        'DailyDecayFutureCall skipped: another decay run is in progress.',
        level: LogLevel.info,
      );
    }
  }
}

/// Thrown by [DailyDecayService.performDecayCalculation] when another decay
/// run holds the decay advisory lock.
class DecayRunInProgressException implements Exception {
  /// Creates the exception.
  const DecayRunInProgressException();

  @override
  String toString() =>
      'DecayRunInProgressException: a decay run is already '
      'in progress';
}

/// Service performing daily stringbed tension relaxation and health decay calculations.
class DailyDecayService {
  /// Default number of [StringJob] rows read and written per page.
  static const defaultBatchSize = 500;

  /// PostgreSQL advisory lock key held for the duration of a decay run.
  static const lockKey = 7421893;

  /// Scans all active string jobs and recalculates their health score
  /// based on static calendar shelf-life decay and recorded court hours.
  ///
  /// Jobs are read in pages of [batchSize] rows using keyset pagination on
  /// `id`, so memory use stays bounded regardless of table size. Changed
  /// scores in a page are written in one batch update that touches only the
  /// `currentHealthScore` column. Each write is conditional on the job's
  /// `totalCourtHours` being unchanged since the page was read, so a score a
  /// session wrote in the meantime is never overwritten; such a job is not
  /// counted and decays on the next run.
  ///
  /// [afterPageRead] is a test seam called with each page after it is read
  /// and before its scores are written, to simulate concurrent updates.
  ///
  /// Only one run executes at a time: the run holds the transaction-level
  /// advisory lock [lockKey] on one otherwise idle transaction, and throws a
  /// [DecayRunInProgressException] if the lock is taken. The pages are read
  /// and written outside that transaction, so no row stays locked for the
  /// whole run, and the lock is released when the run ends, even if it throws.
  ///
  /// Returns the number of [StringJob] records whose health scores were updated.
  static Future<int> performDecayCalculation(
    Session session, {
    DateTime? now,
    int batchSize = defaultBatchSize,
    Future<void> Function(List<StringJob> page)? afterPageRead,
  }) async {
    if (batchSize < 1) {
      throw ArgumentError.value(batchSize, 'batchSize', 'must be positive');
    }
    final effectiveNow = now ?? DateTime.now().toUtc();

    return session.db.transaction((lockTransaction) async {
      final result = await session.db.unsafeQuery(
        'SELECT pg_try_advisory_xact_lock($lockKey);',
        transaction: lockTransaction,
      );
      if (result.first.first != true) {
        throw const DecayRunInProgressException();
      }
      return _decayAllPages(
        session,
        effectiveNow,
        batchSize,
        afterPageRead,
      );
    });
  }

  /// Reads active jobs page by page and writes their changed scores.
  static Future<int> _decayAllPages(
    Session session,
    DateTime effectiveNow,
    int batchSize,
    Future<void> Function(List<StringJob> page)? afterPageRead,
  ) async {
    var scannedCount = 0;
    var updatedCount = 0;
    int? lastId;
    while (true) {
      final cursor = lastId;
      final page = await StringJob.db.find(
        session,
        where: (t) => cursor == null
            ? t.isActive.equals(true)
            : t.isActive.equals(true) & (t.id > cursor),
        orderBy: (t) => t.id,
        limit: batchSize,
      );
      if (page.isEmpty) break;

      scannedCount += page.length;
      lastId = page.last.id;
      await afterPageRead?.call(page);
      final written = await _updatePage(session, page, effectiveNow);
      updatedCount += written.length;

      if (page.length < batchSize) break;
    }

    session.log(
      'DailyDecayFutureCall executed: $updatedCount/$scannedCount active string jobs updated.',
      level: LogLevel.info,
    );

    return updatedCount;
  }

  /// Recalculates health for one page and persists the changed rows.
  ///
  /// Each write is conditional on the job's `totalCourtHours` still matching
  /// the value read with the page. A job whose hours a session changed in the
  /// meantime keeps the score that session wrote and is decayed on the next
  /// run.
  ///
  /// Returns the jobs written, with their new scores.
  static Future<List<StringJob>> _updatePage(
    Session session,
    List<StringJob> page,
    DateTime now,
  ) async {
    final changed = <StringJob>[];
    for (final job in page) {
      try {
        final calculatedHealth = DecayEngine.calculateHealth(
          hoursPlayed: job.totalCourtHours,
          maxRatedHours: job.maxRatedHours,
          stringingDate: job.stringingDate,
          materialCategory: job.materialCategory,
          now: now,
        );
        if (calculatedHealth != job.currentHealthScore) {
          changed.add(job.copyWith(currentHealthScore: calculatedHealth));
        }
      } catch (e, stack) {
        _logJobError(session, job, e, stack);
      }
    }
    if (changed.isEmpty) return const [];

    try {
      final result = await session.db.unsafeQuery(
        'UPDATE string_job AS j SET "currentHealthScore" = v.score '
        'FROM unnest(@ids::bigint[], @scores::bigint[], '
        '@hours::double precision[]) AS v(id, score, hours) '
        'WHERE j.id = v.id AND j."totalCourtHours" = v.hours '
        'RETURNING j.id',
        parameters: QueryParameters.named({
          'ids': [for (final job in changed) job.id!],
          'scores': [for (final job in changed) job.currentHealthScore],
          'hours': [for (final job in changed) job.totalCourtHours],
        }),
      );
      final writtenIds = {for (final row in result) row.first as int};
      return [
        for (final job in changed)
          if (writtenIds.contains(job.id)) job,
      ];
    } catch (e, stack) {
      session.log(
        'Batch decay update failed for ${changed.length} StringJobs, retrying row by row: $e',
        level: LogLevel.warning,
        stackTrace: stack,
      );
    }

    // The batch write is all-or-nothing, so fall back to single-row writes to
    // keep one bad row from dropping the rest of the page.
    final written = <StringJob>[];
    for (final job in changed) {
      try {
        final updated = await StringJob.db.updateWhere(
          session,
          columnValues: (t) => [t.currentHealthScore(job.currentHealthScore)],
          where: (t) =>
              t.id.equals(job.id!) &
              t.totalCourtHours.equals(job.totalCourtHours),
        );
        if (updated.isNotEmpty) written.add(job);
      } catch (e, stack) {
        _logJobError(session, job, e, stack);
      }
    }
    return written;
  }

  static void _logJobError(
    Session session,
    StringJob job,
    Object error,
    StackTrace stack,
  ) {
    session.log(
      'Error updating decay for StringJob #${job.id}: $error',
      level: LogLevel.error,
      stackTrace: stack,
    );
  }
}
