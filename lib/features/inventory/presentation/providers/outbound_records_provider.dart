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
    FutureProvider<List<InventoryTransaction>>((ref) async {
  final dao = ref.watch(inventoryTransactionDaoProvider);
  final transactionsData = await dao.getAllTransactions();
  
  // Convert TableData to Domain Model
  final transactions = transactionsData.map((data) {
    return InventoryTransaction(
      id: data.id,
      productId: data.productId,
      type: data.type,
      quantity: data.quantity,
      shopId: data.shopId,
      time: data.time,
      batchId: data.batchId,
      createdAt: data.createdAt,
    );
  }).toList();

  // Filter for outbound records
  final outboundTransactions = transactions
      .where((t) => t.type == InventoryTransaction.typeOut)
      .toList();
      
  // Sort by creation date descending
  outboundTransactions.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
  
  return outboundTransactions;
});