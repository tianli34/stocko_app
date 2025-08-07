import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/sales_transactions_table.dart';

part 'sales_transaction_dao.g.dart';

@DriftAccessor(tables: [SalesTransactionsTable])
class SalesTransactionDao extends DatabaseAccessor<AppDatabase> with _$SalesTransactionDaoMixin {
  SalesTransactionDao(super.db);

  /// 插入一笔新的销售交易
  Future<int> insertSalesTransaction(SalesTransactionsTableCompanion companion) {
    return into(db.salesTransactionsTable).insert(companion);
  }

  /// 根据ID查找销售交易
  Future<SalesTransactionsTableData?> findSalesTransactionById(int id) {
    return (select(db.salesTransactionsTable)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// 监听所有的销售交易
  Stream<List<SalesTransactionsTableData>> watchAllSalesTransactions() {
    return select(db.salesTransactionsTable).watch();
  }

  /// 更新销售交易状态
  Future<bool> updateSalesTransactionStatus(int id, String status) {
    return (update(db.salesTransactionsTable)..where((tbl) => tbl.id.equals(id)))
        .write(SalesTransactionsTableCompanion(
          status: Value(status),
          updatedAt: Value(DateTime.now()),
        ))
        .then((value) => value > 0);
  }
}