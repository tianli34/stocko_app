import 'package:drift/drift.dart';
import 'sales_returns_table.dart';
import 'sales_transaction_items_table.dart';
import 'products_table.dart';
import 'units_table.dart';
import 'batches_table.dart';

/// 销售退货明细表
class SalesReturnItem extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get salesReturnId => integer().references(SalesReturn, #id)();
  IntColumn get salesTransactionItemId => integer().references(SalesTransactionItem, #id).nullable()();
  IntColumn get productId => integer().references(Product, #id)();
  IntColumn get unitId => integer().references(Unit, #id).nullable()();
  IntColumn get batchId => integer().references(ProductBatch, #id).nullable()();
  IntColumn get quantity => integer()();
  IntColumn get priceInCents => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
