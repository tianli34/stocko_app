import 'package:drift/drift.dart';
import 'customers_table.dart';
import 'shops_table.dart';

/// 销售交易表
class SalesTransactionsTable extends Table {
  @override
  String get tableName => 'sales_transactions';

  /// 主键 - 自增ID
  IntColumn get id => integer().autoIncrement()();

  /// 销售订单号
  IntColumn get salesOrderNo => integer().named('sales_order_no').unique()();

  /// 客户ID
  IntColumn get customerId => integer().named('customer_id').references(Customers, #id)();

  /// 店铺ID
  TextColumn get shopId => text().named('shop_id').references(ShopsTable, #id)();

  /// 总金额
  RealColumn get totalAmount => real().named('total_amount')();

  /// 实际金额
  RealColumn get actualAmount => real().named('actual_amount')();

  /// 状态 (preset,credit, Settled, cancelled)
  TextColumn get status => text().named('status').withDefault(const Constant('preset'))();

  /// 备注
  TextColumn get remarks => text().named('remarks').nullable()();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(currentDateAndTime)();

  /// 最后更新时间
  DateTimeColumn get updatedAt => dateTime().named('updated_at').withDefault(currentDateAndTime)();

}
