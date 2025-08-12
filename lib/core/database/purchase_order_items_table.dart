import 'package:drift/drift.dart';
import 'products_table.dart';
import 'purchase_orders_table.dart';
import 'units_table.dart';

/// 采购订单明细表
/// 存储采购订单中的具体货品信息
class PurchaseOrderItemsTable extends Table {
  @override
  String get tableName => 'purchase_order_items';

  /// 主键 - 自增ID
  IntColumn get id => integer().autoIncrement()();

  /// 外键 - 关联到采购订单表
  IntColumn get purchaseOrderId => integer()
      .named('purchase_order_id')
      .references(PurchaseOrdersTable, #id)();

  /// 外键 - 货品ID
  IntColumn get productId =>
      integer().named('product_id').references(Product, #id)();

  /// 外键 - 单位ID
  IntColumn get unitId => integer().named('unit_id').references(Unit, #id)();

  /// 单价
  RealColumn get unitPrice => real().named('unit_price')();

  /// 数量
  IntColumn get quantity => integer().named('quantity')();

  /// 生产日期
  DateTimeColumn get productionDate =>
      dateTime().named('production_date').nullable()();

  /// 创建时间
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  /// 最后更新时间
  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();
}
