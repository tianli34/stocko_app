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
    required int productId,
    required int shopId,
    int? batchId,
    required int quantity,
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
        inventory = StockModel.create(
          productId: productId,
          quantity: quantity,
          shopId: shopId,
          batchId: batchId,
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
      final transaction = InventoryTransactionModel.createInbound(
        productId: productId,
        quantity: quantity,
        shopId: shopId,
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
    required int productId,
    required int shopId,
    required int quantity,
    DateTime? time,
  }) async {
    try {
      // 检查库存是否足够
      await _inventoryRepository.getInventoryByProductAndShop(
        productId,
        shopId,
      );

      // if (inventory == null || inventory.quantity < quantity) {
      //   print('📦 库存服务：库存不足，无法出库');
      //   return false;
      // }

      // 减少库存数量
      await _inventoryRepository.subtractInventoryQuantity(
        productId,
        shopId,
        quantity,
      );

      // 记录出库流水
      final transaction = InventoryTransactionModel.createOutbound(
        productId: productId,
        quantity: quantity,
        shopId: shopId,
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
    required int productId,
    required int shopId,
    required int adjustQuantity,
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
      // if (newQuantity < 0) {
      //   print('📦 库存服务：调整后库存数量不能为负数');
      //   return false;
      // }

      // 更新库存数量
      await _inventoryRepository.updateInventoryQuantity(
        productId,
        shopId,
        newQuantity,
      );

      // 记录调整流水
      final transaction = InventoryTransactionModel.createAdjustment(
        productId: productId,
        quantity: adjustQuantity,
        shopId: shopId,
      );
      await _transactionRepository.addTransaction(transaction);

      return true;
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
    // 检查库存记录是否存在
    final inventory = await _inventoryRepository.getInventoryByProductAndShop(
      productId,
      shopId,
    );

    final currentQuantity = inventory?.quantity ?? 0;
    final adjustQuantity = quantity - currentQuantity;

    if (inventory != null) {
      // 如果记录存在，则更新数量
      await _inventoryRepository.updateInventoryQuantity(
        productId,
        shopId,
        quantity,
      );
    } else {
      // 如果记录不存在，则创建新的库存记录
      final newInventory = StockModel.create(
        productId: productId,
        quantity: quantity,
        shopId: shopId,
        batchId: null,
      );
      await _inventoryRepository.addInventory(newInventory);
    }

    // 记录调整流水
    final transaction = InventoryTransactionModel.createAdjustment(
      productId: productId,
      quantity: adjustQuantity,
      shopId: shopId,
    );
    await _transactionRepository.addTransaction(transaction);
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
