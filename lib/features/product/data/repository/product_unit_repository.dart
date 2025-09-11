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
  Future<int> addProductUnit(UnitProduct unitProduct) async {
    try {
      print('🗃️ 仓储层：添加产品单位，ID: ${unitProduct.id}');
      return await _productUnitDao.insertProductUnit(
        _productUnitToCompanion(unitProduct),
      );
    } catch (e) {
      print('🗃️ 仓储层：添加产品单位失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> addMultipleProductUnits(List<UnitProduct> productUnits) async {
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
  Future<UnitProduct?> getProductUnitById(int id) async {
    try {
      final data = await _productUnitDao.getProductUnitById(id);
      return data != null ? _dataToProductUnit(data) : null;
    } catch (e) {
      print('🗃️ 仓储层：根据ID获取产品单位失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<UnitProduct>> getProductUnitsByProductId(int productId) async {
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
  Future<List<UnitProduct>> getAllProductUnits() async {
    try {
      final dataList = await _productUnitDao.getAllProductUnits();
      return dataList.map(_dataToProductUnit).toList();
    } catch (e) {
      print('🗃️ 仓储层：获取所有产品单位失败: $e');
      rethrow;
    }
  }

  @override
  Stream<List<UnitProduct>> watchProductUnitsByProductId(int productId) {
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
  Future<bool> updateProductUnit(UnitProduct unitProduct) async {
    try {
      print('🗃️ 仓储层：更新产品单位，ID: ${unitProduct.id}');
      return await _productUnitDao.updateProductUnit(
        _productUnitToCompanion(unitProduct),
      );
    } catch (e) {
      print('🗃️ 仓储层：更新产品单位失败: $e');
      rethrow;
    }
  }

  @override
  Future<int> deleteProductUnit(int id) async {
    try {
      print('🗃️ 仓储层：删除产品单位，ID: $id');
      return await _productUnitDao.deleteProductUnit(id);
    } catch (e) {
      print('🗃️ 仓储层：删除产品单位失败: $e');
      rethrow;
    }
  }

  @override
  Future<int> deleteProductUnitsByProductId(int productId) async {
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
    int productId,
    int unitId,
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
  Future<UnitProduct?> getBaseUnitForProduct(int productId) async {
    try {
      final data = await _productUnitDao.getBaseUnitForProduct(productId);
      return data != null ? _dataToProductUnit(data) : null;
    } catch (e) {
      print('🗃️ 仓储层：获取产品基础单位失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> upsertProductUnit(UnitProduct unitProduct) async {
    try {
      print('🗃️ 仓储层：更新或插入产品单位，ID: ${unitProduct.id}');
      await _productUnitDao.upsertProductUnit(
        _productUnitToCompanion(unitProduct),
      );
    } catch (e) {
      print('🗃️ 仓储层：更新或插入产品单位失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> upsertMultipleProductUnits(
    List<UnitProduct> productUnits,
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
    int productId,
    List<UnitProduct> productUnits,
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
  UnitProductCompanion _productUnitToCompanion(UnitProduct unitProduct) {
    print('==================【批发价调试】==================');
    print('UnitProduct ID: ${unitProduct.id}');
    print('SELLING PRICE: ${unitProduct.sellingPriceInCents}');
    print('WHOLESALE PRICE: ${unitProduct.wholesalePriceInCents}');
    print(
      'productId: ${unitProduct.productId}, unitId: ${unitProduct.unitId}, conversionRate: ${unitProduct.conversionRate}',
    );
    print('=================================================');
    return UnitProductCompanion(
      id: unitProduct.id == null
          ? const Value.absent()
          : Value(unitProduct.id!),
      productId: Value(unitProduct.productId),
      unitId: Value(unitProduct.unitId),
      conversionRate: Value(unitProduct.conversionRate),
      sellingPriceInCents: unitProduct.sellingPriceInCents != null
          ? Value(unitProduct.sellingPriceInCents!)
          : const Value.absent(),
      wholesalePriceInCents: unitProduct.wholesalePriceInCents != null
          ? Value(unitProduct.wholesalePriceInCents!)
          : const Value.absent(),
      lastUpdated: Value(unitProduct.lastUpdated ?? DateTime.now()),
    );
  }

  /// 将数据库数据转换为ProductUnit模型
  UnitProduct _dataToProductUnit(UnitProductData data) {
    print('==================【批发价回显调试】==================');
    print('UnitProduct ID: ${data.id}');
    print('SELLING PRICE: ${data.sellingPriceInCents}');
    print('WHOLESALE PRICE: ${data.wholesalePriceInCents}');
    print(
      'productId: ${data.productId}, unitId: ${data.unitId}, conversionRate: ${data.conversionRate}',
    );
    print('=====================================================');
    return UnitProduct(
      id: data.id,
      productId: data.productId,
      unitId: data.unitId,
      conversionRate: data.conversionRate,
      sellingPriceInCents: data.sellingPriceInCents,
      wholesalePriceInCents: data.wholesalePriceInCents,
      lastUpdated: data.lastUpdated,
    );
  }
}

/// UnitProduct Repository Provider
final productUnitRepositoryProvider = Provider<IProductUnitRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return ProductUnitRepository(database);
});
