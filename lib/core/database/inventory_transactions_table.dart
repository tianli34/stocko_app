import 'package:drift/drift.dart';

/// 库存流水表
/// 记录产品库存变动的历史记录
class InventoryTransactionsTable extends Table {
  @override
  String get tableName => 'inventory_transactions';

  /// 主键 - 流水ID
  TextColumn get id => text().named('id')();

  /// 外键 - 产品ID
  TextColumn get productId => text().named('product_id')();

  /// 流水类型（入库、出库等）
  TextColumn get type => text().named('type')();

  /// 变动数量
  RealColumn get quantity => real().named('quantity')();

  /// 外键 - 店铺ID
  TextColumn get shopId => text().named('shop_id')();

  /// 外键 - 批次ID（可选）
  TextColumn get batchId => text().named('batch_id').nullable()();

  /// 操作时间
  DateTimeColumn get time => dateTime().named('time')();

  /// 创建时间
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
