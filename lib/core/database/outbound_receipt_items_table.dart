import 'package:drift/drift.dart';
import 'product_units_table.dart';
import 'outbound_receipts_table.dart';
import 'batches_table.dart';

/// 出库单明细表
/// 存储出库单中的具体商品明细信息
class OutboundItem extends Table {
  /// 主键 - 明细ID
  IntColumn get id => integer().autoIncrement()();

  /// 外键 - 出库单ID
  IntColumn get receiptId => integer().references(OutboundReceipt, #id)();

  /// 外键 - 产品单位ID
  IntColumn get unitProductId => integer().references(UnitProduct, #id)();

  /// 批次号
  IntColumn get batchId => integer().references(ProductBatch, #id).nullable()();

  /// 数量
  IntColumn get quantity => integer()();
}
