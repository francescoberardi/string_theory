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
import 'string_material_category.dart' as _i5v32zda;

abstract class RestringEvent
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
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
    required _is.UuidValue userId,
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
      userId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      racquetId: jsonSerialization['racquetId'] as int,
      stringJobId: jsonSerialization['stringJobId'] as int,
      stringDescription: jsonSerialization['stringDescription'] as String,
      materialCategory: _i5v32zda.StringMaterialCategory.fromJson(
        (jsonSerialization['materialCategory'] as String),
      ),
      installedTension: (jsonSerialization['installedTension'] as num?)
          ?.toDouble(),
      stringingDate: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['stringingDate'],
      ),
      restringDate: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['restringDate'],
      ),
      finalCourtHours: (jsonSerialization['finalCourtHours'] as num).toDouble(),
      finalDaysActive: jsonSerialization['finalDaysActive'] as int,
      finalHealthScore: jsonSerialization['finalHealthScore'] as int,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = RestringEventTable();

  static const db = RestringEventRepository._();

  @override
  int? id;

  _is.UuidValue userId;

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

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [RestringEvent]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  RestringEvent copyWith({
    int? id,
    _is.UuidValue? userId,
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
      'userId': userId.toJson(),
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
      'userId': userId.toJson(),
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

  static RestringEventInclude include() {
    return RestringEventInclude._();
  }

  static RestringEventIncludeList includeList({
    _is.WhereExpressionBuilder<RestringEventTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RestringEventTable>? orderBy,
    _is.OrderByListBuilder<RestringEventTable>? orderByList,
    RestringEventInclude? include,
  }) {
    return RestringEventIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(RestringEvent.t),
      orderByList: orderByList?.call(RestringEvent.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RestringEventImpl extends RestringEvent {
  _RestringEventImpl({
    int? id,
    required _is.UuidValue userId,
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
  @_is.useResult
  @override
  RestringEvent copyWith({
    Object? id = _Undefined,
    _is.UuidValue? userId,
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

class RestringEventUpdateTable extends _is.UpdateTable<RestringEventTable> {
  RestringEventUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> userId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.userId,
        value,
      );

  _is.ColumnValue<int, int> racquetId(int value) => _is.ColumnValue(
    table.racquetId,
    value,
  );

  _is.ColumnValue<int, int> stringJobId(int value) => _is.ColumnValue(
    table.stringJobId,
    value,
  );

  _is.ColumnValue<String, String> stringDescription(String value) =>
      _is.ColumnValue(
        table.stringDescription,
        value,
      );

  _is.ColumnValue<
    _i5v32zda.StringMaterialCategory,
    _i5v32zda.StringMaterialCategory
  >
  materialCategory(_i5v32zda.StringMaterialCategory value) => _is.ColumnValue(
    table.materialCategory,
    value,
  );

  _is.ColumnValue<double, double> installedTension(double? value) =>
      _is.ColumnValue(
        table.installedTension,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> stringingDate(DateTime value) =>
      _is.ColumnValue(
        table.stringingDate,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> restringDate(DateTime value) =>
      _is.ColumnValue(
        table.restringDate,
        value,
      );

  _is.ColumnValue<double, double> finalCourtHours(double value) =>
      _is.ColumnValue(
        table.finalCourtHours,
        value,
      );

  _is.ColumnValue<int, int> finalDaysActive(int value) => _is.ColumnValue(
    table.finalDaysActive,
    value,
  );

  _is.ColumnValue<int, int> finalHealthScore(int value) => _is.ColumnValue(
    table.finalHealthScore,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class RestringEventTable extends _is.Table<int?> {
  RestringEventTable({super.tableRelation})
    : super(tableName: 'restring_event') {
    updateTable = RestringEventUpdateTable(this);
    userId = _is.ColumnUuid(
      'userId',
      this,
    );
    racquetId = _is.ColumnInt(
      'racquetId',
      this,
    );
    stringJobId = _is.ColumnInt(
      'stringJobId',
      this,
    );
    stringDescription = _is.ColumnString(
      'stringDescription',
      this,
    );
    materialCategory = _is.ColumnEnum(
      'materialCategory',
      this,
      _is.EnumSerialization.byName,
    );
    installedTension = _is.ColumnDouble(
      'installedTension',
      this,
    );
    stringingDate = _is.ColumnDateTime(
      'stringingDate',
      this,
    );
    restringDate = _is.ColumnDateTime(
      'restringDate',
      this,
    );
    finalCourtHours = _is.ColumnDouble(
      'finalCourtHours',
      this,
    );
    finalDaysActive = _is.ColumnInt(
      'finalDaysActive',
      this,
    );
    finalHealthScore = _is.ColumnInt(
      'finalHealthScore',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final RestringEventUpdateTable updateTable;

  late final _is.ColumnUuid userId;

  late final _is.ColumnInt racquetId;

  late final _is.ColumnInt stringJobId;

  late final _is.ColumnString stringDescription;

  late final _is.ColumnEnum<_i5v32zda.StringMaterialCategory> materialCategory;

  late final _is.ColumnDouble installedTension;

  late final _is.ColumnDateTime stringingDate;

  late final _is.ColumnDateTime restringDate;

  late final _is.ColumnDouble finalCourtHours;

  late final _is.ColumnInt finalDaysActive;

  late final _is.ColumnInt finalHealthScore;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    userId,
    racquetId,
    stringJobId,
    stringDescription,
    materialCategory,
    installedTension,
    stringingDate,
    restringDate,
    finalCourtHours,
    finalDaysActive,
    finalHealthScore,
    createdAt,
  ];
}

class RestringEventInclude extends _is.IncludeObject {
  RestringEventInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => RestringEvent.t;
}

class RestringEventIncludeList extends _is.IncludeList {
  RestringEventIncludeList._({
    _is.WhereExpressionBuilder<RestringEventTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(RestringEvent.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => RestringEvent.t;
}

class RestringEventRepository {
  const RestringEventRepository._();

  /// Returns a list of [RestringEvent]s matching the given query parameters.
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
  Future<List<RestringEvent>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RestringEventTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RestringEventTable>? orderBy,
    _is.OrderByListBuilder<RestringEventTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<RestringEvent>(
      where: where?.call(RestringEvent.t),
      orderBy: orderBy?.call(RestringEvent.t),
      orderByList: orderByList?.call(RestringEvent.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [RestringEvent] matching the given query parameters.
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
  Future<RestringEvent?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RestringEventTable>? where,
    int? offset,
    _is.OrderByBuilder<RestringEventTable>? orderBy,
    _is.OrderByListBuilder<RestringEventTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<RestringEvent>(
      where: where?.call(RestringEvent.t),
      orderBy: orderBy?.call(RestringEvent.t),
      orderByList: orderByList?.call(RestringEvent.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [RestringEvent] by its [id] or null if no such row exists.
  Future<RestringEvent?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<RestringEvent>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [RestringEvent]s in the list and returns the inserted rows.
  ///
  /// The returned [RestringEvent]s will have their `id` fields set.
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
  Future<List<RestringEvent>> insert(
    _is.DatabaseSession session,
    List<RestringEvent> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<RestringEvent>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [RestringEvent] and returns the inserted row.
  ///
  /// The returned [RestringEvent] will have its `id` field set.
  Future<RestringEvent> insertRow(
    _is.DatabaseSession session,
    RestringEvent row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<RestringEvent>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [RestringEvent]s in the list and returns the resulting rows.
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
  /// The returned [RestringEvent]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<RestringEvent>> upsert(
    _is.DatabaseSession session,
    List<RestringEvent> rows, {
    required _is.ColumnSelections<RestringEventTable> conflictColumns,
    _is.ColumnSelections<RestringEventTable>? updateColumns,
    _is.WhereExpressionBuilder<RestringEventTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<RestringEvent>(
      rows,
      conflictColumns: conflictColumns(RestringEvent.t),
      updateColumns: updateColumns?.call(RestringEvent.t),
      updateWhere: updateWhere?.call(RestringEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [RestringEvent] and returns the resulting row.
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
  /// The returned [RestringEvent] will have its `id` field set.
  Future<RestringEvent?> upsertRow(
    _is.DatabaseSession session,
    RestringEvent row, {
    required _is.ColumnSelections<RestringEventTable> conflictColumns,
    _is.ColumnSelections<RestringEventTable>? updateColumns,
    _is.WhereExpressionBuilder<RestringEventTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<RestringEvent>(
      row,
      conflictColumns: conflictColumns(RestringEvent.t),
      updateColumns: updateColumns?.call(RestringEvent.t),
      updateWhere: updateWhere?.call(RestringEvent.t),
      transaction: transaction,
    );
  }

  /// Updates all [RestringEvent]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<RestringEvent>> update(
    _is.DatabaseSession session,
    List<RestringEvent> rows, {
    _is.ColumnSelections<RestringEventTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<RestringEvent>(
      rows,
      columns: columns?.call(RestringEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [RestringEvent]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<RestringEvent> updateRow(
    _is.DatabaseSession session,
    RestringEvent row, {
    _is.ColumnSelections<RestringEventTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<RestringEvent>(
      row,
      columns: columns?.call(RestringEvent.t),
      transaction: transaction,
    );
  }

  /// Updates a single [RestringEvent] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<RestringEvent?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<RestringEventUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<RestringEvent>(
      id,
      columnValues: columnValues(RestringEvent.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [RestringEvent]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<RestringEvent>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<RestringEventUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<RestringEventTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RestringEventTable>? orderBy,
    _is.OrderByListBuilder<RestringEventTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<RestringEvent>(
      columnValues: columnValues(RestringEvent.t.updateTable),
      where: where(RestringEvent.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(RestringEvent.t),
      orderByList: orderByList?.call(RestringEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [RestringEvent]s in the list and returns the deleted rows.
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
  Future<List<RestringEvent>> delete(
    _is.DatabaseSession session,
    List<RestringEvent> rows, {
    _is.OrderByBuilder<RestringEventTable>? orderBy,
    _is.OrderByListBuilder<RestringEventTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<RestringEvent>(
      rows,
      orderBy: orderBy?.call(RestringEvent.t),
      orderByList: orderByList?.call(RestringEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [RestringEvent].
  Future<RestringEvent> deleteRow(
    _is.DatabaseSession session,
    RestringEvent row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<RestringEvent>(
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
  Future<List<RestringEvent>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<RestringEventTable> where,
    _is.OrderByBuilder<RestringEventTable>? orderBy,
    _is.OrderByListBuilder<RestringEventTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<RestringEvent>(
      where: where(RestringEvent.t),
      orderBy: orderBy?.call(RestringEvent.t),
      orderByList: orderByList?.call(RestringEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RestringEventTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<RestringEvent>(
      where: where?.call(RestringEvent.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [RestringEvent] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<RestringEventTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<RestringEvent>(
      where: where(RestringEvent.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
