import 'package:drift/drift.dart';
import 'products_table.dart';
import 'purchase_orders_table.dart';

/// 采购订单明细表
/// 存储采购订单中的具体货品信息
class PurchaseOrderItem extends Table {
  /// 主键 - 自增ID
  IntColumn get id => integer().autoIncrement()();

  /// 外键 - 关联到采购订单表
  IntColumn get purchaseOrderId =>
      integer().references(PurchaseOrder, #id, onDelete: KeyAction.cascade)();

  /// 外键 - 货品ID
  IntColumn get productId =>
      integer().references(Product, #id, onDelete: KeyAction.restrict)();

  /// 生产日期
  DateTimeColumn get productionDate => dateTime().nullable()();

  /// 单位价格（以分为单位）
  IntColumn get unitPriceInCents => integer()();

  /// 数量
  IntColumn get quantity => integer()();

  @override
  List<String> get customConstraints => [
        'CHECK(quantity >= 1)',
        'CHECK(unit_price_in_cents >= 0)',
      ];
}
