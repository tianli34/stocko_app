import '../../domain/repository/i_shop_repository.dart';
import '../../domain/model/shop.dart';
import '../../../../core/database/database.dart';
import '../dao/shop_dao.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 店铺仓储实现类
/// 基于本地数据库的店铺数据访问层实现
class ShopRepository implements IShopRepository {
  final ShopDao _shopDao;

  ShopRepository(AppDatabase database) : _shopDao = database.shopDao;

  @override
  Future<int> addShop(Shop shop) async {
    try {
      print('🏪 仓储层：添加店铺，ID: ${shop.id}, 名称: ${shop.name}');
      return await _shopDao.insertShop(_shopToCompanion(shop));
    } catch (e) {
      print('🏪 仓储层：添加店铺失败: $e');
      rethrow;
    }
  }

  @override
  Future<Shop?> getShopById(int id) async {
    try {
      final data = await _shopDao.getShopById(id);
      return data != null ? _dataToShop(data) : null;
    } catch (e) {
      print('🏪 仓储层：根据ID获取店铺失败: $e');
      rethrow;
    }
  }

  @override
  Future<Shop?> getShopByName(String name) async {
    try {
      final data = await _shopDao.getShopByName(name);
      return data != null ? _dataToShop(data) : null;
    } catch (e) {
      print('🏪 仓储层：根据名称获取店铺失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<Shop>> getAllShops() async {
    try {
      final dataList = await _shopDao.getAllShops();
      return dataList.map(_dataToShop).toList();
    } catch (e) {
      print('🏪 仓储层：获取所有店铺失败: $e');
      rethrow;
    }
  }

  @override
  Stream<List<Shop>> watchAllShops() {
    try {
      return _shopDao.watchAllShops().map(
        (dataList) => dataList.map(_dataToShop).toList(),
      );
    } catch (e) {
      print('🏪 仓储层：监听所有店铺失败: $e');
      rethrow;
    }
  }

  @override
  Future<bool> updateShop(Shop shop) async {
    try {
      print('🏪 仓储层：更新店铺，ID: ${shop.id}');
      return await _shopDao.updateShop(_shopToCompanion(shop));
    } catch (e) {
      print('🏪 仓储层：更新店铺失败: $e');
      rethrow;
    }
  }

  @override
  Future<int> deleteShop(int id) async {
    try {
      print('🏪 仓储层：删除店铺，ID: $id');
      return await _shopDao.deleteShop(id);
    } catch (e) {
      print('🏪 仓储层：删除店铺失败: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isShopNameExists(String name, [int? excludeId]) async {
    try {
      return await _shopDao.isShopNameExists(name, excludeId);
    } catch (e) {
      print('🏪 仓储层：检查店铺名称是否存在失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<Shop>> searchShopsByName(String searchTerm) async {
    try {
      final dataList = await _shopDao.searchShopsByName(searchTerm);
      return dataList.map(_dataToShop).toList();
    } catch (e) {
      print('🏪 仓储层：根据名称搜索店铺失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<Shop>> searchShopsByManager(String managerName) async {
    try {
      final dataList = await _shopDao.searchShopsByManager(managerName);
      return dataList.map(_dataToShop).toList();
    } catch (e) {
      print('🏪 仓储层：根据店长搜索店铺失败: $e');
      rethrow;
    }
  }

  @override
  Future<int> getShopCount() async {
    try {
      return await _shopDao.getShopCount();
    } catch (e) {
      print('🏪 仓储层：获取店铺数量失败: $e');
      rethrow;
    }
  }

  /// 将Shop模型转换为数据库Companion对象
  ShopCompanion _shopToCompanion(Shop shop) {
    return ShopCompanion(
      id: shop.id == null ? const Value.absent() : Value(shop.id!),
      name: Value(shop.name),
      manager: Value(shop.manager),
      createdAt: shop.createdAt != null
          ? Value(shop.createdAt!)
          : const Value.absent(),
      updatedAt: Value(shop.updatedAt ?? DateTime.now()),
    );
  }

  /// 将数据库数据转换为Shop模型
  Shop _dataToShop(ShopData data) {
    return Shop(
      id: data.id,
      name: data.name,
      manager: data.manager,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }
}

/// Shop Repository Provider
final shopRepositoryProvider = Provider<IShopRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return ShopRepository(database);
});
