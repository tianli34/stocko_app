import '../model/category.dart';

/// 类别仓储接口
/// 定义类别相关的业务操作规范
abstract class ICategoryRepository {
  /// 添加类别
  Future<int> addCategory(CategoryModel category);

  /// 根据ID获取类别
  Future<CategoryModel?> getCategoryById(int id);

  /// 获取所有类别
  Future<List<CategoryModel>> getAllCategories();

  /// 获取根类别（没有父类别的类别）
  Future<List<CategoryModel>> getRootCategories();

  /// 根据父类别ID获取子类别
  Future<List<CategoryModel>> getCategoriesByParentId(int parentId);

  /// 监听所有类别变化
  Stream<List<CategoryModel>> watchAllCategories();

  /// 监听根类别变化
  Stream<List<CategoryModel>> watchRootCategories();

  /// 监听指定父类别的子类别变化
  Stream<List<CategoryModel>> watchCategoriesByParentId(int parentId);

  /// 更新类别
  Future<bool> updateCategory(CategoryModel category);

  /// 删除类别
  Future<int> deleteCategory(int id);

  /// 检查类别是否有子类别
  Future<bool> hasSubCategories(int categoryId);

  /// 检查类别名称是否已存在（在同一父类别下）
  Future<bool> isCategoryNameExists(
    String name,
    int? parentId, {
    int? excludeId,
  });

  /// 获取类别层级路径（从根到指定类别）
  Future<List<CategoryModel>> getCategoryPath(int categoryId);
}
