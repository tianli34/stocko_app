import 'package:drift/drift.dart';

/// 库存表
/// 存储产品在各店铺的库存信息
class InventoryTable extends Table {
  @override
  String get tableName => 'inventory';

  /// 主键 - 库存ID
  TextColumn get id => text().named('id')();

  /// 外键 - 货品ID
  TextColumn get productId => text().named('product_id')();

  /// 库存数量
  RealColumn get quantity => real().named('quantity')();

  /// 外键 - 店铺ID
  TextColumn get shopId => text().named('shop_id')();

  /// 外键 - 批次号
  TextColumn get batchNumber => text().named('batch_number')();

  /// 创建时间
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  /// 最后更新时间
  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
