import 'package:drift/drift.dart';
import 'products_table.dart';
import 'units_table.dart';

/// 入库单明细表
/// 存储入库单中的具体商品明细信息
class InboundReceiptItemsTable extends Table {
  @override
  String get tableName => 'inbound_receipt_items';

  /// 主键 - 明细ID
  TextColumn get id => text().named('id')();

  /// 外键 - 入库单ID
  TextColumn get receiptId => text().named('receipt_id')();

  /// 外键 - 商品ID
  IntColumn get productId =>
      integer().named('product_id').references(Product, #id)();

  /// 本次入库数量
  IntColumn get quantity => integer().named('quantity')();

  /// 外键 - 单位ID（入库时使用的单位）
  IntColumn get unitId => integer().named('unit_id').references(Unit, #id)();

  /// 生产日期
  DateTimeColumn get productionDate =>
      dateTime().named('production_date').nullable()();

  /// 外键 - 货位ID（入库到的位置）
  TextColumn get locationId => text().named('location_id').nullable()();

  /// 采购数量（来自采购单的原始数量，用于显示对比）
  IntColumn get purchaseQuantity => integer().named('purchase_quantity').nullable()();

  /// 外键 - 采购单ID（如果来自采购单）
  TextColumn get purchaseOrderId =>
      text().named('purchase_order_id').nullable()();

  /// 批次号（如果商品启用批次管理）
  TextColumn get batchNumber => text().named('batch_number').nullable()();

  /// 创建时间
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  /// 最后更新时间
  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    // 同一入库单中，同一商品同一批次只能有一条记录
    {receiptId, productId, batchNumber},
  ];
}
