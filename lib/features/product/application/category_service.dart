import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repository/category_repository.dart';
import '../data/repository/product_repository.dart';
import '../domain/model/category.dart';
import '../domain/model/product.dart';
import '../domain/repository/i_category_repository.dart';
import '../domain/repository/i_product_repository.dart';

/// 类别应用服务
/// 处理类别相关的业务逻辑和状态管理
class CategoryService {
  final ICategoryRepository _repository;
  final IProductRepository? _productRepository;

  CategoryService(this._repository, [this._productRepository]);

  /// 添加新类别
  Future<void> addCategory({
    int? id,
    required String name,
    int? parentId,
  }) async {
    // 验证类别名称
    if (name.trim().isEmpty) {
      throw Exception('类别名称不能为空');
    }

    // 检查名称是否已存在
    final exists = await _repository.isCategoryNameExists(
      name.trim(),
      parentId,
    );
    if (exists) {
      throw Exception('在当前层级下，类别名称已存在');
    }

    // 如果有父类别，验证父类别是否存在
    if (parentId != null && parentId>0) {
      final parentCategory = await _repository.getCategoryById(parentId);
      if (parentCategory == null) {
        throw Exception('父类别不存在');
      }
    }

    final category = CategoryModel(
      name: name.trim(),
      parentId: parentId,
    );

    await _repository.addCategory(category);
  }

  /// 更新类别
  Future<void> updateCategory({
    required int id,
    required String name,
    int? parentId,
  }) async {
    // 验证类别是否存在
    final existingCategory = await _repository.getCategoryById(id);
    if (existingCategory == null) {
      throw Exception('类别不存在');
    }

    // 验证类别名称
    if (name.trim().isEmpty) {
      throw Exception('类别名称不能为空');
    }

    // 检查名称是否已存在（排除当前类别）
    final exists = await _repository.isCategoryNameExists(
      name.trim(),
      parentId,
      excludeId: id,
    );
    if (exists) {
      throw Exception('在当前层级下，类别名称已存在');
    }

    // 如果有父类别，验证父类别是否存在且不是自己或子类别
    if (parentId != null && parentId>0) {
      if (parentId == id) {
        throw Exception('不能将自己设为父类别');
      }

      final parentCategory = await _repository.getCategoryById(parentId);
      if (parentCategory == null) {
        throw Exception('父类别不存在');
      }

      // 检查是否会形成循环引用
      final path = await _repository.getCategoryPath(parentId);
      if (path.any((category) => category.id == id)) {
        throw Exception('不能将子类别设为父类别');
      }
    }

    final updatedCategory = CategoryModel(
      name: name.trim(),
      parentId: parentId,
    );

    await _repository.updateCategory(updatedCategory);
  }

  /// 删除类别 - 仅删除当前类别（保留子类和产品）
  Future<void> deleteCategoryOnly(int id) async {
    // 验证类别是否存在
    final category = await _repository.getCategoryById(id);
    if (category == null) {
      throw Exception('类别不存在');
    }

    // 获取当前类别的所有子类别
    final allCategories = await _repository.getAllCategories();
    final subCategories = allCategories
        .where((cat) => cat.parentId == id)
        .toList();
    // 处理关联到当前类别的产品
    if (_productRepository != null) {
      final relatedProducts = await _productRepository.getProductsByCondition(
        categoryId: id,
      );

      for (final product in relatedProducts) {
        // 将产品的类别设置为当前类别的父类别（如果有），否则设为null
        final updatedProduct = ProductModel(
          id: product.id,
          name: product.name,
          // barcode 字段已移除，条码现在由独立的条码表管理
          sku: product.sku,
          image: product.image,
          categoryId: category.parentId, // 转移到父类别或设为null
          baseUnitId: product.baseUnitId,
          specification: product.specification,
          brand: product.brand,
          // 使用 Money 字段而非 *InCents
          suggestedRetailPrice: product.suggestedRetailPrice,
          retailPrice: product.retailPrice,
          promotionalPrice: product.promotionalPrice,
          stockWarningValue: product.stockWarningValue,
          shelfLife: product.shelfLife,
          status: product.status,
          remarks: product.remarks,
          lastUpdated: DateTime.now(),
        );
        await _productRepository.updateProduct(updatedProduct);
      }
    }

    // 处理子类别的父级关系
    if (subCategories.isNotEmpty) {
      for (final subCategory in subCategories) {
        // 将子类别的父级设置为当前类别的父级
        final updatedSubCategory = CategoryModel(
          id: subCategory.id,
          name: subCategory.name,
          parentId: category.parentId, // 继承当前类别的父级
        );
        await _repository.updateCategory(updatedSubCategory);
      }
    }

    // 删除当前类别
    await _repository.deleteCategory(id);
  }

