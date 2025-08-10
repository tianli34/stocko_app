import 'package:drift/drift.dart';

/// 条码表
/// 存储产品单位对应的条码信息
class BarcodesTable extends Table {
  @override
  String get tableName => 'barcodes';

  /// 主键 - 条码ID
  TextColumn get id => text().named('id')();

  /// 外键 - 产品单位ID，关联到product_units表
  IntColumn get productUnitId => integer().named('product_unit_id')();

  /// 条码值
  TextColumn get barcode => text().named('barcode')();

  /// 创建时间
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  /// 最后更新时间
  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {barcode}, // 条码必须唯一
    {productUnitId, barcode}, // 同一产品单位的条码必须唯一
  ];
}
