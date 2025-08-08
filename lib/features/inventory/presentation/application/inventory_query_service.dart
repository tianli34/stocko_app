import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repository/i_inventory_repository.dart';
import '../../data/repository/inventory_repository.dart';
import '../../../product/domain/repository/i_product_repository.dart';
import '../../../product/data/repository/product_repository.dart';
import '../../../product/domain/repository/i_product_unit_repository.dart';
import '../../../product/data/repository/product_unit_repository.dart';
import '../../../product/domain/repository/i_unit_repository.dart';
import '../../../product/data/repository/unit_repository.dart';
import '../../application/provider/shop_providers.dart';
import '../../../product/application/category_notifier.dart';

/// 库存查询服务
/// 提供库存信息的复合查询功能，包含产品、单位、分类等详细信息
class InventoryQueryService {
  final IInventoryRepository _inventoryRepository;
  final IProductRepository _productRepository;
  final IProductUnitRepository _productUnitRepository;
  final IUnitRepository _unitRepository;
  final Ref _ref;

  InventoryQueryService(
    this._inventoryRepository,
    this._productRepository,
    this._productUnitRepository,
    this._unitRepository,
    this._ref,
  );

  /// 获取库存详细信息
  /// 包含产品名称、图片、库存数量、单位、分类、店铺等信息
  /// 新入库的记录会显示在顶部
  Future<List<Map<String, dynamic>>> getInventoryWithDetails({
    String? shopFilter,
    String? categoryFilter,
    String? statusFilter,
  }) async {
    try {
      print('📦 库存查询服务：开始获取库存详细信息');

      // 1. 获取所有库存记录
      List<dynamic> inventoryList;
      if (shopFilter != null && shopFilter != '所有仓库') {
        // TODO: 根据店铺名称查找shopId，然后查询该店铺的库存
        inventoryList = await _inventoryRepository.getAllInventory();
      } else {
        inventoryList = await _inventoryRepository.getAllInventory();
      }

      print('📦 库存查询服务：获取到 ${inventoryList.length} 条库存记录');

      if (inventoryList.isEmpty) {
        return [];
      }

      // 2. 获取所有相关的产品信息
      final allProducts = await _productRepository.getAllProducts();
      final productMap = {for (var p in allProducts) p.id: p};
      print('📦 库存查询服务：获取到 ${allProducts.length} 个产品');

      // 3. 获取所有单位信息
      final allUnits = await _unitRepository.getAllUnits();
      final unitMap = {for (var u in allUnits) u.id: u};
      print('📦 库存查询服务：获取到 ${allUnits.length} 个单位'); // 4. 获取所有分类信息
      final allCategories = await _ref.read(allCategoriesStreamProvider.future);
      final categoryMap = {for (var c in allCategories) c.id: c};
      print('📦 库存查询服务：获取到 ${allCategories.length} 个分类');

      // 5. 获取所有店铺信息
      final allShops = await _ref.read(allShopsProvider.future);
      final shopMap = {for (var s in allShops) s.id: s};
      print('📦 库存查询服务：获取到 ${allShops.length} 个店铺');

      // 6. 构建详细的库存信息列表
      final result = <Map<String, dynamic>>[];

      // 先按时间排序，最新的在前
      inventoryList.sort((a, b) {
        if (a.updatedAt != null && b.updatedAt != null) {
          return b.updatedAt!.compareTo(a.updatedAt!);
        }
        if (a.updatedAt != null) return -1;
        if (b.updatedAt != null) return 1;
        return 0;
      });

      for (final inventory in inventoryList) {
        final product = productMap[inventory.productId];
        if (product == null) {
          print('📦 库存查询服务：警告 - 找不到产品ID: ${inventory.productId}');
          continue;
        }

        // 获取产品的基础单位
        String unitName = '个'; // 默认单位
        try {
          final baseUnit = await _productUnitRepository.getBaseUnitForProduct(
            inventory.productId,
          );
          if (baseUnit != null) {
            final unit = unitMap[baseUnit.unitId];
            if (unit != null) {
              unitName = unit.name;
            }
          } else if (product.unitId != null) {
            // 如果没有配置产品单位，使用产品主表的单位
            final unit = unitMap[product.unitId!];
            if (unit != null) {
              unitName = unit.name;
            }
          }
        } catch (e) {
          print('📦 库存查询服务：获取单位失败: $e');
        }

        // 获取分类名称
        String? categoryName;
        if (product.categoryId != null) {
          final category = categoryMap[product.categoryId];
          categoryName = category?.name;
        }

        // 获取店铺名称
        String shopName = '未知店铺';
        final shop = shopMap[inventory.shopId];
        if (shop != null) {
          shopName = shop.name;
        }

        // 应用筛选条件
        bool shouldInclude = true;

        // 分类筛选
        if (categoryFilter != null && categoryFilter != '所有分类') {
          if (categoryName != categoryFilter) {
            shouldInclude = false;
          }
        }

        // 店铺筛选
        if (shopFilter != null && shopFilter != '所有仓库') {
          if (shopName != shopFilter) {
            shouldInclude = false;
          }
        }

        // 库存状态筛选
        if (statusFilter != null && statusFilter != '库存状态') {
          switch (statusFilter) {
            case '正常':
              if (inventory.quantity <= 10) shouldInclude = false;
              break;
            case '低库存':
              if (inventory.quantity <= 0 || inventory.quantity > 10) {
                shouldInclude = false;
              }
              break;
            case '缺货':
              if (inventory.quantity > 0) shouldInclude = false;
              break;
          }
        }

        if (!shouldInclude) continue;

        // 构建库存项目数据
        final inventoryItem = {
          'id': inventory.id,
          'productName': product.name,
          'productImage': product.image,
          'quantity': inventory.quantity,
          'unit': unitName,
          'shopId': inventory.shopId,
          'shopName': shopName,
          'categoryId': product.categoryId,
          'categoryName': categoryName ?? '未分类',
          'productId': inventory.productId,
          'batchNumber': inventory.batchNumber,
        };

        result.add(inventoryItem);
      }

      print('📦 库存查询服务：筛选后得到 ${result.length} 条记录');
      return result;
    } catch (e) {
      print('📦 库存查询服务：获取库存详细信息失败: $e');
      rethrow;
    }
  }
}

/// 库存查询服务 Provider
final inventoryQueryServiceProvider = Provider<InventoryQueryService>((ref) {
  final inventoryRepository = ref.watch(inventoryRepositoryProvider);
  final productRepository = ref.watch(productRepositoryProvider);
  final productUnitRepository = ref.watch(productUnitRepositoryProvider);
  final unitRepository = ref.watch(unitRepositoryProvider);

  return InventoryQueryService(
    inventoryRepository,
    productRepository,
    productUnitRepository,
    unitRepository,
    ref,
  );
});
