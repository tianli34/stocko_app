import 'package:drift/drift.dart';

/// 产品单位关联表
/// 存储产品与单位的关联关系及换算率信息
class ProductUnitsTable extends Table {
  @override
  String get tableName => 'product_units';

  /// 主键 - 产品单位ID
  TextColumn get productUnitId => text().named('product_unit_id')();

  /// 外键 - 产品ID
  TextColumn get productId => text().named('product_id')();

  /// 外键 - 单位ID
  TextColumn get unitId => text().named('unit_id')();

  /// 换算率（相对于基础单位）
  RealColumn get conversionRate => real().named('conversion_rate')();

  /// 条码（可选）- 该包装单位的专用条码
  TextColumn get barcode => text().named('barcode').nullable()();

  /// 售价（可选）
  RealColumn get sellingPrice => real().named('selling_price').nullable()();

  /// 最后更新时间
  DateTimeColumn get lastUpdated =>
      dateTime().named('last_updated').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {productUnitId};

  @override
  List<Set<Column>> get uniqueKeys => [
    {productId, unitId}, // 同一产品的同一单位只能有一个记录
  ];
}
