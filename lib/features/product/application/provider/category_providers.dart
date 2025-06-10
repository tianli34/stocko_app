import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/model/category.dart';

// 类别状态管理器
class CategoryNotifier extends StateNotifier<List<Category>> {
  CategoryNotifier() : super(_initialCategories);

  int _nextId = 100; // 起始ID，避免与初始数据冲突

  static const List<Category> _initialCategories = [
    Category(id: '1', name: '食品饮料'),
    Category(id: '2', name: '日用百货'),
    Category(id: '3', name: '服装鞋帽'),
    Category(id: '4', name: '电子数码'),
    Category(id: '5', name: '家居用品'),
    Category(id: '6', name: '美妆个护'),
    Category(id: '7', name: '母婴用品'),
    Category(id: '8', name: '运动户外'),
  ];

  // 生成唯一ID
  String _generateId() {
    return (_nextId++).toString();
  }

  // 添加类别
  void addCategory(String name) {
    final newId = _generateId();
    final newCategory = Category(id: newId, name: name);
    state = [...state, newCategory];
  }

  // 添加子类别
  void addSubCategory(String name, String parentId) {
    final newId = _generateId();
    final newSubCategory = Category(id: newId, name: name, parentId: parentId);
    state = [...state, newSubCategory];
  }

  // 更新类别
  void updateCategory(String id, String newName) {
    state = state.map((category) {
      if (category.id == id) {
        return category.copyWith(name: newName);
      }
      return category;
    }).toList();
  }

  // 删除类别
  void deleteCategory(String id) {
    // 先删除所有子类别
    state = state.where((category) => category.parentId != id).toList();
    // 再删除类别本身
    state = state.where((category) => category.id != id).toList();
  }
}

// 类别状态提供者
final categoriesProvider =
    StateNotifierProvider<CategoryNotifier, List<Category>>((ref) {
      return CategoryNotifier();
    });

// 根据ID获取类别
final getCategoryByIdProvider = Provider.family<Category?, String>((
  ref,
  categoryId,
) {
  final categories = ref.watch(categoriesProvider);
  try {
    return categories.firstWhere((category) => category.id == categoryId);
  } catch (e) {
    return null;
  }
});

// 获取顶级类别（无父级的类别）
final topLevelCategoriesProvider = Provider<List<Category>>((ref) {
  final categories = ref.watch(categoriesProvider);
  return categories.where((category) => category.parentId == null).toList();
});

// 根据父级ID获取子类别
final getSubCategoriesProvider = Provider.family<List<Category>, String>((
  ref,
  parentId,
) {
  final categories = ref.watch(categoriesProvider);
  return categories.where((category) => category.parentId == parentId).toList();
});
