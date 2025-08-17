import 'package:drift/drift.dart';
import 'shops_table.dart';
import 'sales_transactions_table.dart';

/// 出库单表
/// 存储出库单的基本信息
class OutboundReceipt extends Table {
  /// 主键 - 出库单ID
  IntColumn get id => integer().autoIncrement()();

  /// 外键 - 店铺ID
  IntColumn get shopId => integer().references(Shop, #id)();

  /// 原因
  TextColumn get reason => text()();

  /// 外键 - 销售单ID（如果来自销售单）
  IntColumn get salesTransactionId =>
      integer().references(SalesTransaction, #id).nullable()();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
