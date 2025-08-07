import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/sale/domain/model/sales_transaction.dart';
import 'package:stocko_app/features/sale/domain/model/sales_transaction_item.dart';
import 'package:stocko_app/features/sale/domain/repository/i_sales_transaction_repository.dart';

part 'sales_transaction_repository.g.dart';

@riverpod
ISalesTransactionRepository salesTransactionRepository(SalesTransactionRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return SalesTransactionRepository(db);
}

class SalesTransactionRepository implements ISalesTransactionRepository {
  final AppDatabase _db;

  SalesTransactionRepository(this._db);

  @override
  Future<void> addSalesTransaction(SalesTransaction transaction) async {
    print('🔍 [DEBUG] Repository: addSalesTransaction called');
    final transactionCompanion = transaction.toTableCompanion();
    print('🔍 [DEBUG] Repository: transactionCompanion created');
    
    await _db.transaction(() async {
      try {
        // 插入销售交易并获取自增ID
        final transactionId = await _db.salesTransactionDao.insertSalesTransaction(transactionCompanion);
        print('🔍 [DEBUG] Repository: transaction inserted with ID: $transactionId');
        
        // 使用真实的交易ID创建销售交易项目的companion对象
        final itemCompanions = transaction.items.map((item) {
          print('🔍 [DEBUG] Repository: Processing item with salesTransactionId: $transactionId');
          return item.toTableCompanion(transactionId);
        }).toList();
        print('🔍 [DEBUG] Repository: ${itemCompanions.length} item companions created');
        
        // 插入销售交易项目
        await _db.salesTransactionItemDao.insertSalesTransactionItems(itemCompanions);
        print('🔍 [DEBUG] Repository: items inserted successfully');
        
      } catch (e) {
        print('🔍 [DEBUG] Repository: Error in transaction: $e');
        rethrow;
      }
    });
  }

  @override
  Stream<List<SalesTransaction>> watchAllSalesTransactions() {
    return _db.salesTransactionDao.watchAllSalesTransactions().map((transactions) {
      return transactions.map((t) => SalesTransaction.fromTableData(t)).toList();
    });
  }

  @override
  Future<SalesTransaction?> getSalesTransactionById(int id) async {
    final transactionData = await _db.salesTransactionDao.findSalesTransactionById(id);
    if (transactionData == null) {
      return null;
    }
    final itemsData = await _db.salesTransactionItemDao.findSalesTransactionItemsByTransactionId(id.toString());
    final items = itemsData.map((i) => SalesTransactionItem.fromTableData(i)).toList();
    return SalesTransaction.fromTableData(transactionData, items: items);
  }
}