import 'package:drift/drift.dart';

/// 店铺表
/// 存储店铺的基本信息
class ShopsTable extends Table {
  @override
  String get tableName => 'shops';

  /// 主键 - 店铺ID
  TextColumn get id => text().named('id')();

  /// 店铺名称
  TextColumn get name => text().named('name')();

  /// 店长
  TextColumn get manager => text().named('manager')();

  /// 创建时间
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  /// 最后更新时间
  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
