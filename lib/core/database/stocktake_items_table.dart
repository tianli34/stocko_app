import 'package:drift/drift.dart';
import 'stocktake_orders_table.dart';
import 'products_table.dart';
import 'batches_table.dart';

/// 盘点明细表
class StocktakeItem extends Table {
  /// 主键
  IntColumn get id => integer().autoIncrement()();

  /// 外键 - 盘点单ID
  IntColumn get stocktakeId => integer().references(
        StocktakeOrder,
        #id,
        onDelete: KeyAction.cascade,
      )();

  /// 外键 - 商品ID
  IntColumn get productId => integer().references(Product, #id)();

  /// 外键 - 批次ID (可选)
  IntColumn get batchId =>
      integer().references(ProductBatch, #id).nullable()();

  /// 系统库存数量
  IntColumn get systemQuantity => integer()();

  /// 实际盘点数量
  IntColumn get actualQuantity => integer()();

  /// 差异数量 (actual - system)
  IntColumn get differenceQty => integer().withDefault(const Constant(0))();

  /// 差异原因
  TextColumn get differenceReason => text().nullable()();

  /// 是否已调整库存
  BoolColumn get isAdjusted =>
      boolean().withDefault(const Constant(false))();

  /// 扫描/录入时间
  DateTimeColumn get scannedAt => dateTime().withDefault(currentDateAndTime)();

  /// 唯一约束：同一盘点单中，同一商品+批次只能有一条记录
  @override
  List<Set<Column>> get uniqueKeys => [
        {stocktakeId, productId, batchId},
      ];
}
