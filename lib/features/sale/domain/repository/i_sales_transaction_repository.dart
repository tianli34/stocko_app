import '../model/sales_transaction.dart';

abstract class ISalesTransactionRepository {
  /// 插入销售交易，返回生成的自增ID
  Future<int> addSalesTransaction(SalesTransaction transaction);
  Stream<List<SalesTransaction>> watchAllSalesTransactions();
  Future<SalesTransaction?> getSalesTransactionById(int id);
}