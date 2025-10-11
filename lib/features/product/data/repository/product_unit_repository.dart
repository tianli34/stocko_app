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
      print('🗃️ 仓储层：差异更新产品单位配置，产品ID: $productId，新单位数量: ${productUnits.length}');

      // 开启事务
      await _productUnitDao.db.transaction(() async {
        // 1. 获取现有的产品单位配置
        final existingUnits = await _productUnitDao.getProductUnitsByProductId(productId);
        print('🗃️ 仓储层：现有单位数量: ${existingUnits.length}');

        // 2. 构建现有单位的映射表（使用 unitId 作为唯一标识，符合数据库唯一键约束）
        final existingMap = <int, UnitProductData>{};
        for (final unit in existingUnits) {
          existingMap[unit.unitId] = unit;
        }

        // 3. 构建新单位的映射表
        final newMap = <int, UnitProduct>{};
        for (final unit in productUnits) {
          newMap[unit.unitId] = unit;
        }

        // 4. 找出需要删除的单位（存在于旧列表但不在新列表中）
        final toDelete = <int>[];
        for (final entry in existingMap.entries) {
          if (!newMap.containsKey(entry.key)) {
            toDelete.add(entry.value.id);
            print('🗃️ 仓储层：标记删除 - ID: ${entry.value.id}, unitId: ${entry.value.unitId}');
          }
        }

        // 5. 找出需要新增和更新的单位
        final toInsert = <UnitProductCompanion>[];
        final toUpdate = <UnitProductCompanion>[];
        
        for (final entry in newMap.entries) {
          if (existingMap.containsKey(entry.key)) {
            // 存在于旧列表中，需要更新
            final existingUnit = existingMap[entry.key]!;
            final newUnit = entry.value;
            
            // 检查是否真的需要更新（换算率、价格或其他字段是否变化）
            if (existingUnit.conversionRate != newUnit.conversionRate ||
                existingUnit.sellingPriceInCents != newUnit.sellingPriceInCents ||
                existingUnit.wholesalePriceInCents != newUnit.wholesalePriceInCents) {
              toUpdate.add(_productUnitToCompanion(newUnit.copyWith(id: existingUnit.id)));
              print('🗃️ 仓储层：标记更新 - ID: ${existingUnit.id}, unitId: ${newUnit.unitId}');
            } else {
              print('🗃️ 仓储层：无需更新 - ID: ${existingUnit.id}, unitId: ${newUnit.unitId}');
            }
          } else {
            // 不存在于旧列表中，需要新增
            toInsert.add(_productUnitToCompanion(entry.value));
            print('🗃️ 仓储层：标记新增 - unitId: ${entry.value.unitId}');
          }
        }

        // 6. 执行删除操作
        if (toDelete.isNotEmpty) {
          print('🗃️ 仓储层：执行删除操作，数量: ${toDelete.length}');
          for (final id in toDelete) {
            await _productUnitDao.deleteProductUnit(id);
          }
        }

        // 7. 执行更新操作
        if (toUpdate.isNotEmpty) {
          print('🗃️ 仓储层：执行更新操作，数量: ${toUpdate.length}');
          for (final companion in toUpdate) {
            await _productUnitDao.updateProductUnit(companion);
          }
        }

        // 8. 执行新增操作
        if (toInsert.isNotEmpty) {
          print('🗃️ 仓储层：执行新增操作，数量: ${toInsert.length}');
          await _productUnitDao.insertMultipleProductUnits(toInsert);
        }
      });

      print('🗃️ 仓储层：差异更新产品单位配置完成');
    } catch (e) {
      print('🗃️ 仓储层：差异更新产品单位配置失败: $e');
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
