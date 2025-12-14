import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../inventory/application/inventory_service.dart';
import '../../inventory/domain/repository/i_inventory_repository.dart';
import '../../inventory/data/repository/inventory_repository.dart';
import '../domain/model/stocktake_order.dart';
import '../domain/model/stocktake_item.dart';
import '../domain/model/stocktake_status.dart';
import '../domain/repository/i_stocktake_order_repository.dart';
import '../domain/repository/i_stocktake_item_repository.dart';
import '../data/repository/stocktake_order_repository.dart';
import '../data/repository/stocktake_item_repository.dart';

/// 盘点业务服务
class StocktakeService {
  final IStocktakeOrderRepository _orderRepository;
  final IStocktakeItemRepository _itemRepository;
  final IInventoryRepository _inventoryRepository;
  final InventoryService _inventoryService;
  final AppDatabase _db;

  StocktakeService(
    this._orderRepository,
    this._itemRepository,
    this._inventoryRepository,
    this._inventoryService,
    this._db,
  );

  /// 创建盘点单
  Future<StocktakeOrderModel?> createStocktake({
    required int shopId,
    required StocktakeType type,
    int? categoryId,
    String? remarks,
  }) async {
    try {
      final order = StocktakeOrderModel.create(
        shopId: shopId,
        type: type,
        categoryId: categoryId,
        remarks: remarks,
      );
      
      final id = await _orderRepository.createOrder(order);
      return order.copyWith(id: id);
    } catch (e) {
      print('📦 盘点服务：创建盘点单失败: $e');
      return null;
    }
  }

  /// 开始盘点（状态变更为进行中）
  Future<bool> startStocktake(int stocktakeId) async {
    try {
      return await _orderRepository.updateStatus(
          stocktakeId, StocktakeStatus.inProgress);
    } catch (e) {
      print('📦 盘点服务：开始盘点失败: $e');
      return false;
    }
  }

  /// 添加盘点项
  Future<StocktakeItemModel?> addStocktakeItem({
    required int stocktakeId,
    required int productId,
    required int actualQuantity,
    int? batchId,
    required int shopId,
  }) async {
    try {
      // 检查是否已存在该商品的盘点项
      final existing = await _itemRepository.getItemByProductId(
          stocktakeId, productId, batchId);
      
      if (existing != null) {
        // 更新实盘数量
        final updated = existing.updateActualQuantity(actualQuantity);
        await _itemRepository.updateItem(updated);
        return updated;
      }
      
      // 获取系统库存
      final inventory = await _inventoryRepository
          .getInventoryByProductShopAndBatch(productId, shopId, batchId);
      final systemQuantity = inventory?.quantity ?? 0;
      
      // 创建新盘点项
      final item = StocktakeItemModel.create(
        stocktakeId: stocktakeId,
        productId: productId,
        systemQuantity: systemQuantity,
        actualQuantity: actualQuantity,
        batchId: batchId,
      );
      
      final id = await _itemRepository.addItem(item);
      return item.copyWith(id: id);
    } catch (e) {
      print('📦 盘点服务：添加盘点项失败: $e');
      return null;
    }
  }

  /// 更新实盘数量
  Future<bool> updateActualQuantity(int itemId, int quantity) async {
    try {
      return await _itemRepository.updateActualQuantity(itemId, quantity);
    } catch (e) {
      print('📦 盘点服务：更新实盘数量失败: $e');
      return false;
    }
  }

  /// 删除盘点项
  Future<bool> deleteStocktakeItem(int itemId) async {
    try {
      return await _itemRepository.deleteItem(itemId);
    } catch (e) {
      print('📦 盘点服务：删除盘点项失败: $e');
      return false;
    }
  }

  /// 完成盘点
  Future<StocktakeSummary?> completeStocktake(int stocktakeId) async {
    try {
      // 更新状态为已完成
      final success = await _orderRepository.updateStatus(
          stocktakeId, StocktakeStatus.completed);
      
      if (!success) return null;
      
      // 返回盘点汇总
      return await _itemRepository.getSummary(stocktakeId);
    } catch (e) {
      print('📦 盘点服务：完成盘点失败: $e');
      return null;
    }
  }

