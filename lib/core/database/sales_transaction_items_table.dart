import 'package:drift/drift.dart';
import 'sales_transactions_table.dart';
import 'batches_table.dart';
import 'products_table.dart';

class SalesTransactionItem extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get salesTransactionId =>
      integer().references(SalesTransaction, #id)();
  IntColumn get productId => integer().references(Product, #id)();
  IntColumn get batchId => integer().references(ProductBatch, #id).nullable()();
  IntColumn get priceInCents => integer()();
  IntColumn get quantity => integer()();
}
