import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../../../../core/services/data_refresh_service.dart';
import '../../../inbound/data/dao/inbound_item_dao.dart';

final inboundItemDaoProvider = Provider<InboundItemDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.inboundItemDao;
});

final inboundRecordsProvider =
    StreamProvider<List<InboundReceiptData>>((ref) {
  // 监听数据刷新触发器
  ref.watch(dataRefreshTriggerProvider);
  
  final database = ref.watch(appDatabaseProvider);
  return database.inboundReceiptDao.watchAllInboundReceipts().map((receipts) {
    receipts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return receipts;
  });
});

final inboundRecordItemsProvider =
    FutureProvider.family<List<InboundItemData>, int>((
  ref,
  recordId,
) {
  final dao = ref.watch(inboundItemDaoProvider);
  return dao.getInboundItemsByReceiptId(recordId);
});
