import 'package:drift/drift.dart';

/// 采购订单表
/// 存储采购订单的宏观信息，如供应商、店铺、采购日期等。
class PurchaseOrdersTable extends Table {
  @override
  String get tableName => 'purchase_orders';

  /// 主键 - 自增ID
  IntColumn get id => integer().autoIncrement()();

  /// 采购单号 (用于显示和搜索)
  TextColumn get purchaseOrderNumber =>
      text().named('purchase_order_number').unique()();

  /// 外键 - 供应商ID
  TextColumn get supplierId => text().named('supplier_id')();

  /// 外键 - 店铺ID
  TextColumn get shopId => text().named('shop_id')();

  /// 采购日期
  DateTimeColumn get purchaseDate => dateTime().named('purchase_date')();

  /// 订单状态 (可选, e.g., 'draft', 'completed')
  TextColumn get status =>
      text().named('status').withDefault(const Constant('draft'))();

  /// 创建时间
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  /// 最后更新时间
  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();
}
