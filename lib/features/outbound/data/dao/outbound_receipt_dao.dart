import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/outbound_receipts_table.dart';

part 'outbound_receipt_dao.g.dart';

@DriftAccessor(tables: [OutboundReceipt])
class OutboundReceiptDao extends DatabaseAccessor<AppDatabase>
    with _$OutboundReceiptDaoMixin {
  OutboundReceiptDao(super.db);

  /// 插入出库单
  Future<int> insertOutboundReceipt(OutboundReceiptCompanion receipt) async {
    return await into(outboundReceipt).insert(receipt);
  }

  /// 根据ID获取出库单
  Future<OutboundReceiptData?> getOutboundReceiptById(int id) {
    return (select(outboundReceipt)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 获取所有出库单
  Future<List<OutboundReceiptData>> getAllOutboundReceipts() {
    return select(outboundReceipt).get();
  }

  /// 根据店铺ID获取出库单
  Future<List<OutboundReceiptData>> getOutboundReceiptsByShop(int shopId) {
    return (select(outboundReceipt)..where((t) => t.shopId.equals(shopId)))
        .get();
  }

  /// 监听所有出库单变化
  Stream<List<OutboundReceiptData>> watchAllOutboundReceipts() {
    return select(outboundReceipt).watch();
  }
}