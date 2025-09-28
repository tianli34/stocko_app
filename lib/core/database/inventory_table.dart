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
  IntColumn get batchId =>
      integer().references(ProductBatch, #id).nullable()();

  /// 数量
  IntColumn get quantity => integer()();

  /// 移动加权平均单价（以分为单位）
  IntColumn get averageUnitPriceInCents => integer().withDefault(const Constant(0))();

  /// 外键 - 店铺ID
  IntColumn get shopId => integer().references(Shop, #id)();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 最后更新时间
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

}
