import 'package:drift/drift.dart';

class ProductsTable extends Table {
  @override
  String get tableName => 'products';
  TextColumn get id => text()(); // 改为不可为空的主键
  TextColumn get name => text()(); // 名称必须
  TextColumn get sku => text().nullable()();
  TextColumn get image => text().nullable()(); // 图片
  TextColumn get categoryId => text().nullable()(); // 类别ID
  TextColumn get unitId => text().nullable()(); // 单位ID
  TextColumn get specification => text().nullable()(); // 型号/规格
  TextColumn get brand => text().nullable()(); // 品牌
  RealColumn get suggestedRetailPrice => real().nullable()(); // 建议零售价
  RealColumn get retailPrice => real().nullable()(); // 零售价
  RealColumn get promotionalPrice => real().nullable()(); // 促销价
  IntColumn get stockWarningValue => integer().nullable()(); // 库存预警值
  IntColumn get shelfLife => integer().nullable()(); // 保质期(天数)
  TextColumn get shelfLifeUnit =>
      text().withDefault(const Constant('months'))(); // 保质期单位
  BoolColumn get enableBatchManagement =>
      boolean().withDefault(const Constant(false))(); // 批量管理开关，默认为false
  TextColumn get status =>
      text().withDefault(const Constant('active'))(); // 状态，默认为 'active'
  TextColumn get remarks => text().nullable()(); // 备注
  DateTimeColumn get lastUpdated => dateTime().nullable()(); // 最后更新日期

  @override
  Set<Column> get primaryKey => {id};
}
