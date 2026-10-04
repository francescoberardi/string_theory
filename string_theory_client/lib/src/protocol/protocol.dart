/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_type_check

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'package:string_theory_client/src/protocol/racquet.dart' as _ib48ci23;
import 'package:string_theory_client/src/protocol/session_log.dart'
    as _iz65gy0p;
import 'bag_exception.dart' as _ik2s0sst;
import 'bag_stream_message.dart' as _iwuh6un6;
import 'greetings/greeting.dart' as _izw8z7ou;
import 'racquet.dart' as _iiy1gsnd;
import 'session_log.dart' as _ijme2vd8;
import 'string_job.dart' as _ipf7mlcg;
import 'string_material_category.dart' as _i5v32zda;
export 'bag_exception.dart';
export 'bag_stream_message.dart';
export 'greetings/greeting.dart';
export 'racquet.dart';
export 'session_log.dart';
export 'string_job.dart';
export 'string_material_category.dart';
export 'client.dart';

class Protocol extends _isc.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on _isc.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _ik2s0sst.BagException) {
      return _ik2s0sst.BagException.fromJson(data) as T;
    }
    if (t == _iwuh6un6.BagStreamMessage) {
      return _iwuh6un6.BagStreamMessage.fromJson(data) as T;
    }
    if (t == _izw8z7ou.Greeting) {
      return _izw8z7ou.Greeting.fromJson(data) as T;
    }
    if (t == _iiy1gsnd.Racquet) {
      return _iiy1gsnd.Racquet.fromJson(data) as T;
    }
    if (t == _ijme2vd8.SessionLog) {
      return _ijme2vd8.SessionLog.fromJson(data) as T;
    }
    if (t == _ipf7mlcg.StringJob) {
      return _ipf7mlcg.StringJob.fromJson(data) as T;
    }
    if (t == _i5v32zda.StringMaterialCategory) {
      return _i5v32zda.StringMaterialCategory.fromJson(data) as T;
    }
    if (t == _isc.getType<_ik2s0sst.BagException?>()) {
      return (data != null ? _ik2s0sst.BagException.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iwuh6un6.BagStreamMessage?>()) {
      return (data != null ? _iwuh6un6.BagStreamMessage.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_izw8z7ou.Greeting?>()) {
      return (data != null ? _izw8z7ou.Greeting.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iiy1gsnd.Racquet?>()) {
      return (data != null ? _iiy1gsnd.Racquet.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ijme2vd8.SessionLog?>()) {
      return (data != null ? _ijme2vd8.SessionLog.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ipf7mlcg.StringJob?>()) {
      return (data != null ? _ipf7mlcg.StringJob.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i5v32zda.StringMaterialCategory?>()) {
      return (data != null
              ? _i5v32zda.StringMaterialCategory.fromJson(data)
              : null)
          as T;
    }
    if (t == List<_ib48ci23.Racquet>) {
      return (data as List)
              .map((e) => deserialize<_ib48ci23.Racquet>(e))
              .toList()
          as T;
    }
    if (t == List<_iz65gy0p.SessionLog>) {
      return (data as List)
              .map((e) => deserialize<_iz65gy0p.SessionLog>(e))
              .toList()
          as T;
    }
    try {
      return _iaic.Protocol().deserialize<T>(data, t);
    } on _isc.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _iacc.Protocol().deserialize<T>(data, t);
    } on _isc.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _ik2s0sst.BagException => 'BagException',
      _iwuh6un6.BagStreamMessage => 'BagStreamMessage',
      _izw8z7ou.Greeting => 'Greeting',
      _iiy1gsnd.Racquet => 'Racquet',
      _ijme2vd8.SessionLog => 'SessionLog',
      _ipf7mlcg.StringJob => 'StringJob',
      _i5v32zda.StringMaterialCategory => 'StringMaterialCategory',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst(
        'string_theory.',
        '',
      );
    }

    switch (data) {
      case _ik2s0sst.BagException():
        return 'BagException';
      case _iwuh6un6.BagStreamMessage():
        return 'BagStreamMessage';
      case _izw8z7ou.Greeting():
        return 'Greeting';
      case _iiy1gsnd.Racquet():
        return 'Racquet';
      case _ijme2vd8.SessionLog():
        return 'SessionLog';
      case _ipf7mlcg.StringJob():
        return 'StringJob';
      case _i5v32zda.StringMaterialCategory():
        return 'StringMaterialCategory';
    }
    className = _iaic.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _iacc.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'BagException') {
      return deserialize<_ik2s0sst.BagException>(data['data']);
    }
    if (dataClassName == 'BagStreamMessage') {
      return deserialize<_iwuh6un6.BagStreamMessage>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_izw8z7ou.Greeting>(data['data']);
    }
    if (dataClassName == 'Racquet') {
      return deserialize<_iiy1gsnd.Racquet>(data['data']);
    }
    if (dataClassName == 'SessionLog') {
      return deserialize<_ijme2vd8.SessionLog>(data['data']);
    }
    if (dataClassName == 'StringJob') {
      return deserialize<_ipf7mlcg.StringJob>(data['data']);
    }
    if (dataClassName == 'StringMaterialCategory') {
      return deserialize<_i5v32zda.StringMaterialCategory>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _iaic.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _iacc.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _iaic.Protocol().registerHostProtocol('string_theory', this);
    _iacc.Protocol().registerHostProtocol('string_theory', this);
  }

  @override
  String getModuleName() => 'string_theory';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _iaic.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _iacc.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
