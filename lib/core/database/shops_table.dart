import 'package:drift/drift.dart';

/// 店铺表
/// 存储店铺的基本信息
class Shop extends Table {
  /// 主键 - 店铺ID
  IntColumn get id => integer().autoIncrement()();

  /// 店铺名称
  TextColumn get name => text()();

  /// 店长
  TextColumn get manager => text()();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 最后更新时间
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
