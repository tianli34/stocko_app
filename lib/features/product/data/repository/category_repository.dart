import '../../domain/repository/i_category_repository.dart';
import '../../domain/model/category.dart';
import '../../../../core/database/database.dart';
import '../dao/category_dao.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 类别仓储实现类
/// 基于本地数据库的类别数据访问层实现
class CategoryRepository implements ICategoryRepository {
  final CategoryDao _categoryDao;

  CategoryRepository(AppDatabase database)
    : _categoryDao = database.categoryDao;

  @override
  Future<int> addCategory(CategoryModel category) async {
    try {
      print('🏷️ 仓储层：添加类别，ID: ${category.id}, 名称: ${category.name}');
      final newId = await _categoryDao.insertCategory(_categoryToCompanion(category));
      print('🏷️ 仓储层：类别添加成功，新ID: $newId');
      return newId; // 返回新创建的类别ID
    } catch (e) {
      print('🏷️ 仓储层：添加类别失败: $e');
      throw Exception('添加类别失败: $e');
    }
  }

  @override
  Future<CategoryModel?> getCategoryById(int id) async {
    print('🏷️ 仓储层：根据ID获取类别，ID: $id');
    try {
      final categoryData = await _categoryDao.getCategoryById(id);
      if (categoryData != null) {
        final category = _categoryDataToModel(categoryData);
        print('🏷️ 仓储层：获取类别成功，名称: ${category.name}');
        return category;
      }
      print('🏷️ 仓储层：未找到指定ID的类别');
      return null;
    } catch (e) {
      print('🏷️ 仓储层：获取类别失败: $e');
      throw Exception('获取类别失败: $e');
    }
  }

  @override
  Future<List<CategoryModel>> getAllCategories() async {
    print('🏷️ 仓储层：获取所有类别');
    try {
      final categoriesData = await _categoryDao.getAllCategories();
      final categories = categoriesData.map(_categoryDataToModel).toList();
      print('🏷️ 仓储层：获取到 ${categories.length} 个类别');
      return categories;
    } catch (e) {
      print('🏷️ 仓储层：获取所有类别失败: $e');
      throw Exception('获取所有类别失败: $e');
    }
  }

  @override
  Future<List<CategoryModel>> getRootCategories() async {
    try {
      final categoriesData = await _categoryDao.getCategoriesByParentId(null);
      return categoriesData.map(_categoryDataToModel).toList();
    } catch (e) {
      throw Exception('获取根类别失败: $e');
    }
  }

  @override
  Future<List<CategoryModel>> getCategoriesByParentId(int parentId) async {
    try {
      final categoriesData = await _categoryDao.getCategoriesByParentId(
        parentId,
      );
      return categoriesData.map(_categoryDataToModel).toList();
    } catch (e) {
      throw Exception('获取子类别失败: $e');
    }
  }

  @override
  Stream<List<CategoryModel>> watchAllCategories() {
    return _categoryDao.watchAllCategories().map(
      (categoriesData) => categoriesData.map(_categoryDataToModel).toList(),
    );
  }

  @override
  Stream<List<CategoryModel>> watchRootCategories() {
    return _categoryDao.watchRootCategories().map(
      (categoriesData) => categoriesData.map(_categoryDataToModel).toList(),
    );
  }

  @override
  Stream<List<CategoryModel>> watchCategoriesByParentId(int parentId) {
    return _categoryDao
        .watchCategoriesByParentId(parentId)
        .map(
          (categoriesData) => categoriesData.map(_categoryDataToModel).toList(),
        );
  }

  @override
  Future<bool> updateCategory(CategoryModel category) async {
    if ((category.id ?? 0)>0) {
      throw Exception('类别ID不能为空');
    }

    try {
      print('🏷️ 仓储层：更新类别，ID: ${category.id}, 名称: ${category.name}');
      return await _categoryDao.updateCategory(_categoryToCompanion(category));
    } catch (e) {
      print('🏷️ 仓储层：更新类别失败: $e');
      throw Exception('更新类别失败: $e');
    }
  }

  @override
  Future<int> deleteCategory(int id) async {
    print('🏷️ 仓储层：删除类别，ID: $id');
    try {
      final result = await _categoryDao.deleteCategory(id);
      print('🏷️ 仓储层：删除结果，影响行数: $result');
      return result;
    } catch (e) {
      print('🏷️ 仓储层：删除类别失败: $e');
      throw Exception('删除类别失败: $e');
    }
  }

  @override
  Future<bool> hasSubCategories(int categoryId) async {
    try {
      return await _categoryDao.hasSubCategories(categoryId);
    } catch (e) {
      throw Exception('检查子类别失败: $e');
    }
  }

  @override
  Future<bool> isCategoryNameExists(
    String name,
    int? parentId, {
    int? excludeId,
  }) async {
    try {
      return await _categoryDao.isCategoryNameExists(
        name,
        parentId,
        excludeId: excludeId,
      );
    } catch (e) {
      throw Exception('检查类别名称失败: $e');
    }
  }

  @override
  Future<List<CategoryModel>> getCategoryPath(int categoryId) async {
    try {
      final categoriesData = await _categoryDao.getCategoryPath(categoryId);
      return categoriesData.map(_categoryDataToModel).toList();
    } catch (e) {
      throw Exception('获取类别路径失败: $e');
    }
  }

  /// 将 CategoryModel 模型转换为 CategoryCompanion
  CategoryCompanion _categoryToCompanion(CategoryModel category) {
    return CategoryCompanion(
      name: Value(category.name),
      parentId: category.parentId != null
          ? Value(category.parentId!)
          : const Value.absent(),
    );
  }

  /// 将 CategoryData 转换为 CategoryModel 模型
  CategoryModel _categoryDataToModel(CategoryData data) {
    return CategoryModel(id: data.id, name: data.name, parentId: data.parentId);
  }
}

/// CategoryModel Repository Provider
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return CategoryRepository(database);
});
