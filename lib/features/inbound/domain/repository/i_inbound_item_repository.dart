import '../model/inbound_item.dart';

/// 入库单明细仓储接口
/// 定义入库单明细相关的业务操作规范
abstract class IInboundItemRepository {
  /// 添加入库单明细
  Future<int> addInboundItem(InboundItem item);

  /// 批量添加入库单明细
  Future<void> addMultipleInboundItems(List<InboundItem> items);

  /// 根据ID获取入库单明细
  Future<InboundItem?> getInboundItemById(String id);

  /// 根据入库单ID获取所有明细
  Future<List<InboundItem>> getInboundItemsByReceiptId(String receiptId);

  /// 监听入库单明细变化
  Stream<List<InboundItem>> watchInboundItemsByReceiptId(String receiptId);

  /// 更新入库单明细
  Future<bool> updateInboundItem(InboundItem item);

  /// 删除入库单明细
  Future<int> deleteInboundItem(String id);

  /// 删除入库单的所有明细
  Future<int> deleteInboundItemsByReceiptId(String receiptId);

  /// 根据商品ID获取入库明细
  Future<List<InboundItem>> getInboundItemsByProductId(String productId);

  /// 根据批次号获取入库明细
  Future<List<InboundItem>> getInboundItemsByBatchNumber(String batchNumber);

  /// 根据货位ID获取入库明细
  Future<List<InboundItem>> getInboundItemsByLocationId(String locationId);

  /// 获取入库单明细总数
  Future<int> getInboundItemCount(String receiptId);

  /// 获取入库单总数量
  Future<double> getInboundTotalQuantity(String receiptId);

  /// 替换入库单明细（删除旧的，插入新的）
  Future<void> replaceInboundItems(String receiptId, List<InboundItem> items);
}
