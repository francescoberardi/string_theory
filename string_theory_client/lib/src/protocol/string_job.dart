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

abstract class StringJob
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  StringJob._({
    this.id,
    required this.userId,
    required this.racquetId,
    required this.materialCategory,
    this.brand,
    this.model,
    DateTime? stringingDate,
    this.installedTension,
    double? maxRatedHours,
    double? totalCourtHours,
    int? currentHealthScore,
    bool? isActive,
    DateTime? createdAt,
  }) : stringingDate = stringingDate ?? DateTime.now(),
       maxRatedHours = maxRatedHours ?? 20.0,
       totalCourtHours = totalCourtHours ?? 0.0,
       currentHealthScore = currentHealthScore ?? 100,
       isActive = isActive ?? true,
       createdAt = createdAt ?? DateTime.now();

  factory StringJob({
    int? id,
    required _isc.UuidValue userId,
    required int racquetId,
    required _i5v32zda.StringMaterialCategory materialCategory,
    String? brand,
    String? model,
    DateTime? stringingDate,
    double? installedTension,
    double? maxRatedHours,
    double? totalCourtHours,
    int? currentHealthScore,
    bool? isActive,
    DateTime? createdAt,
  }) = _StringJobImpl;

  factory StringJob.fromJson(Map<String, dynamic> jsonSerialization) {
    return StringJob(
      id: jsonSerialization['id'] as int?,
      userId: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      racquetId: jsonSerialization['racquetId'] as int,
      materialCategory: _i5v32zda.StringMaterialCategory.fromJson(
        (jsonSerialization['materialCategory'] as String),
      ),
      brand: jsonSerialization['brand'] as String?,
      model: jsonSerialization['model'] as String?,
      stringingDate: jsonSerialization['stringingDate'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['stringingDate'],
            ),
      installedTension: (jsonSerialization['installedTension'] as num?)
          ?.toDouble(),
      maxRatedHours: (jsonSerialization['maxRatedHours'] as num?)?.toDouble(),
      totalCourtHours: (jsonSerialization['totalCourtHours'] as num?)
          ?.toDouble(),
      currentHealthScore: jsonSerialization['currentHealthScore'] as int?,
      isActive: jsonSerialization['isActive'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['isActive']),
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

  _i5v32zda.StringMaterialCategory materialCategory;

  String? brand;

  String? model;

  DateTime stringingDate;

  double? installedTension;

  double maxRatedHours;

  double totalCourtHours;

  int currentHealthScore;

  bool isActive;

  DateTime createdAt;

  /// Returns a shallow copy of this [StringJob]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  StringJob copyWith({
    int? id,
    _isc.UuidValue? userId,
    int? racquetId,
    _i5v32zda.StringMaterialCategory? materialCategory,
    String? brand,
    String? model,
    DateTime? stringingDate,
    double? installedTension,
    double? maxRatedHours,
    double? totalCourtHours,
    int? currentHealthScore,
    bool? isActive,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StringJob',
      if (id != null) 'id': id,
      'userId': userId.toJson(),
      'racquetId': racquetId,
      'materialCategory': materialCategory.toJson(),
      if (brand != null) 'brand': brand,
      if (model != null) 'model': model,
      'stringingDate': stringingDate.toJson(),
      if (installedTension != null) 'installedTension': installedTension,
      'maxRatedHours': maxRatedHours,
      'totalCourtHours': totalCourtHours,
      'currentHealthScore': currentHealthScore,
      'isActive': isActive,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'StringJob',
      if (id != null) 'id': id,
      'userId': userId.toJson(),
      'racquetId': racquetId,
      'materialCategory': materialCategory.toJson(),
      if (brand != null) 'brand': brand,
      if (model != null) 'model': model,
      'stringingDate': stringingDate.toJson(),
      if (installedTension != null) 'installedTension': installedTension,
      'maxRatedHours': maxRatedHours,
      'totalCourtHours': totalCourtHours,
      'currentHealthScore': currentHealthScore,
      'isActive': isActive,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _StringJobImpl extends StringJob {
  _StringJobImpl({
    int? id,
    required _isc.UuidValue userId,
    required int racquetId,
    required _i5v32zda.StringMaterialCategory materialCategory,
    String? brand,
    String? model,
    DateTime? stringingDate,
    double? installedTension,
    double? maxRatedHours,
    double? totalCourtHours,
    int? currentHealthScore,
    bool? isActive,
    DateTime? createdAt,
  }) : super._(
         id: id,
         userId: userId,
         racquetId: racquetId,
         materialCategory: materialCategory,
         brand: brand,
         model: model,
         stringingDate: stringingDate,
         installedTension: installedTension,
         maxRatedHours: maxRatedHours,
         totalCourtHours: totalCourtHours,
         currentHealthScore: currentHealthScore,
         isActive: isActive,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [StringJob]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  StringJob copyWith({
    Object? id = _Undefined,
    _isc.UuidValue? userId,
    int? racquetId,
    _i5v32zda.StringMaterialCategory? materialCategory,
    Object? brand = _Undefined,
    Object? model = _Undefined,
    DateTime? stringingDate,
    Object? installedTension = _Undefined,
    double? maxRatedHours,
    double? totalCourtHours,
    int? currentHealthScore,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return StringJob(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      racquetId: racquetId ?? this.racquetId,
      materialCategory: materialCategory ?? this.materialCategory,
      brand: brand is String? ? brand : this.brand,
      model: model is String? ? model : this.model,
      stringingDate: stringingDate ?? this.stringingDate,
      installedTension: installedTension is double?
          ? installedTension
          : this.installedTension,
      maxRatedHours: maxRatedHours ?? this.maxRatedHours,
      totalCourtHours: totalCourtHours ?? this.totalCourtHours,
      currentHealthScore: currentHealthScore ?? this.currentHealthScore,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
