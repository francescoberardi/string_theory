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
import 'package:serverpod/serverpod.dart' as _is;

abstract class SessionLog
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
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
    required _is.UuidValue userId,
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
      userId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      racquetId: jsonSerialization['racquetId'] as int,
      startTime: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['startTime'],
      ),
      durationMinutes: jsonSerialization['durationMinutes'] as int,
      courtSurface: jsonSerialization['courtSurface'] as String?,
      notes: jsonSerialization['notes'] as String?,
      source: jsonSerialization['source'] as String,
      externalWorkoutId: jsonSerialization['externalWorkoutId'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = SessionLogTable();

  static const db = SessionLogRepository._();

  @override
  int? id;

  _is.UuidValue userId;

  int racquetId;

  DateTime startTime;

  int durationMinutes;

  String? courtSurface;

  String? notes;

  String source;

  String? externalWorkoutId;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [SessionLog]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SessionLog copyWith({
    int? id,
    _is.UuidValue? userId,
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

  static SessionLogInclude include() {
    return SessionLogInclude._();
  }

  static SessionLogIncludeList includeList({
    _is.WhereExpressionBuilder<SessionLogTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SessionLogTable>? orderBy,
    _is.OrderByListBuilder<SessionLogTable>? orderByList,
    SessionLogInclude? include,
  }) {
    return SessionLogIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SessionLog.t),
      orderByList: orderByList?.call(SessionLog.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SessionLogImpl extends SessionLog {
  _SessionLogImpl({
    int? id,
    required _is.UuidValue userId,
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
  @_is.useResult
  @override
  SessionLog copyWith({
    Object? id = _Undefined,
    _is.UuidValue? userId,
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

class SessionLogUpdateTable extends _is.UpdateTable<SessionLogTable> {
  SessionLogUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> userId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.userId,
        value,
      );

  _is.ColumnValue<int, int> racquetId(int value) => _is.ColumnValue(
    table.racquetId,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> startTime(DateTime value) =>
      _is.ColumnValue(
        table.startTime,
        value,
      );

  _is.ColumnValue<int, int> durationMinutes(int value) => _is.ColumnValue(
    table.durationMinutes,
    value,
  );

  _is.ColumnValue<String, String> courtSurface(String? value) =>
      _is.ColumnValue(
        table.courtSurface,
        value,
      );

  _is.ColumnValue<String, String> notes(String? value) => _is.ColumnValue(
    table.notes,
    value,
  );

  _is.ColumnValue<String, String> source(String value) => _is.ColumnValue(
    table.source,
    value,
  );

  _is.ColumnValue<String, String> externalWorkoutId(String? value) =>
      _is.ColumnValue(
        table.externalWorkoutId,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class SessionLogTable extends _is.Table<int?> {
  SessionLogTable({super.tableRelation}) : super(tableName: 'session_log') {
    updateTable = SessionLogUpdateTable(this);
    userId = _is.ColumnUuid(
      'userId',
      this,
    );
    racquetId = _is.ColumnInt(
      'racquetId',
      this,
    );
    startTime = _is.ColumnDateTime(
      'startTime',
      this,
    );
    durationMinutes = _is.ColumnInt(
      'durationMinutes',
      this,
    );
    courtSurface = _is.ColumnString(
      'courtSurface',
      this,
    );
    notes = _is.ColumnString(
      'notes',
      this,
    );
    source = _is.ColumnString(
      'source',
      this,
    );
    externalWorkoutId = _is.ColumnString(
      'externalWorkoutId',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final SessionLogUpdateTable updateTable;

  late final _is.ColumnUuid userId;

  late final _is.ColumnInt racquetId;

  late final _is.ColumnDateTime startTime;

  late final _is.ColumnInt durationMinutes;

  late final _is.ColumnString courtSurface;

  late final _is.ColumnString notes;

  late final _is.ColumnString source;

  late final _is.ColumnString externalWorkoutId;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    userId,
    racquetId,
    startTime,
    durationMinutes,
    courtSurface,
    notes,
    source,
    externalWorkoutId,
    createdAt,
  ];
}

class SessionLogInclude extends _is.IncludeObject {
  SessionLogInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => SessionLog.t;
}

class SessionLogIncludeList extends _is.IncludeList {
  SessionLogIncludeList._({
    _is.WhereExpressionBuilder<SessionLogTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SessionLog.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => SessionLog.t;
}

class SessionLogRepository {
  const SessionLogRepository._();

  /// Returns a list of [SessionLog]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<SessionLog>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SessionLogTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SessionLogTable>? orderBy,
    _is.OrderByListBuilder<SessionLogTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<SessionLog>(
      where: where?.call(SessionLog.t),
      orderBy: orderBy?.call(SessionLog.t),
      orderByList: orderByList?.call(SessionLog.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [SessionLog] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<SessionLog?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SessionLogTable>? where,
    int? offset,
    _is.OrderByBuilder<SessionLogTable>? orderBy,
    _is.OrderByListBuilder<SessionLogTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<SessionLog>(
      where: where?.call(SessionLog.t),
      orderBy: orderBy?.call(SessionLog.t),
      orderByList: orderByList?.call(SessionLog.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [SessionLog] by its [id] or null if no such row exists.
  Future<SessionLog?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<SessionLog>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [SessionLog]s in the list and returns the inserted rows.
  ///
  /// The returned [SessionLog]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SessionLog>> insert(
    _is.DatabaseSession session,
    List<SessionLog> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<SessionLog>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [SessionLog] and returns the inserted row.
  ///
  /// The returned [SessionLog] will have its `id` field set.
  Future<SessionLog> insertRow(
    _is.DatabaseSession session,
    SessionLog row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<SessionLog>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [SessionLog]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [SessionLog]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SessionLog>> upsert(
    _is.DatabaseSession session,
    List<SessionLog> rows, {
    required _is.ColumnSelections<SessionLogTable> conflictColumns,
    _is.ColumnSelections<SessionLogTable>? updateColumns,
    _is.WhereExpressionBuilder<SessionLogTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<SessionLog>(
      rows,
      conflictColumns: conflictColumns(SessionLog.t),
      updateColumns: updateColumns?.call(SessionLog.t),
      updateWhere: updateWhere?.call(SessionLog.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [SessionLog] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [SessionLog] will have its `id` field set.
  Future<SessionLog?> upsertRow(
    _is.DatabaseSession session,
    SessionLog row, {
    required _is.ColumnSelections<SessionLogTable> conflictColumns,
    _is.ColumnSelections<SessionLogTable>? updateColumns,
    _is.WhereExpressionBuilder<SessionLogTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<SessionLog>(
      row,
      conflictColumns: conflictColumns(SessionLog.t),
      updateColumns: updateColumns?.call(SessionLog.t),
      updateWhere: updateWhere?.call(SessionLog.t),
      transaction: transaction,
    );
  }

  /// Updates all [SessionLog]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SessionLog>> update(
    _is.DatabaseSession session,
    List<SessionLog> rows, {
    _is.ColumnSelections<SessionLogTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<SessionLog>(
      rows,
      columns: columns?.call(SessionLog.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [SessionLog]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SessionLog> updateRow(
    _is.DatabaseSession session,
    SessionLog row, {
    _is.ColumnSelections<SessionLogTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<SessionLog>(
      row,
      columns: columns?.call(SessionLog.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SessionLog] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SessionLog?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<SessionLogUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<SessionLog>(
      id,
      columnValues: columnValues(SessionLog.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SessionLog]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SessionLog>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<SessionLogUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<SessionLogTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SessionLogTable>? orderBy,
    _is.OrderByListBuilder<SessionLogTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<SessionLog>(
      columnValues: columnValues(SessionLog.t.updateTable),
      where: where(SessionLog.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SessionLog.t),
      orderByList: orderByList?.call(SessionLog.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [SessionLog]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SessionLog>> delete(
    _is.DatabaseSession session,
    List<SessionLog> rows, {
    _is.OrderByBuilder<SessionLogTable>? orderBy,
    _is.OrderByListBuilder<SessionLogTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<SessionLog>(
      rows,
      orderBy: orderBy?.call(SessionLog.t),
      orderByList: orderByList?.call(SessionLog.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [SessionLog].
  Future<SessionLog> deleteRow(
    _is.DatabaseSession session,
    SessionLog row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SessionLog>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SessionLog>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SessionLogTable> where,
    _is.OrderByBuilder<SessionLogTable>? orderBy,
    _is.OrderByListBuilder<SessionLogTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<SessionLog>(
      where: where(SessionLog.t),
      orderBy: orderBy?.call(SessionLog.t),
      orderByList: orderByList?.call(SessionLog.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SessionLogTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<SessionLog>(
      where: where?.call(SessionLog.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [SessionLog] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SessionLogTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<SessionLog>(
      where: where(SessionLog.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
