import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stocko_app/core/database/database.dart';
import '../domain/model/inventory.dart';
import '../domain/model/inventory_transaction.dart';
import '../domain/repository/i_inventory_repository.dart';
import '../domain/repository/i_inventory_transaction_repository.dart';
import '../data/repository/inventory_repository.dart';
import '../data/repository/inventory_transaction_repository.dart';

/// 库存应用服务
/// 提供库存相关的业务逻辑操作
class InventoryService {
  final IInventoryRepository _inventoryRepository;
  final IInventoryTransactionRepository _transactionRepository;
  final AppDatabase _db;

  InventoryService(this._inventoryRepository, this._transactionRepository, this._db);

  /// 入库操作
  /// 增加库存数量并记录入库流水
  Future<bool> inbound({
    required int productId,
    required int shopId,
    int? batchId,
    required int quantity,
    DateTime? time,
  }) async {
    try {
      // 事务内：变更库存 + 写流水
      return await _db.transaction(() async {
      // 按 产品+店铺+批次 维度检查库存是否存在
      var inventory = await _inventoryRepository
          .getInventoryByProductShopAndBatch(productId, shopId, batchId);

      if (inventory == null) {
        // 如果库存不存在，创建新库存记录
        inventory = StockModel.create(
          productId: productId,
          quantity: quantity,
          shopId: shopId,
          batchId: batchId,
        );
        await _inventoryRepository.addInventory(inventory);
      } else {
        // 如果库存存在，增加库存数量
        final ok = await _inventoryRepository.addInventoryQuantityByBatch(
          productId,
          shopId,
          batchId,
          quantity,
        );
        if (!ok) return false; // 没有匹配行（例如记录不存在）
      }

      // 记录入库流水
      final transaction = InventoryTransactionModel.createInbound(
        productId: productId,
        quantity: quantity,
        shopId: shopId,
        batchId: batchId,
      );
      await _transactionRepository.addTransaction(transaction);
      return true;
      });
    } catch (e) {
      print('📦 库存服务：入库操作失败: $e');
      return false;
    }
  }

  /// 出库操作
  /// 减少库存数量并记录出库流水
  Future<bool> outbound({
    required int productId,
    required int shopId,
    required int quantity,
    int? batchId,
    DateTime? time,
  }) async {
    try {
  return await _db.transaction(() async {
        // 检查库存记录是否存在
        var inventory = await _inventoryRepository
            .getInventoryByProductShopAndBatch(productId, shopId, batchId);
        
        if (inventory == null) {
          // 如果库存记录不存在，创建初始库存为0的记录
          print('📦 库存服务：产品 $productId 在店铺 $shopId 的库存记录不存在，创建初始记录');
          inventory = StockModel.create(
            productId: productId,
            quantity: 0,
            shopId: shopId,
            batchId: batchId,
          );
          await _inventoryRepository.addInventory(inventory);
        }
        
        // 减少库存数量（允许负库存）
        final ok = batchId != null
            ? await _inventoryRepository.subtractInventoryQuantityByBatch(
                productId,
                shopId,
                batchId,
                quantity,
              )
            : await _inventoryRepository.subtractInventoryQuantity(
                productId,
                shopId,
                quantity,
              );
        if (!ok) return false;

        // 记录出库流水
        final transaction = InventoryTransactionModel.createOutbound(
          productId: productId,
          quantity: quantity,
          shopId: shopId,
          batchId: batchId,
        );
        await _transactionRepository.addTransaction(transaction);
        return true;
      });
    } catch (e) {
      print('📦 库存服务：出库操作失败: $e');
      return false;
    }
  }

  /// 库存调整
  /// 调整库存数量并记录调整流水
  Future<bool> adjust({
    required int productId,
    required int shopId,
    required int adjustQuantity,
    DateTime? time,
  }) async {
    try {
  return await _db.transaction(() async {
        // 允许负库存：直接在现有数量上调整
        final ok = adjustQuantity >= 0
            ? await _inventoryRepository.addInventoryQuantity(
                productId,
                shopId,
                adjustQuantity,
              )
            : await _inventoryRepository.subtractInventoryQuantity(
                productId,
                shopId,
                -adjustQuantity,
              );
        if (!ok) return false;

        // 记录调整流水
        final transaction = InventoryTransactionModel.createAdjustment(
          productId: productId,
          quantity: adjustQuantity,
          shopId: shopId,
        );
        await _transactionRepository.addTransaction(transaction);
        return true;
      });
    } catch (e) {
      print('📦 库存服务：库存调整失败: $e');
      return false;
    }
  }

  /// 获取库存信息
  Future<StockModel?> getInventory(int productId, int shopId) async {
    return await _inventoryRepository.getInventoryByProductAndShop(
      productId,
      shopId,
    );
  }

  /// 获取店铺所有库存
  Future<List<StockModel>> getShopInventory(int shopId) async {
    return await _inventoryRepository.getInventoryByShop(shopId);
  }

  /// 获取产品在所有店铺的库存
  Future<List<StockModel>> getProductInventory(int productId) async {
    return await _inventoryRepository.getInventoryByProduct(productId);
  }

  /// 获取低库存预警列表
  Future<List<StockModel>> getLowStockInventory(
    int shopId,
    int warningLevel,
  ) async {
    return await _inventoryRepository.getLowStockInventory(
      shopId,
      warningLevel,
    );
  }

  /// 获取缺货产品列表
  Future<List<StockModel>> getOutOfStockInventory(int shopId) async {
    return await _inventoryRepository.getOutOfStockInventory(shopId);
  }

  /// 获取库存流水
  Future<List<InventoryTransactionModel>> getTransactions({
    int? productId,
    int? shopId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (startDate != null && endDate != null) {
      return await _transactionRepository.getTransactionsByDateRange(
        startDate,
        endDate,
        shopId: shopId,
        productId: productId,
      );
    }

    if (productId != null && shopId != null) {
      return await _transactionRepository.getTransactionsByProductAndShop(
        productId,
        shopId,
      );
    }

    if (productId != null) {
      return await _transactionRepository.getTransactionsByProduct(productId);
    }

    if (shopId != null) {
      return await _transactionRepository.getTransactionsByShop(shopId);
    }

    if (type != null) {
      return await _transactionRepository.getTransactionsByType(type);
    }

    return await _transactionRepository.getAllTransactions();
  }
  /// 库存调整的业务逻辑
  ///
  /// [productId] 产品ID
  /// [quantity] 调整后的数量
  /// [shopId] 店铺ID
  Future<void> adjustInventory({
    required int productId,
    required int quantity,
    required int shopId,
  }) async {
    // 以“目标量-当前量”为调整额，复用 adjust（允许负库存）
    final inventory = await _inventoryRepository.getInventoryByProductAndShop(
      productId,
      shopId,
    );
    final currentQuantity = inventory?.quantity ?? 0;
    final diff = quantity - currentQuantity;
    if (diff == 0) return;
    await adjust(
      productId: productId,
      shopId: shopId,
      adjustQuantity: diff,
    );
  }
}

/// 库存服务 Provider
final inventoryServiceProvider = Provider<InventoryService>((ref) {
  final inventoryRepository = ref.watch(inventoryRepositoryProvider);
  final transactionRepository = ref.watch(
    inventoryTransactionRepositoryProvider,
  );
  final db = ref.watch(appDatabaseProvider);
  return InventoryService(inventoryRepository, transactionRepository, db);
});
