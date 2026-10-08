import 'package:serverpod/serverpod.dart';
import '../domain/decay_engine.dart';
import '../future_calls/daily_decay_future_call.dart';
import '../generated/protocol.dart';
import '../messaging/bag_channels.dart';
import '../util/tenant_resolver.dart';

/// Endpoint for managing virtual gear bags, racquets, and string setups.
class BagEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Returns all racquets in the virtual bag owned by the authenticated user,
  /// eagerly loading each racquet's active string job.
  Future<List<Racquet>> getVirtualBag(Session session) async {
    final userId = resolveUserId(session);
    return await Racquet.db.find(
      session,
      where: (t) => t.userId.equals(userId),
      orderBy: (t) => t.id,
      include: Racquet.include(
        activeStringJob: StringJob.include(),
      ),
    );
  }

  /// Streams real-time [BagStreamMessage] updates for the authenticated
  /// user's bag from channel `user_{userId}_bag`.
  Stream<BagStreamMessage> bagUpdates(Session session) {
    final userId = resolveUserId(session);
    return session.messages.createStream<BagStreamMessage>(
      BagChannels.forUser(userId),
    );
  }

  /// Atomically creates a new racquet frame and its initial mounted string job
  /// within a single database transaction.
  Future<Racquet> createRacquet(
    Session session, {
    required String racquetName,
    String? brand,
    String? model,
    bool? isPrimary,
    StringMaterialCategory? materialCategory,
    String? stringBrand,
    String? stringModel,
    double? tension,
    double? maxRatedHours,
    DateTime? stringingDate,
  }) async {
    final trimmedName = racquetName.trim();
    if (trimmedName.isEmpty) {
      throw BagException(
        message: 'Racquet name cannot be empty',
        statusCode: 400,
      );
    }

    final userId = resolveUserId(session);
    final now = DateTime.now().toUtc();
    final effectiveIsPrimary = isPrimary ?? false;
    final effectiveCategory = materialCategory ?? StringMaterialCategory.coPoly;
    final effectiveMaxHours = maxRatedHours ?? 20.0;

    return await session.db.transaction((tx) async {
      // If marked as primary, unset any existing primaries for this user
      if (effectiveIsPrimary) {
        final existingPrimaries = await Racquet.db.find(
          session,
          where: (t) => t.userId.equals(userId) & t.isPrimary.equals(true),
          transaction: tx,
        );
        for (final r in existingPrimaries) {
          await Racquet.db.updateRow(
            session,
            r.copyWith(isPrimary: false, updatedAt: now),
            transaction: tx,
          );
        }
      }

      // 1. Insert racquet frame
      final racquet = await Racquet.db.insertRow(
        session,
        Racquet(
          userId: userId,
          name: trimmedName,
          brand: brand,
          model: model,
          isPrimary: effectiveIsPrimary,
          createdAt: now,
          updatedAt: now,
        ),
        transaction: tx,
      );

      // 2. Insert initial active string job linked to the new racquet
      final stringJob = await StringJob.db.insertRow(
        session,
        StringJob(
          userId: userId,
          racquetId: racquet.id!,
          materialCategory: effectiveCategory,
          brand: stringBrand,
          model: stringModel,
          stringingDate: stringingDate ?? now,
          installedTension: tension,
          maxRatedHours: effectiveMaxHours,
          totalCourtHours: 0.0,
          currentHealthScore: 100,
          isActive: true,
          createdAt: now,
        ),
        transaction: tx,
      );

      // 3. Link activeStringJobId on the racquet
      final updatedRacquet = await Racquet.db.updateRow(
        session,
        racquet.copyWith(
          activeStringJobId: stringJob.id,
          updatedAt: now,
        ),
        transaction: tx,
      );

      return updatedRacquet.copyWith(activeStringJob: stringJob);
    });
  }

  /// Sets the specified racquet as the primary racquet in the user's bag,
  /// atomically unsetting any previous primary racquets and returning the racquet
  /// with its active string job loaded.
  Future<Racquet> setPrimary(
    Session session, {
    required int racquetId,
  }) async {
    final userId = resolveUserId(session);
    final now = DateTime.now().toUtc();

    return await session.db.transaction((tx) async {
      final target = await Racquet.db.findById(
        session,
        racquetId,
        transaction: tx,
      );
      if (target == null || target.userId != userId) {
        throw BagException(
          message: 'Racquet not found or unauthorized',
          statusCode: 404,
        );
      }

      final existingPrimaries = await Racquet.db.find(
        session,
        where: (t) => t.userId.equals(userId) & t.isPrimary.equals(true),
        transaction: tx,
      );
      for (final r in existingPrimaries) {
        if (r.id != racquetId) {
          await Racquet.db.updateRow(
            session,
            r.copyWith(isPrimary: false, updatedAt: now),
            transaction: tx,
          );
        }
      }

      await Racquet.db.updateRow(
        session,
        target.copyWith(isPrimary: true, updatedAt: now),
        transaction: tx,
      );

      return (await Racquet.db.findById(
        session,
        racquetId,
        transaction: tx,
        include: Racquet.include(
          activeStringJob: StringJob.include(),
        ),
      ))!;
    });
  }

  /// Deletes a racquet and its associated string jobs.
  /// Throws [BagException] if the racquet does not belong to the authenticated user.
  Future<bool> deleteRacquet(
    Session session, {
    required int racquetId,
  }) async {
    final userId = resolveUserId(session);

    return await session.db.transaction((tx) async {
      final target = await Racquet.db.findById(
        session,
        racquetId,
        transaction: tx,
      );
      if (target == null || target.userId != userId) {
        throw BagException(
          message: 'Racquet not found or unauthorized',
          statusCode: 404,
        );
      }

      await Racquet.db.deleteRow(session, target, transaction: tx);
      return true;
    });
  }

  /// Triggers the static tension relaxation and decay calculation worker
  /// immediately across active string jobs.
  ///
  /// Intended for on-demand developer/judge demonstration of background decay.
  /// Returns the number of [StringJob] records updated.
  Future<int> triggerDailyDecayNow(Session session) async {
    resolveUserId(session);
    return await DailyDecayService.performDecayCalculation(session);
  }

  /// Shifts the active string job's stringingDate for the given racquet by [days]
  /// into the past (defaulting to 30 days) and immediately recalculates the health score.
  ///
  /// Intended for developer/judge demonstration of stringbed aging and decay thresholds.
  /// Returns the updated [Racquet] with its active string job.
  Future<Racquet> fastForwardRacquetAge(
    Session session, {
    required int racquetId,
    int? days,
  }) async {
    final userId = resolveUserId(session);
    final effectiveDays = days ?? 30;
    if (effectiveDays <= 0) {
      throw BagException(
        message: 'Days must be a positive integer',
        statusCode: 400,
      );
    }

    return await session.db.transaction((tx) async {
      final racquet = await Racquet.db.findById(
        session,
        racquetId,
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

      final stringJob = racquet.activeStringJob;
      if (stringJob == null) {
        throw BagException(
          message: 'Racquet has no active string job',
          statusCode: 400,
        );
      }

      final shiftedDate = stringJob.stringingDate.subtract(
        Duration(days: effectiveDays),
      );
      final newHealthScore = DecayEngine.calculateHealth(
        hoursPlayed: stringJob.totalCourtHours,
        maxRatedHours: stringJob.maxRatedHours,
        stringingDate: shiftedDate,
        materialCategory: stringJob.materialCategory,
      );

      final updatedJob = await StringJob.db.updateRow(
        session,
        stringJob.copyWith(
          stringingDate: shiftedDate,
          currentHealthScore: newHealthScore,
        ),
        transaction: tx,
      );

      return racquet.copyWith(activeStringJob: updatedJob);
    });
  }

  /// Restrings a racquet atomically within a single database transaction.
  ///
  /// Marks the current active string job inactive, records a [RestringEvent]
  /// snapshot with final hours and days active, creates a new active string job
  /// initialized to 100% health and 0 court hours, updates the racquet's
  /// [Racquet.activeStringJobId], and broadcasts a [BagStreamMessage]
  /// with [BagChannels.restrung] to `user_{userId}_bag`.
  Future<Racquet> restringRacquet(
    Session session, {
    required int racquetId,
    bool? keepSame,
    StringJob? newSpecs,
    StringMaterialCategory? materialCategory,
    String? stringBrand,
    String? stringModel,
    double? tension,
    double? maxRatedHours,
    DateTime? restringDate,
    bool? simulateFailure,
  }) async {
    final userId = resolveUserId(session);
    final effectiveKeepSame = keepSame ?? true;
    final effectiveSimulateFailure = simulateFailure ?? false;
    final now = DateTime.now().toUtc();
    final effectiveRestringDate = (restringDate ?? now).toUtc();

    // `simulateFailure` and `restringDate` are test seams: reject them outside
    // test mode before any write happens.
    if ((effectiveSimulateFailure || restringDate != null) &&
        session.serverpod.runMode != ServerpodRunMode.test) {
      throw BagException(
        message:
            'simulateFailure and restringDate are only supported in test mode',
        statusCode: 400,
      );
    }

    final updatedRacquet = await session.db.transaction((tx) async {
      // 1. Validate racquet ownership and existence. The row lock serializes
      // concurrent restrings of the same racquet so only one can retire the
      // active job. No include here: FOR UPDATE cannot lock the nullable side
      // of the outer join an include produces.
      final racquet = await Racquet.db.findById(
        session,
        racquetId,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );

      if (racquet == null || racquet.userId != userId) {
        throw BagException(
          message: 'Racquet not found or unauthorized',
          statusCode: 404,
        );
      }

      // 2. Fetch active string job
      final activeStringJobId = racquet.activeStringJobId;
      final oldJob = activeStringJobId == null
          ? null
          : await StringJob.db.findById(
              session,
              activeStringJobId,
              transaction: tx,
            );

      if (oldJob == null || !oldJob.isActive) {
        throw BagException(
          message: 'Racquet has no active string job to retire',
          statusCode: 400,
        );
      }

      // 3. Mark retired job as inactive
      final retiredJob = await StringJob.db.updateRow(
        session,
        oldJob.copyWith(isActive: false),
        transaction: tx,
      );

      // 4. Calculate days active and persist RestringEvent
      final rawDaysActive = effectiveRestringDate
          .difference(oldJob.stringingDate)
          .inDays;
      final finalDaysActive = rawDaysActive < 0 ? 0 : rawDaysActive;

      final finalHealthScore = DecayEngine.calculateHealth(
        hoursPlayed: oldJob.totalCourtHours,
        maxRatedHours: oldJob.maxRatedHours,
        stringingDate: oldJob.stringingDate,
        materialCategory: oldJob.materialCategory,
        now: effectiveRestringDate,
      );

      final restringEvent = RestringEvent(
        userId: userId,
        racquetId: racquetId,
        stringJobId: retiredJob.id!,
        stringDescription: _formatStringDescription(oldJob),
        materialCategory: oldJob.materialCategory,
        installedTension: oldJob.installedTension,
        stringingDate: oldJob.stringingDate,
        restringDate: effectiveRestringDate,
        finalCourtHours: oldJob.totalCourtHours,
        finalDaysActive: finalDaysActive,
        finalHealthScore: finalHealthScore,
        createdAt: DateTime.now().toUtc(),
      );

      await RestringEvent.db.insertRow(
        session,
        restringEvent,
        transaction: tx,
      );

      if (effectiveSimulateFailure) {
        throw Exception('Simulated transaction failure');
      }

      // 5. Determine specs for new active string job
      final StringMaterialCategory nextCategory;
      final String? nextBrand;
      final String? nextModel;
      final double? nextTension;
      double nextMaxHours;

      if (effectiveKeepSame) {
        nextCategory = oldJob.materialCategory;
        nextBrand = oldJob.brand;
        nextModel = oldJob.model;
        nextTension = oldJob.installedTension;
        nextMaxHours = oldJob.maxRatedHours;
      } else {
        nextCategory =
            newSpecs?.materialCategory ??
            materialCategory ??
            oldJob.materialCategory;
        nextBrand = newSpecs?.brand ?? stringBrand ?? oldJob.brand;
        nextModel = newSpecs?.model ?? stringModel ?? oldJob.model;
        nextTension =
            newSpecs?.installedTension ?? tension ?? oldJob.installedTension;
        nextMaxHours =
            newSpecs?.maxRatedHours ?? maxRatedHours ?? oldJob.maxRatedHours;
      }

      if (!nextMaxHours.isFinite || nextMaxHours <= 0) {
        nextMaxHours = 20.0;
      }

      // 6. Create new active StringJob
      final newJob = await StringJob.db.insertRow(
        session,
        StringJob(
          userId: userId,
          racquetId: racquetId,
          materialCategory: nextCategory,
          brand: nextBrand,
          model: nextModel,
          stringingDate: now,
          installedTension: nextTension,
          maxRatedHours: nextMaxHours,
          totalCourtHours: 0.0,
          currentHealthScore: 100,
          isActive: true,
          createdAt: DateTime.now().toUtc(),
        ),
        transaction: tx,
      );

      // 7. Update racquet with new activeStringJobId
      final savedRacquet = await Racquet.db.updateRow(
        session,
        racquet.copyWith(
          activeStringJobId: newJob.id,
          updatedAt: DateTime.now().toUtc(),
        ),
        transaction: tx,
      );

      return savedRacquet.copyWith(activeStringJob: newJob);
    });

    // 8. WebSocket broadcast after transaction commits successfully
    await _publishRestrung(session, userId, racquetId);

    return updatedRacquet;
  }

  /// Returns all restring events for the specified [racquetId] owned by
  /// the authenticated user, ordered in descending order by restring date.
  Future<List<RestringEvent>> getRestringHistory(
    Session session, {
    required int racquetId,
  }) async {
    final userId = resolveUserId(session);

    final racquet = await Racquet.db.findById(session, racquetId);
    if (racquet == null || racquet.userId != userId) {
      throw BagException(
        message: 'Racquet not found or unauthorized',
        statusCode: 404,
      );
    }

    return await RestringEvent.db.find(
      session,
      where: (t) => t.userId.equals(userId) & t.racquetId.equals(racquetId),
      orderBy: (t) => t.restringDate.desc(),
    );
  }

  String _formatStringDescription(StringJob job) {
    final brand = job.brand?.trim() ?? '';
    final model = job.model?.trim() ?? '';
    if (brand.isNotEmpty && model.isNotEmpty) {
      return '$brand $model';
    } else if (brand.isNotEmpty) {
      return brand;
    } else if (model.isNotEmpty) {
      return model;
    } else {
      return '${job.materialCategory.name} setup';
    }
  }

  Future<void> _publishRestrung(
    Session session,
    UuidValue userId,
    int racquetId,
  ) async {
    try {
      final posted = await session.messages.postMessage(
        BagChannels.forUser(userId),
        BagStreamMessage(
          eventType: BagChannels.restrung,
          racquetId: racquetId,
          healthScore: 100,
          totalCourtHours: 0.0,
          timestamp: DateTime.now().toUtc(),
        ),
      );
      if (!posted) {
        session.log(
          'Failed to publish restrung for racquet $racquetId: '
          'postMessage returned false',
          level: LogLevel.warning,
        );
      }
    } catch (e, stackTrace) {
      session.log(
        'Failed to publish restrung for racquet $racquetId: $e',
        level: LogLevel.warning,
        exception: e,
        stackTrace: stackTrace,
      );
    }
  }
}
