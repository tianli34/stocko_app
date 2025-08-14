import 'package:drift/drift.dart';
import 'products_table.dart';
import 'shops_table.dart';
import 'batches_table.dart';

/// 库存流水表
/// 记录产品库存变动的历史记录
class InventoryTransaction extends Table {
  /// 主键 - 流水ID
  IntColumn get id => integer().autoIncrement()();

  /// 外键 - 产品ID
  IntColumn get productId => integer().references(Product, #id)();

  /// 流水类型（入库、出库等）
  TextColumn get transactionType => text()
      .named('type')
      .check(
        const CustomExpression<bool>(
          '"type" IN (\'in\', \'out\', \'adjust\', \'transfer\', \'return\')',
        ),
      )();

  /// 变动数量
  IntColumn get quantity => integer()();

  /// 外键 - 店铺ID
  TextColumn get shopId => text().references(ShopsTable, #id)();

  /// 外键 - 批次ID（可选）
  IntColumn get batchNumber =>
      integer().references(ProductBatch, #batchNumber).nullable()();

  /// 流水时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
