/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_null_comparison

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _is;
import 'package:string_theory_server/src/generated/protocol.dart' as _ir2u5021;
import 'string_job.dart' as _ipf7mlcg;

abstract class Racquet
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
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
    required int userId,
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
      userId: jsonSerialization['userId'] as int,
      name: jsonSerialization['name'] as String,
      brand: jsonSerialization['brand'] as String?,
      model: jsonSerialization['model'] as String?,
      isPrimary: jsonSerialization['isPrimary'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['isPrimary']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      activeStringJobId: jsonSerialization['activeStringJobId'] as int?,
      activeStringJob: jsonSerialization['activeStringJob'] == null
          ? null
          : _ir2u5021.Protocol().deserialize<_ipf7mlcg.StringJob>(
              jsonSerialization['activeStringJob'],
            ),
    );
  }

  static final t = RacquetTable();

  static const db = RacquetRepository._();

  @override
  int? id;

  int userId;

  String name;

  String? brand;

  String? model;

  bool isPrimary;

  DateTime createdAt;

  DateTime updatedAt;

  int? activeStringJobId;

  _ipf7mlcg.StringJob? activeStringJob;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Racquet]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Racquet copyWith({
    int? id,
    int? userId,
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
      'userId': userId,
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
      'userId': userId,
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

  static RacquetInclude include({_ipf7mlcg.StringJobInclude? activeStringJob}) {
    return RacquetInclude._(activeStringJob: activeStringJob);
  }

  static RacquetIncludeList includeList({
    _is.WhereExpressionBuilder<RacquetTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RacquetTable>? orderBy,
    _is.OrderByListBuilder<RacquetTable>? orderByList,
    RacquetInclude? include,
  }) {
    return RacquetIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Racquet.t),
      orderByList: orderByList?.call(Racquet.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RacquetImpl extends Racquet {
  _RacquetImpl({
    int? id,
    required int userId,
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
  @_is.useResult
  @override
  Racquet copyWith({
    Object? id = _Undefined,
    int? userId,
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

class RacquetUpdateTable extends _is.UpdateTable<RacquetTable> {
  RacquetUpdateTable(super.table);

  _is.ColumnValue<int, int> userId(int value) => _is.ColumnValue(
    table.userId,
    value,
  );

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<String, String> brand(String? value) => _is.ColumnValue(
    table.brand,
    value,
  );

  _is.ColumnValue<String, String> model(String? value) => _is.ColumnValue(
    table.model,
    value,
  );

  _is.ColumnValue<bool, bool> isPrimary(bool value) => _is.ColumnValue(
    table.isPrimary,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _is.ColumnValue(
        table.updatedAt,
        value,
      );

  _is.ColumnValue<int, int> activeStringJobId(int? value) => _is.ColumnValue(
    table.activeStringJobId,
    value,
  );
}

class RacquetTable extends _is.Table<int?> {
  RacquetTable({super.tableRelation}) : super(tableName: 'racquet') {
    updateTable = RacquetUpdateTable(this);
    userId = _is.ColumnInt(
      'userId',
      this,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    brand = _is.ColumnString(
      'brand',
      this,
    );
    model = _is.ColumnString(
      'model',
      this,
    );
    isPrimary = _is.ColumnBool(
      'isPrimary',
      this,
      hasDefault: true,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
      hasDefault: true,
    );
    activeStringJobId = _is.ColumnInt(
      'activeStringJobId',
      this,
    );
  }

  late final RacquetUpdateTable updateTable;

  late final _is.ColumnInt userId;

  late final _is.ColumnString name;

  late final _is.ColumnString brand;

  late final _is.ColumnString model;

  late final _is.ColumnBool isPrimary;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  late final _is.ColumnInt activeStringJobId;

  _ipf7mlcg.StringJobTable? _activeStringJob;

  _ipf7mlcg.StringJobTable get activeStringJob {
    if (_activeStringJob != null) return _activeStringJob!;
    _activeStringJob = _is.createRelationTable(
      relationFieldName: 'activeStringJob',
      field: Racquet.t.activeStringJobId,
      foreignField: _ipf7mlcg.StringJob.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _ipf7mlcg.StringJobTable(tableRelation: foreignTableRelation),
    );
    return _activeStringJob!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    userId,
    name,
    brand,
    model,
    isPrimary,
    createdAt,
    updatedAt,
    activeStringJobId,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'activeStringJob') {
      return activeStringJob;
    }
    return null;
  }
}

class RacquetInclude extends _is.IncludeObject {
  RacquetInclude._({_ipf7mlcg.StringJobInclude? activeStringJob}) {
    _activeStringJob = activeStringJob;
  }

  _ipf7mlcg.StringJobInclude? _activeStringJob;

  @override
  Map<String, _is.Include?> get includes => {
    'activeStringJob': _activeStringJob,
  };

  @override
  _is.Table<int?> get table => Racquet.t;
}

class RacquetIncludeList extends _is.IncludeList {
  RacquetIncludeList._({
    _is.WhereExpressionBuilder<RacquetTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Racquet.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Racquet.t;
}

class RacquetRepository {
  const RacquetRepository._();

  final attachRow = const RacquetAttachRowRepository._();

  final detachRow = const RacquetDetachRowRepository._();

  /// Returns a list of [Racquet]s matching the given query parameters.
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
  Future<List<Racquet>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RacquetTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RacquetTable>? orderBy,
    _is.OrderByListBuilder<RacquetTable>? orderByList,
    _is.Transaction? transaction,
    RacquetInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Racquet>(
      where: where?.call(Racquet.t),
      orderBy: orderBy?.call(Racquet.t),
      orderByList: orderByList?.call(Racquet.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Racquet] matching the given query parameters.
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
  Future<Racquet?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RacquetTable>? where,
    int? offset,
    _is.OrderByBuilder<RacquetTable>? orderBy,
    _is.OrderByListBuilder<RacquetTable>? orderByList,
    _is.Transaction? transaction,
    RacquetInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Racquet>(
      where: where?.call(Racquet.t),
      orderBy: orderBy?.call(Racquet.t),
      orderByList: orderByList?.call(Racquet.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Racquet] by its [id] or null if no such row exists.
  Future<Racquet?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    RacquetInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Racquet>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Racquet]s in the list and returns the inserted rows.
  ///
  /// The returned [Racquet]s will have their `id` fields set.
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
  Future<List<Racquet>> insert(
    _is.DatabaseSession session,
    List<Racquet> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Racquet>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Racquet] and returns the inserted row.
  ///
  /// The returned [Racquet] will have its `id` field set.
  Future<Racquet> insertRow(
    _is.DatabaseSession session,
    Racquet row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Racquet>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Racquet]s in the list and returns the resulting rows.
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
  /// The returned [Racquet]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Racquet>> upsert(
    _is.DatabaseSession session,
    List<Racquet> rows, {
    required _is.ColumnSelections<RacquetTable> conflictColumns,
    _is.ColumnSelections<RacquetTable>? updateColumns,
    _is.WhereExpressionBuilder<RacquetTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Racquet>(
      rows,
      conflictColumns: conflictColumns(Racquet.t),
      updateColumns: updateColumns?.call(Racquet.t),
      updateWhere: updateWhere?.call(Racquet.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Racquet] and returns the resulting row.
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
  /// The returned [Racquet] will have its `id` field set.
  Future<Racquet?> upsertRow(
    _is.DatabaseSession session,
    Racquet row, {
    required _is.ColumnSelections<RacquetTable> conflictColumns,
    _is.ColumnSelections<RacquetTable>? updateColumns,
    _is.WhereExpressionBuilder<RacquetTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Racquet>(
      row,
      conflictColumns: conflictColumns(Racquet.t),
      updateColumns: updateColumns?.call(Racquet.t),
      updateWhere: updateWhere?.call(Racquet.t),
      transaction: transaction,
    );
  }

  /// Updates all [Racquet]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Racquet>> update(
    _is.DatabaseSession session,
    List<Racquet> rows, {
    _is.ColumnSelections<RacquetTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Racquet>(
      rows,
      columns: columns?.call(Racquet.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Racquet]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Racquet> updateRow(
    _is.DatabaseSession session,
    Racquet row, {
    _is.ColumnSelections<RacquetTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Racquet>(
      row,
      columns: columns?.call(Racquet.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Racquet] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Racquet?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<RacquetUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Racquet>(
      id,
      columnValues: columnValues(Racquet.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Racquet]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Racquet>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<RacquetUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<RacquetTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RacquetTable>? orderBy,
    _is.OrderByListBuilder<RacquetTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Racquet>(
      columnValues: columnValues(Racquet.t.updateTable),
      where: where(Racquet.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Racquet.t),
      orderByList: orderByList?.call(Racquet.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Racquet]s in the list and returns the deleted rows.
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
  Future<List<Racquet>> delete(
    _is.DatabaseSession session,
    List<Racquet> rows, {
    _is.OrderByBuilder<RacquetTable>? orderBy,
    _is.OrderByListBuilder<RacquetTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Racquet>(
      rows,
      orderBy: orderBy?.call(Racquet.t),
      orderByList: orderByList?.call(Racquet.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Racquet].
  Future<Racquet> deleteRow(
    _is.DatabaseSession session,
    Racquet row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Racquet>(
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
  Future<List<Racquet>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<RacquetTable> where,
    _is.OrderByBuilder<RacquetTable>? orderBy,
    _is.OrderByListBuilder<RacquetTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Racquet>(
      where: where(Racquet.t),
      orderBy: orderBy?.call(Racquet.t),
      orderByList: orderByList?.call(Racquet.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RacquetTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Racquet>(
      where: where?.call(Racquet.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Racquet] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<RacquetTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Racquet>(
      where: where(Racquet.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class RacquetAttachRowRepository {
  const RacquetAttachRowRepository._();

  /// Creates a relation between the given [Racquet] and [StringJob]
  /// by setting the [Racquet]'s foreign key `activeStringJobId` to refer to the [StringJob].
  Future<void> activeStringJob(
    _is.DatabaseSession session,
    Racquet racquet,
    _ipf7mlcg.StringJob activeStringJob, {
    _is.Transaction? transaction,
  }) async {
    if (racquet.id == null) {
      throw ArgumentError.notNull('racquet.id');
    }
    if (activeStringJob.id == null) {
      throw ArgumentError.notNull('activeStringJob.id');
    }

    var $racquet = racquet.copyWith(activeStringJobId: activeStringJob.id);
    await session.db.updateRow<Racquet>(
      $racquet,
      columns: [Racquet.t.activeStringJobId],
      transaction: transaction,
    );
  }
}

class RacquetDetachRowRepository {
  const RacquetDetachRowRepository._();

  /// Detaches the relation between this [Racquet] and the [StringJob] set in `activeStringJob`
  /// by setting the [Racquet]'s foreign key `activeStringJobId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> activeStringJob(
    _is.DatabaseSession session,
    Racquet racquet, {
    _is.Transaction? transaction,
  }) async {
    if (racquet.id == null) {
      throw ArgumentError.notNull('racquet.id');
    }

    var $racquet = racquet.copyWith(activeStringJobId: null);
    await session.db.updateRow<Racquet>(
      $racquet,
      columns: [Racquet.t.activeStringJobId],
      transaction: transaction,
    );
  }
}
