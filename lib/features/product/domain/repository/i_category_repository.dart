import '../model/category.dart';

/// 类别仓储接口
/// 定义类别相关的业务操作规范
abstract class ICategoryRepository {
  /// 添加类别
  Future<int> addCategory(Category category);

  /// 根据ID获取类别
  Future<Category?> getCategoryById(String id);

  /// 获取所有类别
  Future<List<Category>> getAllCategories();

  /// 获取根类别（没有父类别的类别）
  Future<List<Category>> getRootCategories();

  /// 根据父类别ID获取子类别
  Future<List<Category>> getCategoriesByParentId(String parentId);

  /// 监听所有类别变化
  Stream<List<Category>> watchAllCategories();

  /// 监听根类别变化
  Stream<List<Category>> watchRootCategories();

  /// 监听指定父类别的子类别变化
  Stream<List<Category>> watchCategoriesByParentId(String parentId);

  /// 更新类别
  Future<bool> updateCategory(Category category);

  /// 删除类别
  Future<int> deleteCategory(String id);

  /// 检查类别是否有子类别
  Future<bool> hasSubCategories(String categoryId);

  /// 检查类别名称是否已存在（在同一父类别下）
  Future<bool> isCategoryNameExists(
    String name,
    String? parentId, {
    String? excludeId,
  });

  /// 获取类别层级路径（从根到指定类别）
  Future<List<Category>> getCategoryPath(String categoryId);
}
