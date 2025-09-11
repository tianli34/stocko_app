import 'package:drift/drift.dart';
import 'shops_table.dart';
import 'purchase_orders_table.dart';

/// 入库单表
/// 存储入库单的基本信息
class InboundReceipt extends Table {
  /// 主键 - 入库单ID
  IntColumn get id => integer().autoIncrement()();

  /// 外键 - 店铺ID
  IntColumn get shopId => integer().references(Shop, #id)();

  /// 来源
  TextColumn get source => text()();

  /// 外键 - 采购单ID（如果来自采购单）
  IntColumn get purchaseOrderId =>
      integer().references(PurchaseOrder, #id).nullable()();

  /// 入库单状态：preset draft(草稿), completed(已完成)
  TextColumn get status => text().withDefault(const Constant('preset'))();

  /// 备注
  TextColumn get remarks => text().nullable()();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 最后更新时间
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