  /// 级联删除类别及所有关联内容
  Future<void> deleteCategoryCascade(int id) async {
    // 验证类别是否存在
    final category = await _repository.getCategoryById(id);
    if (category == null) {
      throw Exception('类别不存在');
    }

    // 递归获取所有子类别（包括多层级嵌套）
    final allSubCategories = await _getAllDescendantCategories(id);

    // 获取所有需要删除的类别ID（包括当前类别）
    final allCategoryIds = [id, ...allSubCategories.map((cat) => cat.id)];
    // 删除所有关联产品
    if (_productRepository != null) {
      for (final categoryId in allCategoryIds) {
        final relatedProducts = await _productRepository.getProductsByCondition(
          categoryId: categoryId,
        );
        for (final product in relatedProducts) {
          if (product.id != null) {
            await _productRepository.deleteProduct(product.id!);
          }
        }
      }
    }

    // 按层级从深到浅删除类别（先删除子类别，再删除父类别）
    final categoryLevels = <int, List<CategoryModel>>{};

    // 为当前类别和所有子类别计算层级
    final currentCategory = category;
    final currentPath = await _repository.getCategoryPath(id);
    final currentLevel = currentPath.length;
    categoryLevels.putIfAbsent(currentLevel, () => []).add(currentCategory);

    for (final subCategory in allSubCategories) {
      if (subCategory.id != null) {
        final path = await _repository.getCategoryPath(subCategory.id!);
        final level = path.length;
        categoryLevels.putIfAbsent(level, () => []).add(subCategory);
      }
    }

    // 从最深层开始删除
    final sortedLevels = categoryLevels.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    for (final level in sortedLevels) {
      for (final categoryToDelete in categoryLevels[level]!) {
        if (categoryToDelete.id != null) {
          await _repository.deleteCategory(categoryToDelete.id!);
        }
      }
    }
  }

  /// 递归获取所有后代类别
  Future<List<CategoryModel>> _getAllDescendantCategories(int parentId) async {
    final allCategories = await _repository.getAllCategories();
    final result = <CategoryModel>[];

    // 获取直接子类别
    final directSubCategories = allCategories
        .where((cat) => cat.parentId == parentId)
        .toList();

    for (final subCategory in directSubCategories) {
      result.add(subCategory);
      // 递归获取子类别的子类别
      if (subCategory.id != null) {
        final descendants = await _getAllDescendantCategories(subCategory.id!);
        result.addAll(descendants);
      }
    }

    return result;
  }

  /// 兼容原有的删除方法（保持向后兼容）
  Future<void> deleteCategory(int id) async {
    // 默认使用级联删除模式
    await deleteCategoryCascade(id);
  }

  /// 获取所有类别
  Future<List<CategoryModel>> getAllCategories() async {
    return await _repository.getAllCategories();
  }

  /// 获取根类别
  Future<List<CategoryModel>> getRootCategories() async {
    return await _repository.getRootCategories();
  }

  /// 获取子类别
  Future<List<CategoryModel>> getSubCategories(int parentId) async {
    return await _repository.getCategoriesByParentId(parentId);
  }

  /// 获取类别路径
  Future<List<CategoryModel>> getCategoryPath(int categoryId) async {
    return await _repository.getCategoryPath(categoryId);
  }

  /// 监听所有类别变化
  Stream<List<CategoryModel>> watchAllCategories() {
    return _repository.watchAllCategories();
  }

  /// 监听根类别变化
  Stream<List<CategoryModel>> watchRootCategories() {
    return _repository.watchRootCategories();
  }

  /// 监听子类别变化
  Stream<List<CategoryModel>> watchSubCategories(int parentId) {
    return _repository.watchCategoriesByParentId(parentId);
  }

  // /// 生成新的类别ID
  // String generateCategoryId() {
  //   return 'cat_${DateTime.now().millisecondsSinceEpoch}';
  // }
}

/// CategoryModel Service Provider
final categoryServiceProvider = Provider<CategoryService>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  final productRepository = ref.watch(productRepositoryProvider);
  return CategoryService(repository, productRepository);
});
