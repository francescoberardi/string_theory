/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _isc;

abstract class SessionLog
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  SessionLog._({
    this.id,
    required this.userId,
    required this.racquetId,
    required this.startTime,
    required this.durationMinutes,
    this.courtSurface,
    this.notes,
    required this.source,
    this.externalWorkoutId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory SessionLog({
    int? id,
    required _isc.UuidValue userId,
    required int racquetId,
    required DateTime startTime,
    required int durationMinutes,
    String? courtSurface,
    String? notes,
    required String source,
    String? externalWorkoutId,
    DateTime? createdAt,
  }) = _SessionLogImpl;

  factory SessionLog.fromJson(Map<String, dynamic> jsonSerialization) {
    return SessionLog(
      id: jsonSerialization['id'] as int?,
      userId: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      racquetId: jsonSerialization['racquetId'] as int,
      startTime: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['startTime'],
      ),
      durationMinutes: jsonSerialization['durationMinutes'] as int,
      courtSurface: jsonSerialization['courtSurface'] as String?,
      notes: jsonSerialization['notes'] as String?,
      source: jsonSerialization['source'] as String,
      externalWorkoutId: jsonSerialization['externalWorkoutId'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  _isc.UuidValue userId;

  int racquetId;

  DateTime startTime;

  int durationMinutes;

  String? courtSurface;

  String? notes;

  String source;

  String? externalWorkoutId;

  DateTime createdAt;

  /// Returns a shallow copy of this [SessionLog]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  SessionLog copyWith({
    int? id,
    _isc.UuidValue? userId,
    int? racquetId,
    DateTime? startTime,
    int? durationMinutes,
    String? courtSurface,
    String? notes,
    String? source,
    String? externalWorkoutId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SessionLog',
      if (id != null) 'id': id,
      'userId': userId.toJson(),
      'racquetId': racquetId,
      'startTime': startTime.toJson(),
      'durationMinutes': durationMinutes,
      if (courtSurface != null) 'courtSurface': courtSurface,
      if (notes != null) 'notes': notes,
      'source': source,
      if (externalWorkoutId != null) 'externalWorkoutId': externalWorkoutId,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SessionLog',
      if (id != null) 'id': id,
      'userId': userId.toJson(),
      'racquetId': racquetId,
      'startTime': startTime.toJson(),
      'durationMinutes': durationMinutes,
      if (courtSurface != null) 'courtSurface': courtSurface,
      if (notes != null) 'notes': notes,
      'source': source,
      if (externalWorkoutId != null) 'externalWorkoutId': externalWorkoutId,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SessionLogImpl extends SessionLog {
  _SessionLogImpl({
    int? id,
    required _isc.UuidValue userId,
    required int racquetId,
    required DateTime startTime,
    required int durationMinutes,
    String? courtSurface,
    String? notes,
    required String source,
    String? externalWorkoutId,
    DateTime? createdAt,
  }) : super._(
         id: id,
         userId: userId,
         racquetId: racquetId,
         startTime: startTime,
         durationMinutes: durationMinutes,
         courtSurface: courtSurface,
         notes: notes,
         source: source,
         externalWorkoutId: externalWorkoutId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [SessionLog]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  SessionLog copyWith({
    Object? id = _Undefined,
    _isc.UuidValue? userId,
    int? racquetId,
    DateTime? startTime,
    int? durationMinutes,
    Object? courtSurface = _Undefined,
    Object? notes = _Undefined,
    String? source,
    Object? externalWorkoutId = _Undefined,
    DateTime? createdAt,
  }) {
    return SessionLog(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      racquetId: racquetId ?? this.racquetId,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      courtSurface: courtSurface is String? ? courtSurface : this.courtSurface,
      notes: notes is String? ? notes : this.notes,
      source: source ?? this.source,
      externalWorkoutId: externalWorkoutId is String?
          ? externalWorkoutId
          : this.externalWorkoutId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
