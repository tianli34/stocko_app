import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/outbound_receipt_items_table.dart';

part 'outbound_item_dao.g.dart';

@DriftAccessor(tables: [OutboundItem])
class OutboundItemDao extends DatabaseAccessor<AppDatabase>
    with _$OutboundItemDaoMixin {
  OutboundItemDao(super.db);

  /// 根据出库单ID获取所有明细
  Future<List<OutboundItemData>> getOutboundItemsByReceiptId(int receiptId) {
    return (select(outboundItem)
          ..where((t) => t.receiptId.equals(receiptId)))
        .get();
  }
}