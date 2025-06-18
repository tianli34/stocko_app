import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';

/// 入库记录数据模型
class InboundRecordData {
  final String id;
  final String shopName;
  final DateTime date;
  final int productCount;
  final double totalQuantity;
  final String status;

  const InboundRecordData({
    required this.id,
    required this.shopName,
    required this.date,
    required this.productCount,
    required this.totalQuantity,
    required this.status,
  });
}

/// 入库记录Provider
/// 负责获取入库记录数据
final inboundRecordsProvider = FutureProvider<List<InboundRecordData>>((
  ref,
) async {
  final database = ref.read(appDatabaseProvider);

  // 获取所有入库单，按创建时间倒序排列
  final receipts = await database.inboundReceiptDao.getAllInboundReceipts();
  receipts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  final records = <InboundRecordData>[];

  for (final receipt in receipts) {
    // 获取店铺信息
    final shop = await database.shopDao.getShopById(receipt.shopId);
    final shopName = shop?.name ?? '未知店铺';

    // 获取入库单明细，计算商品种类数和总数量
    final items = await database.inboundItemDao.getInboundItemsByReceiptId(
      receipt.id,
    );
    final productCount = items.length;
    final totalQuantity = items.fold<double>(
      0.0,
      (sum, item) => sum + item.quantity,
    );

    records.add(
      InboundRecordData(
        id: receipt.receiptNumber, // 使用入库单号作为显示ID
        shopName: shopName,
        date: receipt.createdAt,
        productCount: productCount,
        totalQuantity: totalQuantity,
        status: receipt.status,
      ),
    );
  }

  return records;
});
