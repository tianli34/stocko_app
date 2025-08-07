import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../../../inbound/data/dao/inbound_item_dao.dart';
import '../../../../core/database/inbound_receipts_table.dart';

final inboundItemDaoProvider = Provider<InboundItemDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.inboundItemDao;
});

/// Provider to watch all inbound records, returning the full data objects.
final inboundRecordsProvider =
    FutureProvider<List<InboundReceiptsTableData>>((ref) async {
  final database = ref.read(appDatabaseProvider);
  final receipts = await database.inboundReceiptDao.getAllInboundReceipts();
  // Sort by creation date descending
  receipts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return receipts;
});

/// Provider to get items for a specific inbound record
final inboundRecordItemsProvider =
    FutureProvider.family<List<InboundReceiptItemsTableData>, String>((
  ref,
  recordId,
) {
  final dao = ref.watch(inboundItemDaoProvider);
  // We are using receiptNumber as the id in InboundRecordData,
  // but the dao method needs the actual id from the inbound_receipts_table.
  // A better approach might be to pass the whole InboundRecord object
  // or adjust the providers. For now, we assume recordId is the receiptNumber.
  // This will require a lookup.
  // Let's modify the inboundRecordsProvider to return the full InboundReceiptsTableData object
  // to avoid this lookup.
  
  // For now, let's assume we can get the receipt by its number.
  // This is a placeholder for the actual implementation.
  // We will need to add a method to InboundReceiptDao to get a receipt by its number.
  // Let's assume we have it for now.
  // final receipt = await ref.read(inboundReceiptDaoProvider).getReceiptByNumber(recordId);
  // if (receipt != null) {
  //   return dao.getInboundItemsByReceiptId(receipt.id);
  // } else {
  //   return [];
  // }
  // The ID passed to the family is the actual receipt ID.
  return dao.getInboundItemsByReceiptId(recordId);
});
