import 'package:drift/drift.dart';

/// 单位表
/// 存储产品的计量单位信息
class UnitsTable extends Table {
  @override
  String get tableName => 'units';

  /// 主键 - 单位ID
  TextColumn get id => text().named('id')();

  /// 单位名称 (如: 个, 箱, 包, 公斤等)
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