  /// 确认调整库存
  Future<bool> confirmAdjustment(int stocktakeId) async {
    try {
      return await _db.transaction(() async {
        final order = await _orderRepository.getOrderById(stocktakeId);
        if (order == null) return false;
        
        // 获取所有未调整的差异项
        final diffItems =
            await _itemRepository.getUnadjustedDiffItems(stocktakeId);
        
        // 逐个调整库存
        for (final item in diffItems) {
          if (item.differenceQty != 0) {
            final success = await _inventoryService.adjust(
              productId: item.productId,
              shopId: order.shopId,
              adjustQuantity: item.differenceQty,
            );
            
            if (success) {
              await _itemRepository.markAsAdjusted(item.id!);
            }
          }
        }
        
        // 更新盘点单状态为已审核
        await _orderRepository.updateStatus(
            stocktakeId, StocktakeStatus.audited);
        
        return true;
      });
    } catch (e) {
      print('📦 盘点服务：确认调整库存失败: $e');
      return false;
    }
  }

  /// 更新差异原因
  Future<bool> updateDifferenceReason(int itemId, String reason) async {
    try {
      return await _itemRepository.updateDifferenceReason(itemId, reason);
    } catch (e) {
      print('📦 盘点服务：更新差异原因失败: $e');
      return false;
    }
  }

  /// 获取盘点单
  Future<StocktakeOrderModel?> getStocktakeOrder(int id) {
    return _orderRepository.getOrderById(id);
  }

  /// 获取盘点单列表
  Future<List<StocktakeOrderModel>> getStocktakeList({int? shopId}) {
    if (shopId != null) {
      return _orderRepository.getOrdersByShop(shopId);
    }
    return _orderRepository.getAllOrders();
  }

  /// 获取盘点项列表
  Future<List<StocktakeItemModel>> getStocktakeItems(int stocktakeId) {
    return _itemRepository.getItemsByStocktakeId(stocktakeId);
  }

  /// 获取差异项列表
  Future<List<StocktakeItemModel>> getDiffItems(int stocktakeId) {
    return _itemRepository.getDiffItems(stocktakeId);
  }

  /// 获取盘点汇总
  Future<StocktakeSummary> getSummary(int stocktakeId) {
    return _itemRepository.getSummary(stocktakeId);
  }

  /// 删除盘点单
  Future<bool> deleteStocktake(int stocktakeId) async {
    try {
      // 先删除盘点项
      await _itemRepository.deleteItemsByStocktakeId(stocktakeId);
      // 再删除盘点单
      return await _orderRepository.deleteOrder(stocktakeId);
    } catch (e) {
      print('📦 盘点服务：删除盘点单失败: $e');
      return false;
    }
  }

  /// 监听盘点单列表
  Stream<List<StocktakeOrderModel>> watchStocktakeList({int? shopId}) {
    if (shopId != null) {
      return _orderRepository.watchOrdersByShop(shopId);
    }
    return _orderRepository.watchAllOrders();
  }

  /// 监听盘点项列表
  Stream<List<StocktakeItemModel>> watchStocktakeItems(int stocktakeId) {
    return _itemRepository.watchItemsByStocktakeId(stocktakeId);
  }
}

/// Provider
final stocktakeServiceProvider = Provider<StocktakeService>((ref) {
  final orderRepository = ref.watch(stocktakeOrderRepositoryProvider);
  final itemRepository = ref.watch(stocktakeItemRepositoryProvider);
  final inventoryRepository = ref.watch(inventoryRepositoryProvider);
  final inventoryService = ref.watch(inventoryServiceProvider);
  final db = ref.watch(appDatabaseProvider);
  return StocktakeService(
    orderRepository,
    itemRepository,
    inventoryRepository,
    inventoryService,
    db,
  );
});
