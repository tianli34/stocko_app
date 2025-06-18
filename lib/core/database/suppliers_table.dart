import 'package:drift/drift.dart';

/// 供应商表
/// 存储供应商信息
class SuppliersTable extends Table {
  @override
  String get tableName => 'suppliers';

  /// 主键 - 供应商ID
  TextColumn get id => text().named('id')();

  /// 供应商名称
  TextColumn get name => text().named('name')();

  /// 创建时间
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  /// 最后更新时间
  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
