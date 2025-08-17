import '../../domain/repository/i_inventory_repository.dart';
import '../../domain/model/inventory.dart';
import '../../../../core/database/database.dart';
import '../dao/inventory_dao.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 库存仓储实现类
/// 基于本地数据库的库存数据访问层实现
class InventoryRepository implements IInventoryRepository {
  final InventoryDao _inventoryDao;

  InventoryRepository(AppDatabase database)
    : _inventoryDao = database.inventoryDao;

  @override
  Future<int> addInventory(StockModel inventory) async {
    try {
      print('📦 仓储层：添加库存记录，ID: ${inventory.id}');
      return await _inventoryDao.insertInventory(
        _inventoryToCompanion(inventory),
      );
    } catch (e) {
      print('📦 仓储层：添加库存记录失败: $e');
      rethrow;
    }
  }

  @override
  Future<StockModel?> getInventoryById(int id) async {
    try {
      final data = await _inventoryDao.getInventoryById(id);
      return data != null ? _dataToInventory(data) : null;
    } catch (e) {
      print('📦 仓储层：根据ID获取库存失败: $e');
      rethrow;
    }
  }

  @override
  Future<StockModel?> getInventoryByProductAndShop(
    int productId,
    int shopId,
  ) async {
    try {
      final data = await _inventoryDao.getInventoryByProductAndShop(
        productId,
        shopId,
      );
      return data != null ? _dataToInventory(data) : null;
    } catch (e) {
      print('📦 仓储层：根据产品和店铺获取库存失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<StockModel>> getAllInventory() async {
    try {
      final dataList = await _inventoryDao.getAllInventory();
      return dataList.map(_dataToInventory).toList();
    } catch (e) {
      print('📦 仓储层：获取所有库存失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<StockModel>> getInventoryByShop(int shopId) async {
    try {
      final dataList = await _inventoryDao.getInventoryByShop(shopId);
      return dataList.map(_dataToInventory).toList();
    } catch (e) {
      print('📦 仓储层：根据店铺获取库存失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<StockModel>> getInventoryByProduct(int productId) async {
    try {
      final dataList = await _inventoryDao.getInventoryByProduct(productId);
      return dataList.map(_dataToInventory).toList();
    } catch (e) {
      print('📦 仓储层：根据产品获取库存失败: $e');
      rethrow;
    }
  }

  @override
  Stream<List<StockModel>> watchAllInventory() {
    try {
      return _inventoryDao.watchAllInventory().map(
        (dataList) => dataList.map(_dataToInventory).toList(),
      );
    } catch (e) {
      print('📦 仓储层：监听所有库存失败: $e');
      rethrow;
    }
  }

  @override
  Stream<List<StockModel>> watchInventoryByShop(int shopId) {
    try {
      return _inventoryDao
          .watchInventoryByShop(shopId)
          .map((dataList) => dataList.map(_dataToInventory).toList());
    } catch (e) {
      print('📦 仓储层：监听店铺库存失败: $e');
      rethrow;
    }
  }

  @override
  Stream<List<StockModel>> watchInventoryByProduct(int productId) {
    try {
      return _inventoryDao
          .watchInventoryByProduct(productId)
          .map((dataList) => dataList.map(_dataToInventory).toList());
    } catch (e) {
      print('📦 仓储层：监听产品库存失败: $e');
      rethrow;
    }
  }

  @override
  Future<bool> updateInventory(StockModel inventory) async {
    try {
      print('📦 仓储层：更新库存，ID: ${inventory.id}');
      return await _inventoryDao.updateInventory(
        _inventoryToCompanion(inventory),
      );
    } catch (e) {
      print('📦 仓储层：更新库存失败: $e');
      rethrow;
    }
  }

  @override
  Future<int> deleteInventory(int id) async {
    try {
      print('📦 仓储层：删除库存记录，ID: $id');
      return await _inventoryDao.deleteInventory(id);
    } catch (e) {
      print('📦 仓储层：删除库存记录失败: $e');
      rethrow;
    }
  }

  @override
  Future<int> deleteInventoryByProductAndShop(
    int productId,
    int shopId,
  ) async {
    try {
      print('📦 仓储层：删除库存记录，产品ID: $productId, 店铺ID: $shopId');
      return await _inventoryDao.deleteInventoryByProductAndShop(
        productId,
        shopId,
      );
    } catch (e) {
      print('📦 仓储层：删除库存记录失败: $e');
      rethrow;
    }
  }

  @override
  Future<bool> updateInventoryQuantity(
    int productId,
    int shopId,
    int quantity,
  ) async {
    try {
      return await _inventoryDao.updateInventoryQuantity(
        productId,
        shopId,
        quantity,
      );
    } catch (e) {
      print('📦 仓储层：更新库存数量失败: $e');
      rethrow;
    }
  }

  @override
  Future<bool> addInventoryQuantity(
    int productId,
    int shopId,
    int amount,
  ) async {
    try {
      final current = await getInventoryByProductAndShop(productId, shopId);
      if (current != null) {
        return await updateInventoryQuantity(
          productId,
          shopId,
          current.quantity + amount,
        );
      }
      return false;
    } catch (e) {
      print('📦 仓储层：增加库存数量失败: $e');
      rethrow;
    }
  }

  @override
  Future<bool> subtractInventoryQuantity(
    int productId,
    int shopId,
    int amount,
  ) async {
    try {
      final current = await getInventoryByProductAndShop(productId, shopId);
      if (current != null) {
        return await updateInventoryQuantity(
          productId,
          shopId,
          current.quantity - amount,
        );
      }
      return false;
    } catch (e) {
      print('📦 仓储层：减少库存数量失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<StockModel>> getLowStockInventory(
    int shopId,
    int warningLevel,
  ) async {
    try {
      final dataList = await _inventoryDao.getLowStockInventory(
        shopId,
        warningLevel,
      );
      return dataList.map(_dataToInventory).toList();
    } catch (e) {
      print('📦 仓储层：获取低库存产品失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<StockModel>> getOutOfStockInventory(int shopId) async {
    try {
      final dataList = await _inventoryDao.getOutOfStockInventory(shopId);
      return dataList.map(_dataToInventory).toList();
    } catch (e) {
      print('📦 仓储层：获取缺货产品失败: $e');
      rethrow;
    }
  }

  @override
  Future<double> getTotalInventoryByShop(int shopId) async {
    try {
      return await _inventoryDao.getTotalInventoryByShop(shopId);
    } catch (e) {
      print('📦 仓储层：获取店铺库存总量失败: $e');
      rethrow;
    }
  }

  @override
  Future<double> getTotalInventoryByProduct(int productId) async {
    try {
      return await _inventoryDao.getTotalInventoryByProduct(productId);
    } catch (e) {
      print('📦 仓储层：获取产品库存总量失败: $e');
      rethrow;
    }
  }

  @override
  Future<bool> inventoryExists(int productId, int shopId) async {
    try {
      return await _inventoryDao.inventoryExists(productId, shopId);
    } catch (e) {
      print('📦 仓储层：检查库存是否存在失败: $e');
      rethrow;
    }
  }

  /// 将Inventory模型转换为数据库Companion对象
  StockCompanion _inventoryToCompanion(StockModel inventory) {
    if (inventory.id == null) {
      throw ArgumentError('Inventory ID cannot be null when creating a companion.');
    }
    return StockCompanion(
      id: Value(inventory.id!),
      productId: Value(inventory.productId),
      quantity: Value(inventory.quantity),
      shopId: Value(inventory.shopId),
      batchId: Value(inventory.batchId),
      createdAt: inventory.createdAt != null
          ? Value(inventory.createdAt!)
          : const Value.absent(),
      updatedAt: Value(inventory.updatedAt ?? DateTime.now()),
    );
  }

  /// 将数据库数据转换为Inventory模型
  StockModel _dataToInventory(StockData data) {
    return StockModel(
      id: data.id,
      productId: data.productId,
      quantity: data.quantity,
      shopId: data.shopId,
      batchId: data.batchId,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }
}

/// Inventory Repository Provider
final inventoryRepositoryProvider = Provider<IInventoryRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return InventoryRepository(database);
});
