import 'package:drift/drift.dart';
import 'sales_transactions_table.dart';
import 'customers_table.dart';
import 'shops_table.dart';

/// 销售退货单表
class SalesReturn extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get salesTransactionId => integer().references(SalesTransaction, #id)();
  IntColumn get customerId => integer().references(Customers, #id).nullable()();
  IntColumn get shopId => integer().references(Shop, #id)();
  RealColumn get totalAmount => real()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get reason => text().nullable()();
  TextColumn get remarks => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
