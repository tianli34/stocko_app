import 'package:drift/drift.dart';
import 'products_table.dart';
import 'units_table.dart';
import 'sales_transactions_table.dart';
import 'batches_table.dart';

class SalesTransactionItemsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get salesTransactionId =>
      integer().references(SalesTransactionsTable, #id)();
  IntColumn get productId => integer().references(Product, #id)();
  IntColumn get unitId => integer().references(Unit, #id)();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
  RealColumn get totalPrice => real()();
  IntColumn get batchNumber =>
      integer().references(ProductBatch, #batchNumber).nullable()();
}
