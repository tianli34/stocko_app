/// 货品供应商关联表使用示例
///
/// 此文件展示了如何使用ProductSupplierDao来管理商品和供应商之间的关联关系

import 'package:drift/drift.dart';
import '../core/database/database.dart';
import '../features/purchase/data/dao/product_supplier_dao.dart';

class ProductSupplierService {
  final ProductSupplierDao _dao;

  ProductSupplierService(this._dao);

  /// 为商品添加供应商
  ///
  /// [productId] 商品ID
  /// [supplierId] 供应商ID
  /// [unitId] 单位ID，指定供货单位
  /// [supplierProductCode] 供应商商品编号
  /// [supplyPrice] 供货价格
  /// [isPrimary] 是否为主要供应商
  Future<void> addProductSupplier({
    required String productId,
    required String supplierId,
    required String unitId,
    String? supplierProductCode,
    String? supplierProductName,
    double? supplyPrice,
    int? minimumOrderQuantity,
    int? leadTimeDays,
    bool isPrimary = false,
    String? remarks,
  }) async {
    // 检查关联是否已存在
    final exists = await _dao.existsProductSupplierWithUnit(
      productId,
      supplierId,
      unitId,
    );
    if (exists) {
      throw Exception('该商品、供应商和单位的关联已存在');
    }

    // 生成关联ID
    final id =
        '${productId}_${supplierId}_${unitId}_${DateTime.now().millisecondsSinceEpoch}';

    final companion = ProductSuppliersTableCompanion.insert(
      id: id,
      productId: productId,
      supplierId: supplierId,
      unitId: unitId,
      supplierProductCode: Value(supplierProductCode),
      supplierProductName: Value(supplierProductName),
      supplyPrice: Value(supplyPrice),
      minimumOrderQuantity: Value(minimumOrderQuantity),
      leadTimeDays: Value(leadTimeDays),
      isPrimary: Value(isPrimary),
      remarks: Value(remarks),
    );

    await _dao.insertProductSupplier(companion);

    // 如果设为主要供应商，需要将其他供应商设为非主要
    if (isPrimary) {
      await _dao.setPrimarySupplier(productId, supplierId);
    }
  }

  /// 获取商品指定单位的所有供应商
  Future<List<ProductSuppliersTableData>> getProductSuppliersForUnit(
    String productId,
    String unitId,
  ) {
    return _dao.getSuppliersByProductIdAndUnitId(productId, unitId);
  }

  /// 获取商品的所有供应商
  Future<List<ProductSuppliersTableData>> getProductSuppliers(
    String productId,
  ) {
    return _dao.getSuppliersByProductId(productId);
  }

  /// 获取商品指定单位的主要供应商
  Future<ProductSuppliersTableData?> getPrimarySupplierForUnit(
    String productId,
    String unitId,
  ) {
    return _dao.getPrimarySupplierByProductIdAndUnitId(productId, unitId);
  }

  /// 获取商品的主要供应商（所有单位）
  Future<ProductSuppliersTableData?> getPrimarySupplier(String productId) {
    return _dao.getPrimarySupplierByProductId(productId);
  }

  /// 获取供应商的所有商品
  Future<List<ProductSuppliersTableData>> getSupplierProducts(
    String supplierId,
  ) {
    return _dao.getProductsBySupplierId(supplierId);
  }

  /// 更新供货价格
  Future<void> updateSupplyPrice(String id, double newPrice) async {
    final existing = await _dao.getProductSupplierById(id);
    if (existing == null) {
      throw Exception('货品供应商关联不存在');
    }

    final updated = existing.copyWith(
      supplyPrice: Value(newPrice),
      updatedAt: DateTime.now(),
    );

    await _dao.updateProductSupplier(updated);
  }

  /// 设置主要供应商（所有单位）
  Future<void> setPrimarySupplier(String productId, String supplierId) {
    return _dao.setPrimarySupplier(productId, supplierId);
  }

  /// 删除商品供应商关联
  Future<void> removeProductSupplier(String id) {
    return _dao.deleteProductSupplier(id);
  }

  /// 删除商品的所有供应商关联
  Future<void> removeAllProductSuppliers(String productId) {
    return _dao.deleteProductSuppliersByProductId(productId);
  }

  /// 删除供应商的所有商品关联
  Future<void> removeAllSupplierProducts(String supplierId) {
    return _dao.deleteProductSuppliersBySupplierId(supplierId);
  }

  /// 批量导入商品供应商关联
  Future<void> batchImportProductSuppliers(
    List<Map<String, dynamic>> data,
  ) async {
    for (final item in data) {
      try {
        await addProductSupplier(
          productId: item['productId'],
          supplierId: item['supplierId'],
          unitId: item['unitId'],
          supplierProductCode: item['supplierProductCode'],
          supplierProductName: item['supplierProductName'],
          supplyPrice: item['supplyPrice']?.toDouble(),
          minimumOrderQuantity: item['minimumOrderQuantity'],
          leadTimeDays: item['leadTimeDays'],
          isPrimary: item['isPrimary'] ?? false,
          remarks: item['remarks'],
        );
      } catch (e) {
        print('导入失败: ${item['productId']} - ${item['supplierId']}: $e');
      }
    }
  }

  /// 获取所有有效的货品供应商关联
  Future<List<ProductSuppliersTableData>> getAllActiveProductSuppliers() {
    return _dao.getActiveProductSuppliers();
  }
}

/// 使用示例：
/// 
/// ```dart
/// // 获取数据库实例
/// final database = ref.read(databaseProvider);
/// final service = ProductSupplierService(database.productSupplierDao);
/// 
/// // 为商品添加供应商
/// await service.addProductSupplier(
///   productId: 'product_001',
///   supplierId: 'supplier_001',
///   supplierProductCode: 'SUP001-ABC',
///   supplyPrice: 15.50,
///   isPrimary: true,
/// );
/// 
/// // 获取商品的所有供应商
/// final suppliers = await service.getProductSuppliers('product_001');
/// 
/// // 获取主要供应商
/// final primarySupplier = await service.getPrimarySupplier('product_001');
/// 
/// // 更新供货价格
/// await service.updateSupplyPrice('relation_id', 16.00);
/// ```
