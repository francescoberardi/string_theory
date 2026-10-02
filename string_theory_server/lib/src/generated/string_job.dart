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

abstract class StringJob
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
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
    required int userId,
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
      userId: jsonSerialization['userId'] as int,
      racquetId: jsonSerialization['racquetId'] as int,
      materialCategory: _i5v32zda.StringMaterialCategory.fromJson(
        (jsonSerialization['materialCategory'] as String),
      ),
      brand: jsonSerialization['brand'] as String?,
      model: jsonSerialization['model'] as String?,
      stringingDate: jsonSerialization['stringingDate'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
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
          : _is.BoolJsonExtension.fromJson(jsonSerialization['isActive']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = StringJobTable();

  static const db = StringJobRepository._();

  @override
  int? id;

  int userId;

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

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [StringJob]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  StringJob copyWith({
    int? id,
    int? userId,
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
      'userId': userId,
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
      'userId': userId,
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

  static StringJobInclude include() {
    return StringJobInclude._();
  }

  static StringJobIncludeList includeList({
    _is.WhereExpressionBuilder<StringJobTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<StringJobTable>? orderBy,
    _is.OrderByListBuilder<StringJobTable>? orderByList,
    StringJobInclude? include,
  }) {
    return StringJobIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(StringJob.t),
      orderByList: orderByList?.call(StringJob.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _StringJobImpl extends StringJob {
  _StringJobImpl({
    int? id,
    required int userId,
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
  @_is.useResult
  @override
  StringJob copyWith({
    Object? id = _Undefined,
    int? userId,
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

class StringJobUpdateTable extends _is.UpdateTable<StringJobTable> {
  StringJobUpdateTable(super.table);

  _is.ColumnValue<int, int> userId(int value) => _is.ColumnValue(
    table.userId,
    value,
  );

  _is.ColumnValue<int, int> racquetId(int value) => _is.ColumnValue(
    table.racquetId,
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

  _is.ColumnValue<String, String> brand(String? value) => _is.ColumnValue(
    table.brand,
    value,
  );

  _is.ColumnValue<String, String> model(String? value) => _is.ColumnValue(
    table.model,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> stringingDate(DateTime value) =>
      _is.ColumnValue(
        table.stringingDate,
        value,
      );

  _is.ColumnValue<double, double> installedTension(double? value) =>
      _is.ColumnValue(
        table.installedTension,
        value,
      );

  _is.ColumnValue<double, double> maxRatedHours(double value) =>
      _is.ColumnValue(
        table.maxRatedHours,
        value,
      );

  _is.ColumnValue<double, double> totalCourtHours(double value) =>
      _is.ColumnValue(
        table.totalCourtHours,
        value,
      );

  _is.ColumnValue<int, int> currentHealthScore(int value) => _is.ColumnValue(
    table.currentHealthScore,
    value,
  );

  _is.ColumnValue<bool, bool> isActive(bool value) => _is.ColumnValue(
    table.isActive,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class StringJobTable extends _is.Table<int?> {
  StringJobTable({super.tableRelation}) : super(tableName: 'string_job') {
    updateTable = StringJobUpdateTable(this);
    userId = _is.ColumnInt(
      'userId',
      this,
    );
    racquetId = _is.ColumnInt(
      'racquetId',
      this,
    );
    materialCategory = _is.ColumnEnum(
      'materialCategory',
      this,
      _is.EnumSerialization.byName,
    );
    brand = _is.ColumnString(
      'brand',
      this,
    );
    model = _is.ColumnString(
      'model',
      this,
    );
    stringingDate = _is.ColumnDateTime(
      'stringingDate',
      this,
      hasDefault: true,
    );
    installedTension = _is.ColumnDouble(
      'installedTension',
      this,
    );
    maxRatedHours = _is.ColumnDouble(
      'maxRatedHours',
      this,
      hasDefault: true,
    );
    totalCourtHours = _is.ColumnDouble(
      'totalCourtHours',
      this,
      hasDefault: true,
    );
    currentHealthScore = _is.ColumnInt(
      'currentHealthScore',
      this,
      hasDefault: true,
    );
    isActive = _is.ColumnBool(
      'isActive',
      this,
      hasDefault: true,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final StringJobUpdateTable updateTable;

  late final _is.ColumnInt userId;

  late final _is.ColumnInt racquetId;

  late final _is.ColumnEnum<_i5v32zda.StringMaterialCategory> materialCategory;

  late final _is.ColumnString brand;

  late final _is.ColumnString model;

  late final _is.ColumnDateTime stringingDate;

  late final _is.ColumnDouble installedTension;

  late final _is.ColumnDouble maxRatedHours;

  late final _is.ColumnDouble totalCourtHours;

  late final _is.ColumnInt currentHealthScore;

  late final _is.ColumnBool isActive;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    userId,
    racquetId,
    materialCategory,
    brand,
    model,
    stringingDate,
    installedTension,
    maxRatedHours,
    totalCourtHours,
    currentHealthScore,
    isActive,
    createdAt,
  ];
}

class StringJobInclude extends _is.IncludeObject {
  StringJobInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => StringJob.t;
}

class StringJobIncludeList extends _is.IncludeList {
  StringJobIncludeList._({
    _is.WhereExpressionBuilder<StringJobTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(StringJob.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => StringJob.t;
}

class StringJobRepository {
  const StringJobRepository._();

  /// Returns a list of [StringJob]s matching the given query parameters.
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
  Future<List<StringJob>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<StringJobTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<StringJobTable>? orderBy,
    _is.OrderByListBuilder<StringJobTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<StringJob>(
      where: where?.call(StringJob.t),
      orderBy: orderBy?.call(StringJob.t),
      orderByList: orderByList?.call(StringJob.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [StringJob] matching the given query parameters.
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
  Future<StringJob?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<StringJobTable>? where,
    int? offset,
    _is.OrderByBuilder<StringJobTable>? orderBy,
    _is.OrderByListBuilder<StringJobTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<StringJob>(
      where: where?.call(StringJob.t),
      orderBy: orderBy?.call(StringJob.t),
      orderByList: orderByList?.call(StringJob.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [StringJob] by its [id] or null if no such row exists.
  Future<StringJob?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<StringJob>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [StringJob]s in the list and returns the inserted rows.
  ///
  /// The returned [StringJob]s will have their `id` fields set.
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
  Future<List<StringJob>> insert(
    _is.DatabaseSession session,
    List<StringJob> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<StringJob>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [StringJob] and returns the inserted row.
  ///
  /// The returned [StringJob] will have its `id` field set.
  Future<StringJob> insertRow(
    _is.DatabaseSession session,
    StringJob row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<StringJob>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [StringJob]s in the list and returns the resulting rows.
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
  /// The returned [StringJob]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<StringJob>> upsert(
    _is.DatabaseSession session,
    List<StringJob> rows, {
    required _is.ColumnSelections<StringJobTable> conflictColumns,
    _is.ColumnSelections<StringJobTable>? updateColumns,
    _is.WhereExpressionBuilder<StringJobTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<StringJob>(
      rows,
      conflictColumns: conflictColumns(StringJob.t),
      updateColumns: updateColumns?.call(StringJob.t),
      updateWhere: updateWhere?.call(StringJob.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [StringJob] and returns the resulting row.
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
  /// The returned [StringJob] will have its `id` field set.
  Future<StringJob?> upsertRow(
    _is.DatabaseSession session,
    StringJob row, {
    required _is.ColumnSelections<StringJobTable> conflictColumns,
    _is.ColumnSelections<StringJobTable>? updateColumns,
    _is.WhereExpressionBuilder<StringJobTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<StringJob>(
      row,
      conflictColumns: conflictColumns(StringJob.t),
      updateColumns: updateColumns?.call(StringJob.t),
      updateWhere: updateWhere?.call(StringJob.t),
      transaction: transaction,
    );
  }

  /// Updates all [StringJob]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<StringJob>> update(
    _is.DatabaseSession session,
    List<StringJob> rows, {
    _is.ColumnSelections<StringJobTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<StringJob>(
      rows,
      columns: columns?.call(StringJob.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [StringJob]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<StringJob> updateRow(
    _is.DatabaseSession session,
    StringJob row, {
    _is.ColumnSelections<StringJobTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<StringJob>(
      row,
      columns: columns?.call(StringJob.t),
      transaction: transaction,
    );
  }

  /// Updates a single [StringJob] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<StringJob?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<StringJobUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<StringJob>(
      id,
      columnValues: columnValues(StringJob.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [StringJob]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<StringJob>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<StringJobUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<StringJobTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<StringJobTable>? orderBy,
    _is.OrderByListBuilder<StringJobTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<StringJob>(
      columnValues: columnValues(StringJob.t.updateTable),
      where: where(StringJob.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(StringJob.t),
      orderByList: orderByList?.call(StringJob.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [StringJob]s in the list and returns the deleted rows.
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
  Future<List<StringJob>> delete(
    _is.DatabaseSession session,
    List<StringJob> rows, {
    _is.OrderByBuilder<StringJobTable>? orderBy,
    _is.OrderByListBuilder<StringJobTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<StringJob>(
      rows,
      orderBy: orderBy?.call(StringJob.t),
      orderByList: orderByList?.call(StringJob.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [StringJob].
  Future<StringJob> deleteRow(
    _is.DatabaseSession session,
    StringJob row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<StringJob>(
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
  Future<List<StringJob>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<StringJobTable> where,
    _is.OrderByBuilder<StringJobTable>? orderBy,
    _is.OrderByListBuilder<StringJobTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<StringJob>(
      where: where(StringJob.t),
      orderBy: orderBy?.call(StringJob.t),
      orderByList: orderByList?.call(StringJob.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<StringJobTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<StringJob>(
      where: where?.call(StringJob.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [StringJob] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<StringJobTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<StringJob>(
      where: where(StringJob.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
