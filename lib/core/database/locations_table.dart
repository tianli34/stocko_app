import 'package:drift/drift.dart';

/// 货位表
/// 存储仓库货位信息
class LocationsTable extends Table {
  @override
  String get tableName => 'locations';

  /// 主键 - 货位ID
  TextColumn get id => text().named('id')();

  /// 货位编码（如：A-01-01）
  TextColumn get code => text().named('code').unique()();

  /// 货位名称
  TextColumn get name => text().named('name')();

  /// 货位描述
  TextColumn get description => text().named('description').nullable()();

  /// 外键 - 店铺ID
  TextColumn get shopId => text().named('shop_id')();

  /// 货位状态：active(活跃), inactive(停用)
  TextColumn get status =>
      text().named('status').withDefault(const Constant('active'))();

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
    // 同一店铺内货位编码唯一
    {shopId, code},
  ];
}
