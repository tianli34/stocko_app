import '../../domain/repository/i_product_repository.dart';
import '../../domain/model/product.dart';
import '../../../../core/database/database.dart';
import '../dao/product_dao.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 产品仓储实现类
/// 基于本地数据库的产品数据访问层实现
class ProductRepository implements IProductRepository {
  final ProductDao _productDao;

  ProductRepository(AppDatabase database) : _productDao = database.productDao;
  @override
  Future<int> addProduct(Product product) async {
    try {
      print('🗃️ 仓储层：添加产品，ID: ${product.id}, 名称: ${product.name}');
      await _productDao.insertProduct(_productToCompanion(product));
      // 由于我们使用的是String ID，返回一个表示成功的值
      return 1;
    } catch (e) {
      print('🗃️ 仓储层：添加产品失败: $e');
      throw Exception('添加产品失败: $e');
    }
  }

  @override
  Future<bool> updateProduct(Product product) async {
    // 检查产品ID是否为空
    if (product.id.isEmpty) {
      throw Exception('产品ID不能为空');
    }

    try {
      return await _productDao.updateProduct(_productToCompanion(product));
    } catch (e) {
      throw Exception('更新产品失败: $e');
    }
  }

  @override
  Future<int> deleteProduct(String id) async {
    print('🗃️ 仓储层：删除产品，ID: $id');
    try {
      final result = await _productDao.deleteProduct(id);
      print('🗃️ 仓储层：删除结果，影响行数: $result');
      return result;
    } catch (e) {
      print('🗃️ 仓储层：删除时发生异常: $e');
      throw Exception('删除产品失败: $e');
    }
  }

  @override
  Future<Product?> getProductById(String id) async {
    try {
      final result = await _productDao.getProductById(id);
      return result != null ? _dataToProduct(result) : null;
    } catch (e) {
      throw Exception('获取产品失败: $e');
    }
  }

  @override
  Stream<List<Product>> watchAllProducts() {
    return _productDao
        .watchAllProducts()
        .map((data) => data.map(_dataToProduct).toList())
        .handleError((error) {
          throw Exception('监听产品列表失败: $error');
        });
  }

  @override
  Future<List<Product>> getAllProducts() async {
    try {
      final data = await _productDao.getAllProducts();
      return data.map(_dataToProduct).toList();
    } catch (e) {
      throw Exception('获取产品列表失败: $e');
    }
  }

  /// 根据条件查询产品
  @override
  Future<List<Product>> getProductsByCondition({
    String? categoryId,
    String? status,
    String? keyword,
  }) async {
    try {
      final data = await _productDao.getProductsByCondition(
        categoryId: categoryId,
        status: status,
        keyword: keyword,
      );
      return data.map(_dataToProduct).toList();
    } catch (e) {
      throw Exception('根据条件查询产品失败: $e');
    }
  }

  /// 监听指定类别的产品
  @override
  Stream<List<Product>> watchProductsByCategory(String categoryId) {
    return _productDao
        .watchProductsByCategory(categoryId)
        .map((data) => data.map(_dataToProduct).toList())
        .handleError((error) {
          throw Exception('监听类别产品失败: $error');
        });
  }

  /// 根据条码查询产品
  @override
  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final result = await _productDao.getProductByBarcode(barcode);
      return result != null ? _dataToProduct(result) : null;
    } catch (e) {
      throw Exception('根据条码查询产品失败: $e');
    }
  }

  /// 获取库存预警产品
  Future<List<Product>> getStockWarningProducts() async {
    try {
      final data = await _productDao.getStockWarningProducts();
      return data.map(_dataToProduct).toList();
    } catch (e) {
      throw Exception('获取库存预警产品失败: $e');
    }
  }

  /// 批量添加产品
  Future<void> addMultipleProducts(List<Product> products) async {
    try {
      final companions = products.map(_productToCompanion).toList();
      await _productDao.insertMultipleProducts(companions);
    } catch (e) {
      throw Exception('批量添加产品失败: $e');
    }
  }

  /// 批量更新产品
  Future<void> updateMultipleProducts(List<Product> products) async {
    try {
      final companions = products.map(_productToCompanion).toList();
      await _productDao.updateMultipleProducts(companions);
    } catch (e) {
      throw Exception('批量更新产品失败: $e');
    }
  }

  /// 检查产品是否存在
  Future<bool> productExists(String id) async {
    try {
      return await _productDao.productExists(id);
    } catch (e) {
      throw Exception('检查产品是否存在失败: $e');
    }
  }

  /// 获取产品数量
  Future<int> getProductCount() async {
    try {
      return await _productDao.getProductCount();
    } catch (e) {
      throw Exception('获取产品数量失败: $e');
    }
  }

  /// 将Product模型转换为数据库Companion
  ProductsTableCompanion _productToCompanion(Product product) {
    return ProductsTableCompanion(
      id: Value(product.id),
      name: Value(product.name),
      sku: Value(product.sku),
      image: Value(product.image),
      categoryId: Value(product.categoryId),
      unitId: Value(product.unitId),
      specification: Value(product.specification),
      brand: Value(product.brand),
      suggestedRetailPrice: Value(product.suggestedRetailPrice),
      retailPrice: Value(product.retailPrice),
      promotionalPrice: Value(product.promotionalPrice),
      stockWarningValue: Value(product.stockWarningValue),
      shelfLife: Value(product.shelfLife),
      shelfLifeUnit: Value(product.shelfLifeUnit),
      enableBatchManagement: Value(product.enableBatchManagement),
      status: Value(product.status),
      remarks: Value(product.remarks),
      lastUpdated: Value(product.lastUpdated),
    );
  }

  /// 将数据库数据转换为Product模型
  Product _dataToProduct(ProductsTableData data) {
    return Product(
      id: data.id, // ID现在是必需的，不需要null检查
      name: data.name,
      sku: data.sku,
      image: data.image,
      categoryId: data.categoryId,
      unitId: data.unitId,
      specification: data.specification,
      brand: data.brand,
      suggestedRetailPrice: data.suggestedRetailPrice,
      retailPrice: data.retailPrice,
      promotionalPrice: data.promotionalPrice,
      stockWarningValue: data.stockWarningValue,
      shelfLife: data.shelfLife,
      shelfLifeUnit: data.shelfLifeUnit,
      enableBatchManagement: data.enableBatchManagement,
      status: data.status,
      remarks: data.remarks,
      lastUpdated: data.lastUpdated,
    );
  }
}

/// 产品仓储 Provider
/// 提供 IProductRepository 的实现实例
final productRepositoryProvider = Provider<IProductRepository>((ref) {
  return ProductRepository(ref.watch(appDatabaseProvider));
});
