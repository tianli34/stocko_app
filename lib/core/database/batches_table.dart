import 'package:drift/drift.dart';

/// 批次表
/// 存储产品批次信息，包括批次号、生产日期、数量等
class BatchesTable extends Table {
  @override
  String get tableName => 'batches';

  /// 主键 - 批次号（系统自动生成的生产日期数字格式，如20250523）
  TextColumn get batchNumber => text().named('batch_number')();

  /// 生产日期
  DateTimeColumn get productionDate => dateTime().named('production_date')();

  /// 初始数量，同一批次可累加
  RealColumn get initialQuantity => real().named('initial_quantity')();

  /// 外键 - 店铺ID
  TextColumn get shopId => text().named('shop_id')();

  /// 外键 - 货品ID
  TextColumn get productId => text().named('product_id')();

  /// 创建时间
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  /// 最后更新时间
  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {batchNumber};
}
