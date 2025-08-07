import '../model/sales_transaction.dart';

abstract class ISalesTransactionRepository {
  Future<void> addSalesTransaction(SalesTransaction transaction);
  Stream<List<SalesTransaction>> watchAllSalesTransactions();
  Future<SalesTransaction?> getSalesTransactionById(int id);
}