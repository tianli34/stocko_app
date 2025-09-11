import '../model/inbound_item.dart';

/// 入库单明细仓储接口
/// 定义入库单明细相关的业务操作规范
abstract class IInboundItemRepository {
  /// 添加入库单明细
  Future<int> addInboundItem(InboundItemModel item);

  /// 批量添加入库单明细
  Future<void> addMultipleInboundItems(List<InboundItemModel> items);

  /// 根据ID获取入库单明细
  Future<InboundItemModel?> getInboundItemById(int id);

  /// 根据入库单ID获取所有明细
  Future<List<InboundItemModel>> getInboundItemsByReceiptId(int receiptId);

  /// 监听入库单明细变化
  Stream<List<InboundItemModel>> watchInboundItemsByReceiptId(int receiptId);

  /// 更新入库单明细
  Future<bool> updateInboundItem(InboundItemModel item);

  /// 删除入库单明细
  Future<int> deleteInboundItem(int id);

  /// 删除入库单的所有明细
  Future<int> deleteInboundItemsByReceiptId(int receiptId);

  /// 根据商品ID获取入库明细
  Future<List<InboundItemModel>> getInboundItemsByProductId(int productId);

  /// 根据批次号获取入库明细
  Future<List<InboundItemModel>> getInboundItemsByBatchNumber(int id);

  /// 根据货位ID获取入库明细
  Future<List<InboundItemModel>> getInboundItemsByLocationId(String locationId);

  /// 获取入库单明细总数
  Future<int> getInboundItemCount(int receiptId);

  /// 获取入库单总数量
  Future<double> getInboundTotalQuantity(int receiptId);

  /// 替换入库单明细（删除旧的，插入新的）
  Future<void> replaceInboundItems(int receiptId, List<InboundItemModel> items);
}
