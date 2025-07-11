import 'package:drift/drift.dart';

/// 采购表
/// 存储采购单信息，包括采购单号、货品ID、单位ID、单价、数量、生产日期、店铺ID、供应商ID、采购日期等
class PurchasesTable extends Table {
  @override
  String get tableName => 'purchases';

  /// 主键 - 采购单号（系统自动生成）
  TextColumn get purchaseNumber => text().named('purchase_number')();

  /// 外键 - 货品ID
  TextColumn get productId => text().named('product_id')();

  /// 外键 - 单位ID
  TextColumn get unitId => text().named('unit_id')();

  /// 单价
  RealColumn get unitPrice => real().named('unit_price')();

  /// 数量
  RealColumn get quantity => real().named('quantity')();

  /// 生产日期
  DateTimeColumn get productionDate =>
      dateTime().named('production_date').nullable()();

  /// 外键 - 店铺ID
  TextColumn get shopId => text().named('shop_id')();

  /// 外键 - 供应商ID
  TextColumn get supplierId => text().named('supplier_id')();

  /// 采购日期
  DateTimeColumn get purchaseDate => dateTime().named('purchase_date')();

  /// 创建时间
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  /// 最后更新时间
  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {purchaseNumber};
}
