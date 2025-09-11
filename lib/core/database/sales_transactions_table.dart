import 'package:drift/drift.dart';
import 'customers_table.dart';
import 'shops_table.dart';

/// 销售交易表
class SalesTransaction extends Table {
  /// 主键 - 自增ID
  IntColumn get id => integer().autoIncrement()();

  /// 客户ID
  IntColumn get customerId => integer().references(Customers, #id)();

  /// 店铺ID
  IntColumn get shopId => integer().references(Shop, #id)();

  /// 总金额
  RealColumn get totalAmount => real()();

  /// 实收金额
  RealColumn get actualAmount => real()();

  /// 状态 (preset,credit, Settled, cancelled)
  TextColumn get status => text().withDefault(const Constant('preset'))();

  /// 备注
  TextColumn get remarks => text().nullable()();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 最后更新时间
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
