import '../model/inventory.dart';

/// 库存仓储接口
/// 定义库存相关的业务操作规范
abstract class IInventoryRepository {
  /// 添加库存记录
  Future<int> addInventory(StockModel inventory);

  /// 根据ID获取库存
  Future<StockModel?> getInventoryById(int id);

  /// 根据产品ID和店铺ID获取库存
  Future<StockModel?> getInventoryByProductAndShop(
    int productId,
    int shopId,
  );

  /// 根据产品ID、店铺ID与批次ID（可空）获取库存
  Future<StockModel?> getInventoryByProductShopAndBatch(
    int productId,
    int shopId,
    int? batchId,
  );

  /// 获取所有库存
  Future<List<StockModel>> getAllInventory();

  /// 根据店铺ID获取库存列表
  Future<List<StockModel>> getInventoryByShop(int shopId);

  /// 根据产品ID获取库存列表
  Future<List<StockModel>> getInventoryByProduct(int productId);

  /// 监听所有库存变化
  Stream<List<StockModel>> watchAllInventory();

  /// 监听指定店铺的库存变化
  Stream<List<StockModel>> watchInventoryByShop(int shopId);

  /// 监听指定产品的库存变化
  Stream<List<StockModel>> watchInventoryByProduct(int productId);

  /// 更新库存
  Future<bool> updateInventory(StockModel inventory);

  /// 删除库存记录
  Future<int> deleteInventory(int id);

  /// 根据产品和店铺删除库存
  Future<int> deleteInventoryByProductAndShop(int productId, int shopId);

  /// 更新库存数量
  Future<bool> updateInventoryQuantity(
    int productId,
    int shopId,
    int quantity,
  );

  /// 按批次更新库存数量（batchId 可为 null 表示无批次）
  Future<bool> updateInventoryQuantityByBatch(
    int productId,
    int shopId,
    int? batchId,
    int quantity,
  );

  /// 增加库存数量
  Future<bool> addInventoryQuantity(
    int productId,
    int shopId,
    int amount,
  );

  /// 按批次增加库存数量（batchId 可为 null 表示无批次）
  Future<bool> addInventoryQuantityByBatch(
    int productId,
    int shopId,
    int? batchId,
    int amount,
  );

  /// 减少库存数量
  Future<bool> subtractInventoryQuantity(
    int productId,
    int shopId,
    int amount,
  );

  /// 按批次减少库存数量（batchId 可为 null 表示无批次）
  Future<bool> subtractInventoryQuantityByBatch(
    int productId,
    int shopId,
    int? batchId,
    int amount,
  );

  /// 获取低库存产品列表
  Future<List<StockModel>> getLowStockInventory(int shopId, int warningLevel);

  /// 获取缺货产品列表
  Future<List<StockModel>> getOutOfStockInventory(int shopId);

  /// 获取库存总数量（按店铺）
  Future<double> getTotalInventoryByShop(int shopId);

  /// 获取库存总数量（按产品）
  Future<double> getTotalInventoryByProduct(int productId);

  /// 检查库存是否存在
  Future<bool> inventoryExists(int productId, int shopId);

  /// 更新库存的移动加权平均价格
  Future<bool> updateAverageUnitPrice(
    int productId,
    int shopId,
    int? batchId,
    int averageUnitPriceInSis,
  );
}
