// lib/features/product/application/services/category_resolver_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logger/product_logger.dart';
import '../../domain/model/category.dart';
import '../category_notifier.dart';
import '../category_service.dart';

/// 类别解析服务
/// 
/// 负责解析或创建类别，返回 categoryId
class CategoryResolverService {
  final Ref _ref;

  CategoryResolverService(this._ref);

  /// 解析类别ID
  /// 
  /// 如果 [selectedCategoryId] 不为空，直接返回
  /// 如果 [newCategoryName] 不为空，查找或创建类别
  /// 
  /// 返回类别ID，如果无法解析则返回 null
  Future<int?> resolve({
    int? selectedCategoryId,
    String newCategoryName = '',
  }) async {
    ProductLogger.debug(
      '开始解析类别: selectedId=$selectedCategoryId, newName="$newCategoryName"',
      tag: 'CategoryResolver',
    );

    // 如果已选择类别，直接返回
    if (selectedCategoryId != null) {
      ProductLogger.debug('使用已选择的类别ID: $selectedCategoryId', tag: 'CategoryResolver');
      return selectedCategoryId;
    }

    // 如果没有新类别名称，返回 null
    final trimmedName = newCategoryName.trim();
    if (trimmedName.isEmpty) {
      ProductLogger.debug('无类别信息，返回 null', tag: 'CategoryResolver');
      return null;
    }

    // 查找或创建类别
    return _findOrCreateCategory(trimmedName);
  }

  /// 查找或创建类别
  Future<int?> _findOrCreateCategory(String categoryName) async {
    ProductLogger.debug('查找或创建类别: "$categoryName"', tag: 'CategoryResolver');

    // 加载现有类别
    final categoryNotifier = _ref.read(categoryListProvider.notifier);
    await categoryNotifier.loadCategories();
    final categories = _ref.read(categoryListProvider).categories;

    // 查找是否已存在
    CategoryModel? existingCategory;
    try {
      existingCategory = categories.firstWhere(
        (c) => c.name.toLowerCase() == categoryName.toLowerCase(),
      );
    } catch (e) {
      existingCategory = null;
    }

    if (existingCategory != null) {
      ProductLogger.debug(
        '找到已存在的类别: ID=${existingCategory.id}',
        tag: 'CategoryResolver',
      );
      return existingCategory.id;
    }

    // 创建新类别
    ProductLogger.debug('创建新类别: "$categoryName"', tag: 'CategoryResolver');
    final service = _ref.read(categoryServiceProvider);
    final newCategoryId = await service.addCategory(name: categoryName);

    ProductLogger.debug('新类别创建成功: ID=$newCategoryId', tag: 'CategoryResolver');

    // 刷新类别缓存
    _ref.invalidate(categoryListProvider);

    return newCategoryId;
  }
}

/// CategoryResolverService Provider
final categoryResolverServiceProvider = Provider<CategoryResolverService>((ref) {
  return CategoryResolverService(ref);
});
