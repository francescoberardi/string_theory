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
import 'package:serverpod/protocol.dart' as _isp;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
import 'package:string_theory_server/src/generated/racquet.dart' as _iwugozzn;
import 'package:string_theory_server/src/generated/restring_event.dart'
    as _ired0jse;
import 'package:string_theory_server/src/generated/session_log.dart'
    as _iyc5nsr4;
import 'bag_exception.dart' as _ik2s0sst;
import 'bag_stream_message.dart' as _iwuh6un6;
import 'greetings/greeting.dart' as _izw8z7ou;
import 'racquet.dart' as _iiy1gsnd;
import 'restring_event.dart' as _i3zubmt5;
import 'session_log.dart' as _ijme2vd8;
import 'string_job.dart' as _ipf7mlcg;
import 'string_material_category.dart' as _i5v32zda;
export 'bag_exception.dart';
export 'bag_stream_message.dart';
export 'greetings/greeting.dart';
export 'racquet.dart';
export 'restring_event.dart';
export 'session_log.dart';
export 'string_job.dart';
export 'string_material_category.dart';

class Protocol extends _is.DatabaseSerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  static List<_isp.TableDefinition> get targetTableDefinitions => [
    _isp.TableDefinition(
      name: 'racquet',
      dartName: 'Racquet',
      schema: 'public',
      module: 'string_theory',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'brand',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'model',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'isPrimary',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'activeStringJobId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'racquet_fk_0',
          columns: ['activeStringJobId'],
          referenceTable: 'string_job',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'racquet_user_id_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'restring_event',
      dartName: 'RestringEvent',
      schema: 'public',
      module: 'string_theory',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'racquetId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'stringJobId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'stringDescription',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'materialCategory',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:StringMaterialCategory',
        ),
        _isp.ColumnDefinition(
          name: 'stringingDate',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'restringDate',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'finalCourtHours',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _isp.ColumnDefinition(
          name: 'finalDaysActive',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'finalHealthScore',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'restring_event_fk_0',
          columns: ['racquetId'],
          referenceTable: 'racquet',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'restring_event_fk_1',
          columns: ['stringJobId'],
          referenceTable: 'string_job',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'restring_event_user_id_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'restring_event_racquet_id_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'racquetId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'session_log',
      dartName: 'SessionLog',
      schema: 'public',
      module: 'string_theory',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'racquetId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'startTime',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'durationMinutes',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'courtSurface',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'notes',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'source',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'externalWorkoutId',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'session_log_fk_0',
          columns: ['racquetId'],
          referenceTable: 'racquet',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'session_log_user_id_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'session_log_racquet_id_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'racquetId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'session_log_external_id_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'externalWorkoutId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'string_job',
      dartName: 'StringJob',
      schema: 'public',
      module: 'string_theory',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'racquetId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'materialCategory',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:StringMaterialCategory',
        ),
        _isp.ColumnDefinition(
          name: 'brand',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'model',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'stringingDate',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'installedTension',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'maxRatedHours',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
          columnDefault: '20.0',
        ),
        _isp.ColumnDefinition(
          name: 'totalCourtHours',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
          columnDefault: '0.0',
        ),
        _isp.ColumnDefinition(
          name: 'currentHealthScore',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '100',
        ),
        _isp.ColumnDefinition(
          name: 'isActive',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'string_job_fk_0',
          columns: ['racquetId'],
          referenceTable: 'racquet',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'string_job_user_id_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'string_job_racquet_id_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'racquetId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._iais.Protocol.targetTableDefinitions,
    ..._iacs.Protocol.targetTableDefinitions,
    ..._isp.Protocol.targetTableDefinitions,
  ];

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
      } on _is.DeserializationClassNameNotFoundException catch (_) {
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
    if (t == _i3zubmt5.RestringEvent) {
      return _i3zubmt5.RestringEvent.fromJson(data) as T;
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
    if (t == _is.getType<_ik2s0sst.BagException?>()) {
      return (data != null ? _ik2s0sst.BagException.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iwuh6un6.BagStreamMessage?>()) {
      return (data != null ? _iwuh6un6.BagStreamMessage.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_izw8z7ou.Greeting?>()) {
      return (data != null ? _izw8z7ou.Greeting.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iiy1gsnd.Racquet?>()) {
      return (data != null ? _iiy1gsnd.Racquet.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i3zubmt5.RestringEvent?>()) {
      return (data != null ? _i3zubmt5.RestringEvent.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ijme2vd8.SessionLog?>()) {
      return (data != null ? _ijme2vd8.SessionLog.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ipf7mlcg.StringJob?>()) {
      return (data != null ? _ipf7mlcg.StringJob.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i5v32zda.StringMaterialCategory?>()) {
      return (data != null
              ? _i5v32zda.StringMaterialCategory.fromJson(data)
              : null)
          as T;
    }
    if (t == List<_iwugozzn.Racquet>) {
      return (data as List)
              .map((e) => deserialize<_iwugozzn.Racquet>(e))
              .toList()
          as T;
    }
    if (t == List<_ired0jse.RestringEvent>) {
      return (data as List)
              .map((e) => deserialize<_ired0jse.RestringEvent>(e))
              .toList()
          as T;
    }
    if (t == List<_iyc5nsr4.SessionLog>) {
      return (data as List)
              .map((e) => deserialize<_iyc5nsr4.SessionLog>(e))
              .toList()
          as T;
    }
    try {
      return _iais.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _iacs.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _isp.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _ik2s0sst.BagException => 'BagException',
      _iwuh6un6.BagStreamMessage => 'BagStreamMessage',
      _izw8z7ou.Greeting => 'Greeting',
      _iiy1gsnd.Racquet => 'Racquet',
      _i3zubmt5.RestringEvent => 'RestringEvent',
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
      case _i3zubmt5.RestringEvent():
        return 'RestringEvent';
      case _ijme2vd8.SessionLog():
        return 'SessionLog';
      case _ipf7mlcg.StringJob():
        return 'StringJob';
      case _i5v32zda.StringMaterialCategory():
        return 'StringMaterialCategory';
    }
    className = _iais.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _iacs.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    className = _isp.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.') ? className : 'serverpod.$className';
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
    if (dataClassName == 'RestringEvent') {
      return deserialize<_i3zubmt5.RestringEvent>(data['data']);
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
      return _iais.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _iacs.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _isp.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _iais.Protocol().registerHostProtocol('string_theory', this);
    _iacs.Protocol().registerHostProtocol('string_theory', this);
  }

  @override
  _is.Table? getTableForType(Type t) {
    {
      var table = _iais.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _iacs.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _isp.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _iiy1gsnd.Racquet:
        return _iiy1gsnd.Racquet.t;
      case _i3zubmt5.RestringEvent:
        return _i3zubmt5.RestringEvent.t;
      case _ijme2vd8.SessionLog:
        return _ijme2vd8.SessionLog.t;
      case _ipf7mlcg.StringJob:
        return _ipf7mlcg.StringJob.t;
    }
    return null;
  }

  @override
  List<_isp.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

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
      return _iais.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _iacs.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
