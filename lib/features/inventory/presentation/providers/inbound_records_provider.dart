import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../../../inbound/data/dao/inbound_item_dao.dart';

final inboundItemDaoProvider = Provider<InboundItemDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.inboundItemDao;
});

final inboundRecordsProvider =
    FutureProvider<List<InboundReceiptData>>((ref) async {
  final database = ref.read(appDatabaseProvider);
  final receipts = await database.inboundReceiptDao.getAllInboundReceipts();
  receipts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return receipts;
});

final inboundRecordItemsProvider =
    FutureProvider.family<List<InboundItemData>, int>((
  ref,
  recordId,
) {
  final dao = ref.watch(inboundItemDaoProvider);
  return dao.getInboundItemsByReceiptId(recordId);
});
