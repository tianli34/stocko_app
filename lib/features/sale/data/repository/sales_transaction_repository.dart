import 'package:drift/drift.dart' as drift;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/sale/domain/model/sale_cart_item.dart';
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
  Future<int> addSalesTransaction(SalesTransaction transaction) async {
    print('🔍 [DEBUG] Repository: addSalesTransaction called');
    final transactionCompanion = transaction.toTableCompanion();
    print('🔍 [DEBUG] Repository: transactionCompanion created');
    
    return await _db.transaction(() async {
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
        return transactionId;
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
  @override
  Future<int> handleOutbound(
      int shopId, int salesId, List<SaleCartItem> saleItems) async {
    final receiptId = await _db.outboundReceiptDao.insertOutboundReceipt(
      OutboundReceiptCompanion(
        shopId: drift.Value(shopId),
        reason: const drift.Value('销售出库'),
        salesTransactionId: drift.Value(salesId),
      ),
    );

    // 合并明细（将数量换算为基本单位）
    final Map<(int, int, int?), int> merged = {};
    for (final item in saleItems) {
      // 根据productId和unitId查找unitProductId
      final unitProduct = await _db.productUnitDao.getUnitProductByProductAndUnit(
        item.productId,
        item.unitId,
      );
      if (unitProduct == null) {
        throw Exception('未找到产品${item.productName}的单位配置');
      }
      
      final key = (unitProduct.id,
          item.productId,
          item.batchId != null ? int.tryParse(item.batchId!) : null);
      // 将销售数量换算为基本单位数量
      final baseUnitQuantity = (item.quantity * item.conversionRate).toInt();
      merged.update(key, (q) => q + baseUnitQuantity, ifAbsent: () => baseUnitQuantity);
    }

    // 批量写入出库明细
    if (merged.isNotEmpty) {
      final companions = merged.entries.map((e) {
        final upid = e.key.$1;
        final bid = e.key.$3;
        final qty = e.value;
        return OutboundItemCompanion(
          receiptId: drift.Value(receiptId),
          unitProductId: drift.Value(upid),
          quantity: drift.Value(qty),
          batchId: bid != null
              ? drift.Value(bid)
              : const drift.Value.absent(),
        );
      }).toList(growable: false);
      await _db.batch((batch) {
        batch.insertAll(_db.outboundItem, companions);
      });
    }
    return receiptId;
  }
}