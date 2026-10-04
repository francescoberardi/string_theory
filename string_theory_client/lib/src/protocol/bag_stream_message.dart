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

/// Real-time bag update pushed to a user's `user_{userId}_bag` channel.
abstract class BagStreamMessage
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  BagStreamMessage._({
    required this.eventType,
    this.racquetId,
    this.healthScore,
    this.totalCourtHours,
    required this.timestamp,
  });

  factory BagStreamMessage({
    required String eventType,
    int? racquetId,
    int? healthScore,
    double? totalCourtHours,
    required DateTime timestamp,
  }) = _BagStreamMessageImpl;

  factory BagStreamMessage.fromJson(Map<String, dynamic> jsonSerialization) {
    return BagStreamMessage(
      eventType: jsonSerialization['eventType'] as String,
      racquetId: jsonSerialization['racquetId'] as int?,
      healthScore: jsonSerialization['healthScore'] as int?,
      totalCourtHours: (jsonSerialization['totalCourtHours'] as num?)
          ?.toDouble(),
      timestamp: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['timestamp'],
      ),
    );
  }

  /// Event kind, e.g. `sessionLogged` or `restrung`.
  String eventType;

  /// Racquet affected by the event.
  int? racquetId;

  /// New health score of the racquet's active string job.
  int? healthScore;

  /// New total court hours of the racquet's active string job.
  double? totalCourtHours;

  /// When the event happened (UTC).
  DateTime timestamp;

  /// Returns a shallow copy of this [BagStreamMessage]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  BagStreamMessage copyWith({
    String? eventType,
    int? racquetId,
    int? healthScore,
    double? totalCourtHours,
    DateTime? timestamp,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BagStreamMessage',
      'eventType': eventType,
      if (racquetId != null) 'racquetId': racquetId,
      if (healthScore != null) 'healthScore': healthScore,
      if (totalCourtHours != null) 'totalCourtHours': totalCourtHours,
      'timestamp': timestamp.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BagStreamMessage',
      'eventType': eventType,
      if (racquetId != null) 'racquetId': racquetId,
      if (healthScore != null) 'healthScore': healthScore,
      if (totalCourtHours != null) 'totalCourtHours': totalCourtHours,
      'timestamp': timestamp.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BagStreamMessageImpl extends BagStreamMessage {
  _BagStreamMessageImpl({
    required String eventType,
    int? racquetId,
    int? healthScore,
    double? totalCourtHours,
    required DateTime timestamp,
  }) : super._(
         eventType: eventType,
         racquetId: racquetId,
         healthScore: healthScore,
         totalCourtHours: totalCourtHours,
         timestamp: timestamp,
       );

  /// Returns a shallow copy of this [BagStreamMessage]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  BagStreamMessage copyWith({
    String? eventType,
    Object? racquetId = _Undefined,
    Object? healthScore = _Undefined,
    Object? totalCourtHours = _Undefined,
    DateTime? timestamp,
  }) {
    return BagStreamMessage(
      eventType: eventType ?? this.eventType,
      racquetId: racquetId is int? ? racquetId : this.racquetId,
      healthScore: healthScore is int? ? healthScore : this.healthScore,
      totalCourtHours: totalCourtHours is double?
          ? totalCourtHours
          : this.totalCourtHours,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
