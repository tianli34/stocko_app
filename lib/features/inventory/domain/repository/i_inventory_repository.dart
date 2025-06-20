import '../model/inventory.dart';

/// 库存仓储接口
/// 定义库存相关的业务操作规范
abstract class IInventoryRepository {
  /// 添加库存记录
  Future<int> addInventory(Inventory inventory);

  /// 根据ID获取库存
  Future<Inventory?> getInventoryById(String id);

  /// 根据产品ID和店铺ID获取库存
  Future<Inventory?> getInventoryByProductAndShop(
    String productId,
    String shopId,
  );

  /// 获取所有库存
  Future<List<Inventory>> getAllInventory();

  /// 根据店铺ID获取库存列表
  Future<List<Inventory>> getInventoryByShop(String shopId);

  /// 根据产品ID获取库存列表
  Future<List<Inventory>> getInventoryByProduct(String productId);

  /// 监听所有库存变化
  Stream<List<Inventory>> watchAllInventory();

  /// 监听指定店铺的库存变化
  Stream<List<Inventory>> watchInventoryByShop(String shopId);

  /// 监听指定产品的库存变化
  Stream<List<Inventory>> watchInventoryByProduct(String productId);

  /// 更新库存
  Future<bool> updateInventory(Inventory inventory);

  /// 删除库存记录
  Future<int> deleteInventory(String id);

  /// 根据产品和店铺删除库存
  Future<int> deleteInventoryByProductAndShop(String productId, String shopId);

  /// 更新库存数量
  Future<bool> updateInventoryQuantity(
    String productId,
    String shopId,
    double quantity,
  );

  /// 增加库存数量
  Future<bool> addInventoryQuantity(
    String productId,
    String shopId,
    double amount,
  );

  /// 减少库存数量
  Future<bool> subtractInventoryQuantity(
    String productId,
    String shopId,
    double amount,
  );

  /// 获取低库存产品列表
  Future<List<Inventory>> getLowStockInventory(String shopId, int warningLevel);

  /// 获取缺货产品列表
  Future<List<Inventory>> getOutOfStockInventory(String shopId);

  /// 获取库存总数量（按店铺）
  Future<double> getTotalInventoryByShop(String shopId);

  /// 获取库存总数量（按产品）
  Future<double> getTotalInventoryByProduct(String productId);

  /// 检查库存是否存在
  Future<bool> inventoryExists(String productId, String shopId);
}
