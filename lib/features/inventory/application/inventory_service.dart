import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  InventoryService(this._inventoryRepository, this._transactionRepository);

  /// 入库操作
  /// 增加库存数量并记录入库流水
  Future<bool> inbound({
    required String productId,
    required String shopId,
    required String batchNumber,
    required double quantity,
    DateTime? time,
  }) async {
    try {
      // 检查库存是否存在（暂时使用产品+店铺查找，未来需要支持批次）
      var inventory = await _inventoryRepository.getInventoryByProductAndShop(
        productId,
        shopId,
      );

      if (inventory == null) {
        // 如果库存不存在，创建新库存记录
        inventory = Inventory.create(
          productId: productId,
          quantity: quantity,
          shopId: shopId,
          batchNumber: batchNumber,
        );
        await _inventoryRepository.addInventory(inventory);
      } else {
        // 如果库存存在，增加库存数量
        await _inventoryRepository.addInventoryQuantity(
          productId,
          shopId,
          quantity,
        );
      }

      // 记录入库流水
      final transaction = InventoryTransaction.createInbound(
        productId: productId,
        quantity: quantity,
        shopId: shopId,
        time: time,
      );
      await _transactionRepository.addTransaction(transaction);

      return true;
    } catch (e) {
      print('📦 库存服务：入库操作失败: $e');
      return false;
    }
  }

  /// 出库操作
  /// 减少库存数量并记录出库流水
  Future<bool> outbound({
    required String productId,
    required String shopId,
    required double quantity,
    DateTime? time,
  }) async {
    try {
      // 检查库存是否足够
      final inventory = await _inventoryRepository.getInventoryByProductAndShop(
        productId,
        shopId,
      );

      if (inventory == null || inventory.quantity < quantity) {
        print('📦 库存服务：库存不足，无法出库');
        return false;
      }

      // 减少库存数量
      await _inventoryRepository.subtractInventoryQuantity(
        productId,
        shopId,
        quantity,
      );

      // 记录出库流水
      final transaction = InventoryTransaction.createOutbound(
        productId: productId,
        quantity: quantity,
        shopId: shopId,
        time: time,
      );
      await _transactionRepository.addTransaction(transaction);

      return true;
    } catch (e) {
      print('📦 库存服务：出库操作失败: $e');
      return false;
    }
  }

  /// 库存调整
  /// 调整库存数量并记录调整流水
  Future<bool> adjust({
    required String productId,
    required String shopId,
    required double adjustQuantity,
    DateTime? time,
  }) async {
    try {
      // 获取当前库存
      final inventory = await _inventoryRepository.getInventoryByProductAndShop(
        productId,
        shopId,
      );

      if (inventory == null) {
        print('📦 库存服务：库存不存在，无法调整');
        return false;
      }

      // 计算新的库存数量
      final newQuantity = inventory.quantity + adjustQuantity;
      if (newQuantity < 0) {
        print('📦 库存服务：调整后库存数量不能为负数');
        return false;
      }

      // 更新库存数量
      await _inventoryRepository.updateInventoryQuantity(
        productId,
        shopId,
        newQuantity,
      );

      // 记录调整流水
      final transaction = InventoryTransaction.createAdjustment(
        productId: productId,
        quantity: adjustQuantity,
        shopId: shopId,
        time: time,
      );
      await _transactionRepository.addTransaction(transaction);

      return true;
    } catch (e) {
      print('📦 库存服务：库存调整失败: $e');
      return false;
    }
  }

  /// 获取库存信息
  Future<Inventory?> getInventory(String productId, String shopId) async {
    return await _inventoryRepository.getInventoryByProductAndShop(
      productId,
      shopId,
    );
  }

  /// 获取店铺所有库存
  Future<List<Inventory>> getShopInventory(String shopId) async {
    return await _inventoryRepository.getInventoryByShop(shopId);
  }

  /// 获取产品在所有店铺的库存
  Future<List<Inventory>> getProductInventory(String productId) async {
    return await _inventoryRepository.getInventoryByProduct(productId);
  }

  /// 获取低库存预警列表
  Future<List<Inventory>> getLowStockInventory(
    String shopId,
    int warningLevel,
  ) async {
    return await _inventoryRepository.getLowStockInventory(
      shopId,
      warningLevel,
    );
  }

  /// 获取缺货产品列表
  Future<List<Inventory>> getOutOfStockInventory(String shopId) async {
    return await _inventoryRepository.getOutOfStockInventory(shopId);
  }

  /// 获取库存流水
  Future<List<InventoryTransaction>> getTransactions({
    String? productId,
    String? shopId,
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
}

/// 库存服务 Provider
final inventoryServiceProvider = Provider<InventoryService>((ref) {
  final inventoryRepository = ref.watch(inventoryRepositoryProvider);
  final transactionRepository = ref.watch(
    inventoryTransactionRepositoryProvider,
  );
  return InventoryService(inventoryRepository, transactionRepository);
});
