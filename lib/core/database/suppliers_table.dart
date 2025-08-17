import 'package:drift/drift.dart';

/// 供应商表
/// 存储供应商信息
class Supplier extends Table {
  /// 主键 - 供应商ID
  IntColumn get id => integer().autoIncrement()();

  /// 供应商名称
  TextColumn get name => text()();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 最后更新时间
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
