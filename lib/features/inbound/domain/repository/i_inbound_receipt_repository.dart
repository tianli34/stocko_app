import '../model/inbound_receipt.dart';

/// 入库单仓储接口
/// 定义入库单相关的业务操作规范
abstract class IInboundReceiptRepository {
  /// 添加入库单
  Future<int> addInboundReceipt(InboundReceipt receipt);

  /// 根据ID获取入库单
  Future<InboundReceipt?> getInboundReceiptById(String id);

  /// 根据入库单号获取入库单
  Future<InboundReceipt?> getInboundReceiptByNumber(String receiptNumber);

  /// 获取所有入库单
  Future<List<InboundReceipt>> getAllInboundReceipts();

  /// 根据店铺ID获取入库单
  Future<List<InboundReceipt>> getInboundReceiptsByShop(String shopId);

  /// 根据状态获取入库单
  Future<List<InboundReceipt>> getInboundReceiptsByStatus(String status);

  /// 监听所有入库单变化
  Stream<List<InboundReceipt>> watchAllInboundReceipts();

  /// 监听指定店铺的入库单变化
  Stream<List<InboundReceipt>> watchInboundReceiptsByShop(String shopId);

  /// 更新入库单
  Future<bool> updateInboundReceipt(InboundReceipt receipt);

  /// 删除入库单
  Future<int> deleteInboundReceipt(String id);

  /// 生成新的入库单号
  Future<String> generateReceiptNumber(DateTime date);

  /// 检查入库单号是否已存在
  Future<bool> isReceiptNumberExists(String receiptNumber);

  /// 获取入库单总数
  Future<int> getInboundReceiptCount();

  /// 根据日期范围获取入库单
  Future<List<InboundReceipt>> getInboundReceiptsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
}
