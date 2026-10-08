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
import 'package:string_theory_client/src/protocol/protocol.dart' as _irphjejg;
import 'string_job.dart' as _ipf7mlcg;

abstract class Racquet
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Racquet._({
    this.id,
    required this.userId,
    required this.name,
    this.brand,
    this.model,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.activeStringJobId,
    this.activeStringJob,
  }) : isPrimary = isPrimary ?? false,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Racquet({
    int? id,
    required _isc.UuidValue userId,
    required String name,
    String? brand,
    String? model,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? activeStringJobId,
    _ipf7mlcg.StringJob? activeStringJob,
  }) = _RacquetImpl;

  factory Racquet.fromJson(Map<String, dynamic> jsonSerialization) {
    return Racquet(
      id: jsonSerialization['id'] as int?,
      userId: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      name: jsonSerialization['name'] as String,
      brand: jsonSerialization['brand'] as String?,
      model: jsonSerialization['model'] as String?,
      isPrimary: jsonSerialization['isPrimary'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['isPrimary']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      activeStringJobId: jsonSerialization['activeStringJobId'] as int?,
      activeStringJob: jsonSerialization['activeStringJob'] == null
          ? null
          : _irphjejg.Protocol().deserialize<_ipf7mlcg.StringJob>(
              jsonSerialization['activeStringJob'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  _isc.UuidValue userId;

  String name;

  String? brand;

  String? model;

  bool isPrimary;

  DateTime createdAt;

  DateTime updatedAt;

  int? activeStringJobId;

  _ipf7mlcg.StringJob? activeStringJob;

  /// Returns a shallow copy of this [Racquet]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Racquet copyWith({
    int? id,
    _isc.UuidValue? userId,
    String? name,
    String? brand,
    String? model,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? activeStringJobId,
    _ipf7mlcg.StringJob? activeStringJob,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Racquet',
      if (id != null) 'id': id,
      'userId': userId.toJson(),
      'name': name,
      if (brand != null) 'brand': brand,
      if (model != null) 'model': model,
      'isPrimary': isPrimary,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (activeStringJobId != null) 'activeStringJobId': activeStringJobId,
      if (activeStringJob != null) 'activeStringJob': activeStringJob?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Racquet',
      if (id != null) 'id': id,
      'userId': userId.toJson(),
      'name': name,
      if (brand != null) 'brand': brand,
      if (model != null) 'model': model,
      'isPrimary': isPrimary,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (activeStringJobId != null) 'activeStringJobId': activeStringJobId,
      if (activeStringJob != null)
        'activeStringJob': activeStringJob?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RacquetImpl extends Racquet {
  _RacquetImpl({
    int? id,
    required _isc.UuidValue userId,
    required String name,
    String? brand,
    String? model,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? activeStringJobId,
    _ipf7mlcg.StringJob? activeStringJob,
  }) : super._(
         id: id,
         userId: userId,
         name: name,
         brand: brand,
         model: model,
         isPrimary: isPrimary,
         createdAt: createdAt,
         updatedAt: updatedAt,
         activeStringJobId: activeStringJobId,
         activeStringJob: activeStringJob,
       );

  /// Returns a shallow copy of this [Racquet]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Racquet copyWith({
    Object? id = _Undefined,
    _isc.UuidValue? userId,
    String? name,
    Object? brand = _Undefined,
    Object? model = _Undefined,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? activeStringJobId = _Undefined,
    Object? activeStringJob = _Undefined,
  }) {
    return Racquet(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      brand: brand is String? ? brand : this.brand,
      model: model is String? ? model : this.model,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      activeStringJobId: activeStringJobId is int?
          ? activeStringJobId
          : this.activeStringJobId,
      activeStringJob: activeStringJob is _ipf7mlcg.StringJob?
          ? activeStringJob
          : this.activeStringJob?.copyWith(),
    );
  }
}
