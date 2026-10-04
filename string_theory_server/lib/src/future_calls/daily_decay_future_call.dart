import 'package:serverpod/serverpod.dart';

import '../domain/decay_engine.dart';
import '../generated/protocol.dart';

/// Serverpod FutureCall that executes daily tension relaxation and health decay
/// across all active [StringJob] records in the database.
class DailyDecayFutureCall extends FutureCall {
  /// Entry point called by Serverpod's FutureCall scheduler.
  Future<void> execute(Session session) async {
    await DailyDecayService.performDecayCalculation(session);
  }
}

/// Service performing daily stringbed tension relaxation and health decay calculations.
class DailyDecayService {
  /// Scans all active string jobs and recalculates their health score
  /// based on static calendar shelf-life decay and recorded court hours.
  ///
  /// Returns the number of [StringJob] records whose health scores were updated.
  static Future<int> performDecayCalculation(
    Session session, {
    DateTime? now,
  }) async {
    final effectiveNow = now ?? DateTime.now().toUtc();
    final activeJobs = await StringJob.db.find(
      session,
      where: (t) => t.isActive.equals(true),
    );

    var updatedCount = 0;
    for (final job in activeJobs) {
      try {
        final calculatedHealth = DecayEngine.calculateHealth(
          hoursPlayed: job.totalCourtHours,
          maxRatedHours: job.maxRatedHours,
          stringingDate: job.stringingDate,
          materialCategory: job.materialCategory,
          now: effectiveNow,
        );

        if (calculatedHealth != job.currentHealthScore) {
          await StringJob.db.updateRow(
            session,
            job.copyWith(currentHealthScore: calculatedHealth),
          );
          updatedCount++;
        }
      } catch (e, stack) {
        session.log(
          'Error updating decay for StringJob #${job.id}: $e',
          level: LogLevel.error,
          stackTrace: stack,
        );
      }
    }

    session.log(
      'DailyDecayFutureCall executed: $updatedCount/${activeJobs.length} active string jobs updated.',
      level: LogLevel.info,
    );

    return updatedCount;
  }
}
