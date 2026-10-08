import 'package:equatable/equatable.dart';
import 'package:string_theory_client/string_theory_client.dart';

abstract class BagEvent extends Equatable {
  const BagEvent();

  @override
  List<Object?> get props => [];
}

class LoadBag extends BagEvent {
  /// Called once the load settles, with [BagLoaded] or [BagError] emitted,
  /// so a pull-to-refresh can hold its spinner until then. Not part of
  /// [props].
  final void Function()? onSettled;

  const LoadBag({this.onSettled});
}

class AddRacquet extends BagEvent {
  final String name;
  final String? brand;
  final String? model;
  final bool isPrimary;
  final StringMaterialCategory materialCategory;
  final String stringBrand;
  final String stringModel;
  final double tension;
  final double maxRatedHours;
  final DateTime stringingDate;

  const AddRacquet({
    required this.name,
    this.brand,
    this.model,
    this.isPrimary = false,
    this.materialCategory = StringMaterialCategory.coPoly,
    required this.stringBrand,
    required this.stringModel,
    required this.tension,
    required this.maxRatedHours,
    required this.stringingDate,
  });

  @override
  List<Object?> get props => [
    name,
    brand,
    model,
    isPrimary,
    materialCategory,
    stringBrand,
    stringModel,
    tension,
    maxRatedHours,
    stringingDate,
  ];
}

class DeleteRacquet extends BagEvent {
  final int racquetId;

  const DeleteRacquet(this.racquetId);

  @override
  List<Object?> get props => [racquetId];
}

class SetPrimaryRacquet extends BagEvent {
  final int racquetId;

  const SetPrimaryRacquet(this.racquetId);

  @override
  List<Object?> get props => [racquetId];
}

class SeedSampleBag extends BagEvent {
  const SeedSampleBag();
}

class FastForwardRacquetAge extends BagEvent {
  final int racquetId;
  final int days;

  const FastForwardRacquetAge(this.racquetId, {this.days = 30});

  @override
  List<Object?> get props => [racquetId, days];
}

/// A real-time [BagStreamMessage] pushed by the server on the user's bag
/// channel.
class BagStreamReceived extends BagEvent {
  final BagStreamMessage message;

  const BagStreamReceived(this.message);

  @override
  List<Object?> get props => [message];
}

/// Logs a tennis session against [racquetId], attributing court time to its
/// active stringbed.
class LogSession extends BagEvent {
  final int racquetId;
  final DateTime startTime;
  final int durationMinutes;
  final String? courtSurface;
  final String? notes;
  final String source;
  final String? externalWorkoutId;

  /// Called once the server has accepted the session (even if the bag
  /// refresh that follows fails) or once it is safely queued offline.
  /// Not part of [props].
  final void Function()? onLogged;

  const LogSession({
    required this.racquetId,
    required this.startTime,
    required this.durationMinutes,
    this.courtSurface,
    this.notes,
    required this.source,
    this.externalWorkoutId,
    this.onLogged,
  });

  @override
  List<Object?> get props => [
    racquetId,
    startTime,
    durationMinutes,
    courtSurface,
    notes,
    source,
    externalWorkoutId,
  ];
}

/// Retires the active stringbed of [racquetId] and mounts a fresh one at 100%
/// health. With [keepSame] the previous specs carry over; otherwise the given
/// specs apply, falling back to the previous value for any left null.
class RestringRacquet extends BagEvent {
  final int racquetId;
  final bool keepSame;
  final StringMaterialCategory? materialCategory;
  final String? stringBrand;
  final String? stringModel;
  final double? tension;
  final double? maxRatedHours;

  const RestringRacquet(
    this.racquetId, {
    this.keepSame = true,
    this.materialCategory,
    this.stringBrand,
    this.stringModel,
    this.tension,
    this.maxRatedHours,
  });

  @override
  List<Object?> get props => [
    racquetId,
    keepSame,
    materialCategory,
    stringBrand,
    stringModel,
    tension,
    maxRatedHours,
  ];
}

/// Drains the offline session queue to the server and reconciles the bag with
/// the authoritative server state.
class SyncOfflineSessions extends BagEvent {
  const SyncOfflineSessions();
}
