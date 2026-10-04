import 'package:serverpod/serverpod.dart';
import '../domain/decay_engine.dart';
import '../future_calls/daily_decay_future_call.dart';
import '../generated/protocol.dart';

/// Endpoint for managing virtual gear bags, racquets, and string setups.
class BagEndpoint extends Endpoint {
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

  /// Returns all racquets in the virtual bag owned by the authenticated user,
  /// eagerly loading each racquet's active string job.
  Future<List<Racquet>> getVirtualBag(Session session) async {
    final userId = _resolveUserId(session);
    return await Racquet.db.find(
      session,
      where: (t) => t.userId.equals(userId),
      orderBy: (t) => t.id,
      include: Racquet.include(
        activeStringJob: StringJob.include(),
      ),
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

    final userId = _resolveUserId(session);
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
    final userId = _resolveUserId(session);
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
    final userId = _resolveUserId(session);

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
    _resolveUserId(session);
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
    final userId = _resolveUserId(session);
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
}
