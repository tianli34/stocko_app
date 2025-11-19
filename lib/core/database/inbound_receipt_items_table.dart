import 'package:drift/drift.dart';
import 'product_units_table.dart';
import 'inbound_receipts_table.dart';
import 'batches_table.dart';

/// 入库单明细表
/// 存储入库单中的具体商品明细信息
class InboundItem extends Table {
  /// 主键 - 明细ID
  IntColumn get id => integer().autoIncrement()();

  /// 外键 - 入库单ID
  IntColumn get receiptId => integer().references(InboundReceipt, #id)();

  /// 外键 - 产品单位ID
  IntColumn get unitProductId => integer().references(UnitProduct, #id)();

  /// 批次号
  IntColumn get batchId => integer().references(ProductBatch, #id).nullable()();

  /// 入库数量
  IntColumn get quantity => integer()();
}
