import 'package:drift/drift.dart';
import 'products_table.dart';
import 'shops_table.dart';
import 'batches_table.dart';

/// 库存表
/// 存储产品在各店铺的库存信息
class Stock extends Table {
  /// 主键 - 库存ID
  IntColumn get id => integer().autoIncrement()();

  /// 外键 - 货品ID
  IntColumn get productId => integer().references(Product, #id)();

  /// 外键 - 批次号
  IntColumn get batchNumber =>
      integer().references(ProductBatch, #batchNumber).nullable()();

  /// 库存数量
  IntColumn get quantity => integer()();

  /// 外键 - 店铺ID
  TextColumn get shopId => text().references(ShopsTable, #id)();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 最后更新时间
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<String> get customConstraints => [
    // 1. 针对有批次号的库存：(产品, 店铺, 批次号) 联合唯一
    'UNIQUE (product_id, shop_id, batch_number) WHERE batch_number IS NOT NULL',
    // 2. 针对无批次号的库存：(产品, 店铺) 联合唯一
    'UNIQUE (product_id, shop_id) WHERE batch_number IS NULL',
  ];
}
