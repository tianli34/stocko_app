import '../model/inventory_transaction.dart';

/// 库存流水仓储接口
/// 定义库存流水相关的业务操作规范
abstract class IInventoryTransactionRepository {
  /// 添加库存流水记录
  Future<int> addTransaction(InventoryTransaction transaction);

  /// 根据ID获取库存流水
  Future<InventoryTransaction?> getTransactionById(String id);

  /// 获取所有库存流水
  Future<List<InventoryTransaction>> getAllTransactions();

  /// 根据产品ID获取流水记录
  Future<List<InventoryTransaction>> getTransactionsByProduct(String productId);

  /// 根据店铺ID获取流水记录
  Future<List<InventoryTransaction>> getTransactionsByShop(String shopId);

  /// 根据流水类型获取记录
  Future<List<InventoryTransaction>> getTransactionsByType(String type);

  /// 根据产品和店铺获取流水记录
  Future<List<InventoryTransaction>> getTransactionsByProductAndShop(
    String productId,
    String shopId,
  );

  /// 根据时间范围获取流水记录
  Future<List<InventoryTransaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? shopId,
    String? productId,
  });

  /// 监听所有库存流水变化
  Stream<List<InventoryTransaction>> watchAllTransactions();

  /// 监听指定产品的流水变化
  Stream<List<InventoryTransaction>> watchTransactionsByProduct(
    String productId,
  );

  /// 监听指定店铺的流水变化
  Stream<List<InventoryTransaction>> watchTransactionsByShop(String shopId);

  /// 更新库存流水
  Future<bool> updateTransaction(InventoryTransaction transaction);

  /// 删除库存流水记录
  Future<int> deleteTransaction(String id);

  /// 根据产品删除相关流水
  Future<int> deleteTransactionsByProduct(String productId);

  /// 根据店铺删除相关流水
  Future<int> deleteTransactionsByShop(String shopId);

  /// 获取入库流水记录
  Future<List<InventoryTransaction>> getInboundTransactions({
    String? shopId,
    String? productId,
  });

  /// 获取出库流水记录
  Future<List<InventoryTransaction>> getOutboundTransactions({
    String? shopId,
    String? productId,
  });

  /// 获取调整流水记录
  Future<List<InventoryTransaction>> getAdjustmentTransactions({
    String? shopId,
    String? productId,
  });

  /// 统计指定期间的流水数量
  Future<Map<String, double>> getTransactionSummaryByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? shopId,
    String? productId,
  });

  /// 获取最近的流水记录
  Future<List<InventoryTransaction>> getRecentTransactions(
    int limit, {
    String? shopId,
    String? productId,
  });

  /// 获取流水总数
  Future<int> getTransactionCount({
    String? shopId,
    String? productId,
    String? type,
  });
}
