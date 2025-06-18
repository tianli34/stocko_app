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
  Future<int> addInventory(Inventory inventory) async {
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
  Future<Inventory?> getInventoryById(String id) async {
    try {
      final data = await _inventoryDao.getInventoryById(id);
      return data != null ? _dataToInventory(data) : null;
    } catch (e) {
      print('📦 仓储层：根据ID获取库存失败: $e');
      rethrow;
    }
  }

  @override
  Future<Inventory?> getInventoryByProductAndShop(
    String productId,
    String shopId,
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
  Future<List<Inventory>> getAllInventory() async {
    try {
      final dataList = await _inventoryDao.getAllInventory();
      return dataList.map(_dataToInventory).toList();
    } catch (e) {
      print('📦 仓储层：获取所有库存失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<Inventory>> getInventoryByShop(String shopId) async {
    try {
      final dataList = await _inventoryDao.getInventoryByShop(shopId);
      return dataList.map(_dataToInventory).toList();
    } catch (e) {
      print('📦 仓储层：根据店铺获取库存失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<Inventory>> getInventoryByProduct(String productId) async {
    try {
      final dataList = await _inventoryDao.getInventoryByProduct(productId);
      return dataList.map(_dataToInventory).toList();
    } catch (e) {
      print('📦 仓储层：根据产品获取库存失败: $e');
      rethrow;
    }
  }

  @override
  Stream<List<Inventory>> watchAllInventory() {
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
  Stream<List<Inventory>> watchInventoryByShop(String shopId) {
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
  Stream<List<Inventory>> watchInventoryByProduct(String productId) {
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
  Future<bool> updateInventory(Inventory inventory) async {
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
  Future<int> deleteInventory(String id) async {
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
    String productId,
    String shopId,
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
    String productId,
    String shopId,
    double quantity,
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
    String productId,
    String shopId,
    double amount,
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
    String productId,
    String shopId,
    double amount,
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
  Future<List<Inventory>> getLowStockInventory(
    String shopId,
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
  Future<List<Inventory>> getOutOfStockInventory(String shopId) async {
    try {
      final dataList = await _inventoryDao.getOutOfStockInventory(shopId);
      return dataList.map(_dataToInventory).toList();
    } catch (e) {
      print('📦 仓储层：获取缺货产品失败: $e');
      rethrow;
    }
  }

  @override
  Future<double> getTotalInventoryByShop(String shopId) async {
    try {
      return await _inventoryDao.getTotalInventoryByShop(shopId);
    } catch (e) {
      print('📦 仓储层：获取店铺库存总量失败: $e');
      rethrow;
    }
  }

  @override
  Future<double> getTotalInventoryByProduct(String productId) async {
    try {
      return await _inventoryDao.getTotalInventoryByProduct(productId);
    } catch (e) {
      print('📦 仓储层：获取产品库存总量失败: $e');
      rethrow;
    }
  }

  @override
  Future<bool> inventoryExists(String productId, String shopId) async {
    try {
      return await _inventoryDao.inventoryExists(productId, shopId);
    } catch (e) {
      print('📦 仓储层：检查库存是否存在失败: $e');
      rethrow;
    }
  }

  /// 将Inventory模型转换为数据库Companion对象
  InventoryTableCompanion _inventoryToCompanion(Inventory inventory) {
    return InventoryTableCompanion(
      id: Value(inventory.id),
      productId: Value(inventory.productId),
      quantity: Value(inventory.quantity),
      shopId: Value(inventory.shopId),
      // TODO: 添加批次号字段，等待代码生成
      batchNumber: Value(inventory.batchNumber),
      createdAt: inventory.createdAt != null
          ? Value(inventory.createdAt!)
          : const Value.absent(),
      updatedAt: Value(inventory.updatedAt ?? DateTime.now()),
    );
  }

  /// 将数据库数据转换为Inventory模型
  Inventory _dataToInventory(InventoryTableData data) {
    return Inventory(
      id: data.id,
      productId: data.productId,
      quantity: data.quantity,
      shopId: data.shopId,
      batchNumber: 'temp_batch', // TODO: 临时值，等待代码生成后使用 data.batchNumber
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
