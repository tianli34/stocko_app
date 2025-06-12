import '../../domain/repository/i_product_unit_repository.dart';
import '../../domain/model/product_unit.dart';
import '../../../../core/database/database.dart';
import '../dao/product_unit_dao.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 产品单位仓储实现类
/// 基于本地数据库的产品单位数据访问层实现
class ProductUnitRepository implements IProductUnitRepository {
  final ProductUnitDao _productUnitDao;

  ProductUnitRepository(AppDatabase database)
    : _productUnitDao = database.productUnitDao;

  @override
  Future<int> addProductUnit(ProductUnit productUnit) async {
    try {
      print('🗃️ 仓储层：添加产品单位，ID: ${productUnit.productUnitId}');
      return await _productUnitDao.insertProductUnit(
        _productUnitToCompanion(productUnit),
      );
    } catch (e) {
      print('🗃️ 仓储层：添加产品单位失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> addMultipleProductUnits(List<ProductUnit> productUnits) async {
    try {
      print('🗃️ 仓储层：批量添加产品单位，数量: ${productUnits.length}');
      final companions = productUnits.map(_productUnitToCompanion).toList();
      await _productUnitDao.insertMultipleProductUnits(companions);
    } catch (e) {
      print('🗃️ 仓储层：批量添加产品单位失败: $e');
      rethrow;
    }
  }

  @override
  Future<ProductUnit?> getProductUnitById(String productUnitId) async {
    try {
      final data = await _productUnitDao.getProductUnitById(productUnitId);
      return data != null ? _dataToProductUnit(data) : null;    } catch (e) {
      print('🗃️ 仓储层：根据ID获取产品单位失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<ProductUnit>> getProductUnitsByProductId(String productId) async {
    try {
      final dataList = await _productUnitDao.getProductUnitsByProductId(
        productId,
      );
      return dataList.map(_dataToProductUnit).toList();
    } catch (e) {
      print('🗃️ 仓储层：根据产品ID获取产品单位失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<ProductUnit>> getAllProductUnits() async {
    try {
      final dataList = await _productUnitDao.getAllProductUnits();
      return dataList.map(_dataToProductUnit).toList();
    } catch (e) {
      print('🗃️ 仓储层：获取所有产品单位失败: $e');
      rethrow;
    }
  }

  @override
  Stream<List<ProductUnit>> watchProductUnitsByProductId(String productId) {
    try {
      return _productUnitDao.watchProductUnitsByProductId(productId).map((
        dataList,
      ) {
        return dataList.map(_dataToProductUnit).toList();
      });
    } catch (e) {
      print('🗃️ 仓储层：监听产品单位失败: $e');
      rethrow;
    }
  }

  @override
  Future<bool> updateProductUnit(ProductUnit productUnit) async {
    try {
      print('🗃️ 仓储层：更新产品单位，ID: ${productUnit.productUnitId}');
      return await _productUnitDao.updateProductUnit(
        _productUnitToCompanion(productUnit),
      );
    } catch (e) {
      print('🗃️ 仓储层：更新产品单位失败: $e');
      rethrow;
    }
  }

  @override
  Future<int> deleteProductUnit(String productUnitId) async {
    try {
      print('🗃️ 仓储层：删除产品单位，ID: $productUnitId');
      return await _productUnitDao.deleteProductUnit(productUnitId);
    } catch (e) {
      print('🗃️ 仓储层：删除产品单位失败: $e');
      rethrow;
    }
  }

  @override
  Future<int> deleteProductUnitsByProductId(String productId) async {
    try {
      print('🗃️ 仓储层：删除产品的所有单位，产品ID: $productId');
      return await _productUnitDao.deleteProductUnitsByProductId(productId);
    } catch (e) {
      print('🗃️ 仓储层：删除产品单位失败: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isUnitConfiguredForProduct(
    String productId,
    String unitId,
  ) async {
    try {
      return await _productUnitDao.isUnitConfiguredForProduct(
        productId,
        unitId,
      );
    } catch (e) {
      print('🗃️ 仓储层：检查产品单位配置失败: $e');
      rethrow;
    }
  }

  @override
  Future<ProductUnit?> getBaseUnitForProduct(String productId) async {
    try {
      final data = await _productUnitDao.getBaseUnitForProduct(productId);
      return data != null ? _dataToProductUnit(data) : null;
    } catch (e) {
      print('🗃️ 仓储层：获取产品基础单位失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> upsertProductUnit(ProductUnit productUnit) async {
    try {
      print('🗃️ 仓储层：更新或插入产品单位，ID: ${productUnit.productUnitId}');
      await _productUnitDao.upsertProductUnit(
        _productUnitToCompanion(productUnit),
      );
    } catch (e) {
      print('🗃️ 仓储层：更新或插入产品单位失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> upsertMultipleProductUnits(
    List<ProductUnit> productUnits,
  ) async {
    try {
      print('🗃️ 仓储层：批量更新或插入产品单位，数量: ${productUnits.length}');
      final companions = productUnits.map(_productUnitToCompanion).toList();
      await _productUnitDao.upsertMultipleProductUnits(companions);
    } catch (e) {
      print('🗃️ 仓储层：批量更新或插入产品单位失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> replaceProductUnits(
    String productId,
    List<ProductUnit> productUnits,
  ) async {
    try {
      print('🗃️ 仓储层：替换产品单位配置，产品ID: $productId，新单位数量: ${productUnits.length}');

      // 开启事务
      await _productUnitDao.db.transaction(() async {
        // 1. 删除现有的产品单位配置
        await _productUnitDao.deleteProductUnitsByProductId(productId);

        // 2. 添加新的产品单位配置
        if (productUnits.isNotEmpty) {
          final companions = productUnits.map(_productUnitToCompanion).toList();
          await _productUnitDao.insertMultipleProductUnits(companions);
        }
      });

      print('🗃️ 仓储层：产品单位配置替换完成');
    } catch (e) {
      print('🗃️ 仓储层：替换产品单位配置失败: $e');
      rethrow;
    }
  }

  /// 将ProductUnit模型转换为数据库Companion
  ProductUnitsTableCompanion _productUnitToCompanion(ProductUnit productUnit) {
    return ProductUnitsTableCompanion(
      productUnitId: Value(productUnit.productUnitId),
      productId: Value(productUnit.productId),
      unitId: Value(productUnit.unitId),
      conversionRate: Value(productUnit.conversionRate),
      barcode: productUnit.barcode != null
          ? Value(productUnit.barcode!)
          : const Value.absent(),
      sellingPrice: productUnit.sellingPrice != null
          ? Value(productUnit.sellingPrice!)
          : const Value.absent(),
      lastUpdated: Value(productUnit.lastUpdated ?? DateTime.now()),
    );
  }

  /// 将数据库数据转换为ProductUnit模型
  ProductUnit _dataToProductUnit(ProductUnitsTableData data) {
    return ProductUnit(
      productUnitId: data.productUnitId,
      productId: data.productId,
      unitId: data.unitId,
      conversionRate: data.conversionRate,
      barcode: data.barcode,
      sellingPrice: data.sellingPrice,
      lastUpdated: data.lastUpdated,
    );
  }
}

/// ProductUnit Repository Provider
final productUnitRepositoryProvider = Provider<IProductUnitRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return ProductUnitRepository(database);
});
