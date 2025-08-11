import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/categories_table.dart';

part 'category_dao.g.dart';

/// 类别数据访问对象 (DAO)
/// 专门负责类别相关的数据库操作
@DriftAccessor(tables: [Category])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  /// 添加类别
  Future<int> insertCategory(CategoryCompanion companion) async {
    return await into(db.category).insert(companion);
  }

  /// 根据ID获取类别
  Future<CategoryData?> getCategoryById(int id) async {
    return await (select(
      db.category,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// 获取所有类别
  Future<List<CategoryData>> getAllCategories() async {
    return await select(db.category).get();
  }

  /// 监听所有类别变化
  Stream<List<CategoryData>> watchAllCategories() {
    return select(db.category).watch();
  }

  /// 根据父类别ID获取子类别
  Future<List<CategoryData>> getCategoriesByParentId(
    int? parentId,
  ) async {
    if (parentId == null) {
      // 获取根类别（没有父类别的类别）
      return await (select(
        db.category,
      )..where((tbl) => tbl.parentId.isNull())).get();
    } else {
      // 获取指定父类别的子类别
      return await (select(
        db.category,
      )..where((tbl) => tbl.parentId.equals(parentId))).get();
    }
  }

  /// 监听根类别变化（没有父类别的类别）
  Stream<List<CategoryData>> watchRootCategories() {
    return (select(
      db.category,
    )..where((tbl) => tbl.parentId.isNull())).watch();
  }

  /// 监听指定父类别的子类别变化
  Stream<List<CategoryData>> watchCategoriesByParentId(int parentId) {
    return (select(
      db.category,
    )..where((tbl) => tbl.parentId.equals(parentId))).watch();
  }

  /// 更新类别
  Future<bool> updateCategory(CategoryCompanion companion) async {
    final result = await update(db.category).replace(companion);
    return result;
  }

  /// 删除类别
  Future<int> deleteCategory(int id) async {
    return await (delete(
      db.category,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  /// 检查类别是否有子类别
  Future<bool> hasSubCategories(int categoryId) async {
    final count = await (select(
      db.category,
    )..where((tbl) => tbl.parentId.equals(categoryId))).get();
    return count.isNotEmpty;
  }

  /// 检查类别名称是否已存在（在同一父类别下）
  Future<bool> isCategoryNameExists(
    String name,
    int? parentId, {
    int? excludeId,
  }) async {
    var query = select(db.category)
      ..where((tbl) => tbl.name.equals(name));

    if (parentId == null) {
      query = query..where((tbl) => tbl.parentId.isNull());
    } else {
      query = query..where((tbl) => tbl.parentId.equals(parentId));
    }

    if (excludeId != null) {
      query = query..where((tbl) => tbl.id.isNotValue(excludeId));
    }

    final result = await query.get();
    return result.isNotEmpty;
  }

  /// 获取类别层级路径（从根到指定类别）
  Future<List<CategoryData>> getCategoryPath(int categoryId) async {
    final path = <CategoryData>[];
    int? currentId = categoryId;

    while (currentId != null) {
      final category = await getCategoryById(currentId);
      if (category == null) break;

      path.insert(0, category);
      currentId = category.parentId;
    }

    return path;
  }
}
