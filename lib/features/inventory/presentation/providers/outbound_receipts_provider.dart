import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../../../outbound/data/dao/outbound_item_dao.dart';

final outboundItemDaoProvider = Provider<OutboundItemDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.outboundItemDao;
});

/// 实时监听所有出库记录，数据库有变化时自动推送到 UI
final outboundReceiptsProvider =
    StreamProvider<List<OutboundReceiptData>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.outboundReceiptDao
      .watchAllOutboundReceipts()
      .map((receipts) {
    final sorted = List<OutboundReceiptData>.of(receipts)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  });
});

final outboundReceiptItemsProvider =
    FutureProvider.family<List<OutboundItemData>, int>((ref, recordId) {
  final dao = ref.watch(outboundItemDaoProvider);
  return dao.getOutboundItemsByReceiptId(recordId);
});
