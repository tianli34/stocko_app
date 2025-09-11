import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../../data/dao/inventory_transaction_dao.dart';
import '../../domain/model/inventory_transaction.dart';

final inventoryTransactionDaoProvider =
    Provider<InventoryTransactionDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.inventoryTransactionDao;
});

/// Provider to watch all outbound records, returning the full data objects.
final outboundRecordsProvider =
    FutureProvider<List<InventoryTransactionModel>>((ref) async {
  final dao = ref.watch(inventoryTransactionDaoProvider);
  final transactionsData = await dao.getAllTransactions();
  
  // Convert TableData to Domain Model
  final transactions = transactionsData.map((data) {
    return InventoryTransactionModel(
      id: data.id,
      productId: data.productId,
  // DB stores short codes: 'in' | 'out' | 'adjust' | 'transfer' | 'return'
  // Use converter to enum to avoid Bad state: No element
  type: inventoryTransactionTypeFromDbCode(data.transactionType),
      quantity: data.quantity,
      shopId: data.shopId,
      batchId: data.batchId,
      createdAt: data.createdAt,
    );
  }).toList();

  // Filter for outbound records
  final outboundTransactions = transactions
      .where((t) => t.isOutbound)
      .toList();
      
  // Sort by creation date descending
  outboundTransactions.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
  
  return outboundTransactions;
});