import 'package:drift/drift.dart';
import 'products_table.dart';
import 'batches_table.dart';
import 'units_table.dart';
import 'sales_transactions_table.dart';

class SalesTransactionItemsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get salesTransactionId => integer().references(SalesTransactionsTable, #id)();
  IntColumn get productId => integer().references(ProductsTable, #id)();
  IntColumn get unitId => integer().named('unit_id').references(Unit, #id)();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
  RealColumn get totalPrice => real()();
  
  /// 批次ID（外键引用batches.batchNumber），可为空
  TextColumn get batchId => text().named('batch_id').nullable().references(BatchesTable, #batchNumber)();

}