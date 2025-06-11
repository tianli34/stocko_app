import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/model/category.dart';
import 'category_service.dart';

/// 类别示例数据服务
class CategorySampleDataService {
  final CategoryService _categoryService;

  CategorySampleDataService(this._categoryService);

  /// 创建示例类别数据
  Future<void> createSampleCategories() async {
    try {
      // 检查是否已有数据
      final existingCategories = await _categoryService.getAllCategories();
      if (existingCategories.isNotEmpty) {
        print('📦 类别示例数据已存在，跳过创建');
        return;
      }

      print('📦 开始创建类别示例数据...');

      // 创建根类别
      await _createCategory(id: 'cat_food', name: '食品饮料', parentId: null);

      await _createCategory(id: 'cat_daily', name: '日用百货', parentId: null);

      await _createCategory(id: 'cat_personal', name: '个人护理', parentId: null);

      // 创建食品饮料子类别
      await _createCategory(
        id: 'cat_snacks',
        name: '休闲零食',
        parentId: 'cat_food',
      );

      await _createCategory(
        id: 'cat_beverages',
        name: '饮料',
        parentId: 'cat_food',
      );

      await _createCategory(id: 'cat_dairy', name: '乳制品', parentId: 'cat_food');

      // 创建休闲零食的子类别
      await _createCategory(
        id: 'cat_chips',
        name: '薯片',
        parentId: 'cat_snacks',
      );

      await _createCategory(
        id: 'cat_candy',
        name: '糖果',
        parentId: 'cat_snacks',
      );

      // 创建饮料的子类别
      await _createCategory(
        id: 'cat_soft_drinks',
        name: '软饮',
        parentId: 'cat_beverages',
      );

      await _createCategory(
        id: 'cat_juice',
        name: '果汁',
        parentId: 'cat_beverages',
      );

      // 创建日用百货子类别
      await _createCategory(
        id: 'cat_cleaning',
        name: '清洁用品',
        parentId: 'cat_daily',
      );

      await _createCategory(
        id: 'cat_kitchen',
        name: '厨房用品',
        parentId: 'cat_daily',
      );

      // 创建个人护理子类别
      await _createCategory(
        id: 'cat_skincare',
        name: '护肤用品',
        parentId: 'cat_personal',
      );

      await _createCategory(
        id: 'cat_oral_care',
        name: '口腔护理',
        parentId: 'cat_personal',
      );

      print('📦 类别示例数据创建完成！');
    } catch (e) {
      print('📦 创建类别示例数据失败: $e');
      rethrow;
    }
  }

  Future<void> _createCategory({
    required String id,
    required String name,
    String? parentId,
  }) async {
    try {
      await _categoryService.addCategory(
        id: id,
        name: name,
        parentId: parentId,
      );
      print('✅ 创建类别: $name ${parentId != null ? "(父类别: $parentId)" : "(根类别)"}');
    } catch (e) {
      print('❌ 创建类别失败: $name - $e');
      rethrow;
    }
  }

  /// 清除所有示例数据
  Future<void> clearAllCategories() async {
    try {
      final categories = await _categoryService.getAllCategories();

      // 按层级从深到浅删除（先删除子类别，再删除父类别）
      final categoryLevels = <int, List<Category>>{};

      for (final category in categories) {
        final path = await _categoryService.getCategoryPath(category.id);
        final level = path.length;
        categoryLevels.putIfAbsent(level, () => []).add(category);
      }

      // 从最深层开始删除
      final sortedLevels = categoryLevels.keys.toList()
        ..sort((a, b) => b.compareTo(a));

      for (final level in sortedLevels) {
        for (final category in categoryLevels[level]!) {
          await _categoryService.deleteCategory(category.id);
          print('🗑️ 删除类别: ${category.name}');
        }
      }

      print('📦 所有类别数据已清除');
    } catch (e) {
      print('📦 清除类别数据失败: $e');
      rethrow;
    }
  }
}

/// Category Sample Data Service Provider
final categorySampleDataServiceProvider = Provider<CategorySampleDataService>((
  ref,
) {
  final categoryService = ref.watch(categoryServiceProvider);
  return CategorySampleDataService(categoryService);
});
