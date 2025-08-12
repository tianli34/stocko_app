import 'package:drift/drift.dart';
import 'products_table.dart';
import 'units_table.dart';

/// 货品供应商关联表
/// 建立商品和供应商之间的多对多关系
class ProductSuppliersTable extends Table {
  @override
  String get tableName => 'product_suppliers';

  /// 主键 - 关联ID
  TextColumn get id => text().named('id')();

  /// 商品ID - 外键关联到products表
  IntColumn get productId =>
      integer().named('product_id').references(Product, #id)();

  /// 供应商ID - 外键关联到suppliers表
  TextColumn get supplierId => text().named('supplier_id')();

  /// 单位ID - 外键关联到units表，指定供货单位
  IntColumn get unitId => integer().named('unit_id').references(Unit, #id)();

  /// 供应商商品编号/型号
  TextColumn get supplierProductCode =>
      text().named('supplier_product_code').nullable()();

  /// 供应商商品名称
  TextColumn get supplierProductName =>
      text().named('supplier_product_name').nullable()();

  /// 供货价格
  RealColumn get supplyPrice => real().named('supply_price').nullable()();

  /// 最小订购量
  IntColumn get minimumOrderQuantity =>
      integer().named('minimum_order_quantity').nullable()();

  /// 供货周期（天数）
  IntColumn get leadTimeDays => integer().named('lead_time_days').nullable()();

  /// 是否为主要供应商
  BoolColumn get isPrimary =>
      boolean().named('is_primary').withDefault(const Constant(false))();

  /// 状态：active-有效，inactive-无效
  TextColumn get status =>
      text().named('status').withDefault(const Constant('active'))();

  /// 备注
  TextColumn get remarks => text().named('remarks').nullable()();

  /// 创建时间
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  /// 最后更新时间
  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  /// 创建联合唯一索引，确保同一商品的同一供应商同一单位只能有一条记录
  @override
  List<Set<Column>> get uniqueKeys => [
    {productId, supplierId, unitId},
  ];
}
