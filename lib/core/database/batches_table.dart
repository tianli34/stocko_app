import 'package:drift/drift.dart';
import 'products_table.dart';
import 'shops_table.dart';

/// 批次表,不用表名 Batch，因为Batch 是 Drift 的保留字
class ProductBatch extends Table {
  /// 主键
  IntColumn get id => integer().autoIncrement()();

  /// 外键 - 货品ID
  IntColumn get productId => integer().references(
    Product,
    #id,
    onDelete: KeyAction.restrict,
    onUpdate: KeyAction.cascade,
  )();

  /// 生产日期
  DateTimeColumn get productionDate => dateTime()();

  /// 累计入库数量，非负，即同一批次的货品数量
  IntColumn get totalInboundQuantity =>
      integer().named('total_inbound_quantity')();

  /// 外键 - 店铺ID
  IntColumn get shopId => integer()
      .references(
        Shop,
        #id,
        onDelete: KeyAction.restrict,
        onUpdate: KeyAction.cascade,
      )();

  /// 创建时间（由数据库默认生成）
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 最后更新时间（注意：不会自动在更新时刷新，需要应用层或触发器维护）
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// 业务唯一键：同一店铺、同一产品、同一生产日期只能有一个批次
  @override
  List<Set<Column>> get uniqueKeys => [
    {productId, productionDate, shopId},
  ];

  /// 表级约束：数量非负
  @override
  List<String> get customConstraints => ['CHECK(total_inbound_quantity >= 0)'];
}
