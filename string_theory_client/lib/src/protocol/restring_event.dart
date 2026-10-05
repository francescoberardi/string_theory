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
import 'string_material_category.dart' as _i5v32zda;

abstract class RestringEvent
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  RestringEvent._({
    this.id,
    required this.userId,
    required this.racquetId,
    required this.stringJobId,
    required this.stringDescription,
    required this.materialCategory,
    this.installedTension,
    required this.stringingDate,
    required this.restringDate,
    required this.finalCourtHours,
    required this.finalDaysActive,
    required this.finalHealthScore,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory RestringEvent({
    int? id,
    required int userId,
    required int racquetId,
    required int stringJobId,
    required String stringDescription,
    required _i5v32zda.StringMaterialCategory materialCategory,
    double? installedTension,
    required DateTime stringingDate,
    required DateTime restringDate,
    required double finalCourtHours,
    required int finalDaysActive,
    required int finalHealthScore,
    DateTime? createdAt,
  }) = _RestringEventImpl;

  factory RestringEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return RestringEvent(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      racquetId: jsonSerialization['racquetId'] as int,
      stringJobId: jsonSerialization['stringJobId'] as int,
      stringDescription: jsonSerialization['stringDescription'] as String,
      materialCategory: _i5v32zda.StringMaterialCategory.fromJson(
        (jsonSerialization['materialCategory'] as String),
      ),
      installedTension: (jsonSerialization['installedTension'] as num?)
          ?.toDouble(),
      stringingDate: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['stringingDate'],
      ),
      restringDate: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['restringDate'],
      ),
      finalCourtHours: (jsonSerialization['finalCourtHours'] as num).toDouble(),
      finalDaysActive: jsonSerialization['finalDaysActive'] as int,
      finalHealthScore: jsonSerialization['finalHealthScore'] as int,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int userId;

  int racquetId;

  int stringJobId;

  String stringDescription;

  _i5v32zda.StringMaterialCategory materialCategory;

  double? installedTension;

  DateTime stringingDate;

  DateTime restringDate;

  double finalCourtHours;

  int finalDaysActive;

  int finalHealthScore;

  DateTime createdAt;

  /// Returns a shallow copy of this [RestringEvent]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  RestringEvent copyWith({
    int? id,
    int? userId,
    int? racquetId,
    int? stringJobId,
    String? stringDescription,
    _i5v32zda.StringMaterialCategory? materialCategory,
    double? installedTension,
    DateTime? stringingDate,
    DateTime? restringDate,
    double? finalCourtHours,
    int? finalDaysActive,
    int? finalHealthScore,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RestringEvent',
      if (id != null) 'id': id,
      'userId': userId,
      'racquetId': racquetId,
      'stringJobId': stringJobId,
      'stringDescription': stringDescription,
      'materialCategory': materialCategory.toJson(),
      if (installedTension != null) 'installedTension': installedTension,
      'stringingDate': stringingDate.toJson(),
      'restringDate': restringDate.toJson(),
      'finalCourtHours': finalCourtHours,
      'finalDaysActive': finalDaysActive,
      'finalHealthScore': finalHealthScore,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RestringEvent',
      if (id != null) 'id': id,
      'userId': userId,
      'racquetId': racquetId,
      'stringJobId': stringJobId,
      'stringDescription': stringDescription,
      'materialCategory': materialCategory.toJson(),
      if (installedTension != null) 'installedTension': installedTension,
      'stringingDate': stringingDate.toJson(),
      'restringDate': restringDate.toJson(),
      'finalCourtHours': finalCourtHours,
      'finalDaysActive': finalDaysActive,
      'finalHealthScore': finalHealthScore,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RestringEventImpl extends RestringEvent {
  _RestringEventImpl({
    int? id,
    required int userId,
    required int racquetId,
    required int stringJobId,
    required String stringDescription,
    required _i5v32zda.StringMaterialCategory materialCategory,
    double? installedTension,
    required DateTime stringingDate,
    required DateTime restringDate,
    required double finalCourtHours,
    required int finalDaysActive,
    required int finalHealthScore,
    DateTime? createdAt,
  }) : super._(
         id: id,
         userId: userId,
         racquetId: racquetId,
         stringJobId: stringJobId,
         stringDescription: stringDescription,
         materialCategory: materialCategory,
         installedTension: installedTension,
         stringingDate: stringingDate,
         restringDate: restringDate,
         finalCourtHours: finalCourtHours,
         finalDaysActive: finalDaysActive,
         finalHealthScore: finalHealthScore,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [RestringEvent]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  RestringEvent copyWith({
    Object? id = _Undefined,
    int? userId,
    int? racquetId,
    int? stringJobId,
    String? stringDescription,
    _i5v32zda.StringMaterialCategory? materialCategory,
    Object? installedTension = _Undefined,
    DateTime? stringingDate,
    DateTime? restringDate,
    double? finalCourtHours,
    int? finalDaysActive,
    int? finalHealthScore,
    DateTime? createdAt,
  }) {
    return RestringEvent(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      racquetId: racquetId ?? this.racquetId,
      stringJobId: stringJobId ?? this.stringJobId,
      stringDescription: stringDescription ?? this.stringDescription,
      materialCategory: materialCategory ?? this.materialCategory,
      installedTension: installedTension is double?
          ? installedTension
          : this.installedTension,
      stringingDate: stringingDate ?? this.stringingDate,
      restringDate: restringDate ?? this.restringDate,
      finalCourtHours: finalCourtHours ?? this.finalCourtHours,
      finalDaysActive: finalDaysActive ?? this.finalDaysActive,
      finalHealthScore: finalHealthScore ?? this.finalHealthScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
