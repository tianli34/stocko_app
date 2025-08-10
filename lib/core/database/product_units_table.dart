import 'package:drift/drift.dart';
import 'products_table.dart';
import 'units_table.dart';

/// 产品单位关联表
/// 存储产品与单位的关联关系及换算率信息
class ProductUnit extends Table {
  /// 主键 - 产品单位ID
  IntColumn get productUnitId => integer().autoIncrement()();

  /// 外键 - 产品ID
  IntColumn get productId =>
      integer().named('product_id').references(ProductsTable, #id)();

  /// 外键 - 单位ID
  IntColumn get unitId => integer().named('unit_id').references(Unit, #id)();

  /// 换算率（相对于基础单位）
  IntColumn get conversionRate => integer().named('conversion_rate')();

  /// 售价（以分为单位存储，避免浮点数精度问题）
  IntColumn get sellingPriceInCents =>
      integer().named('selling_price_in_cents').nullable()();

  /// 批发价（以分为单位存储）
  IntColumn get wholesalePriceInCents =>
      integer().named('wholesale_price_in_cents').nullable()();

  /// 最后更新时间
  DateTimeColumn get lastUpdated =>
      dateTime().named('last_updated').withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {productId, unitId}, // 同一产品的同一单位只能有一个记录
  ];
}
