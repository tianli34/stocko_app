import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/model/category.dart';
import 'category_service.dart';

/// 类别列表状态
class CategoryListState {
  final List<Category> categories;
  final bool isLoading;
  final String? error;

  const CategoryListState({
    this.categories = const [],
    this.isLoading = false,
    this.error,
  });

  CategoryListState copyWith({
    List<Category>? categories,
    bool? isLoading,
    String? error,
  }) {
    return CategoryListState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 类别列表状态管理器
class CategoryListNotifier extends StateNotifier<CategoryListState> {
  final CategoryService _categoryService;

  CategoryListNotifier(this._categoryService)
    : super(const CategoryListState()) {
    loadCategories();
  }

  /// 加载所有类别
  Future<void> loadCategories() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final categories = await _categoryService.getAllCategories();
      state = state.copyWith(categories: categories, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 添加类别
  Future<void> addCategory({required String name, String? parentId}) async {
    try {
      final id = _categoryService.generateCategoryId();
      await _categoryService.addCategory(
        id: id,
        name: name,
        parentId: parentId,
      );
      await loadCategories(); // 重新加载列表
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// 更新类别
  Future<void> updateCategory({
    required String id,
    required String name,
    String? parentId,
  }) async {
    try {
      await _categoryService.updateCategory(
        id: id,
        name: name,
        parentId: parentId,
      );
      await loadCategories(); // 重新加载列表
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// 删除类别 - 仅删除当前类别（保留子类和产品）
  Future<void> deleteCategoryOnly(String id) async {
    try {
      await _categoryService.deleteCategoryOnly(id);
      await loadCategories(); // 重新加载列表
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// 级联删除类别及所有关联内容
  Future<void> deleteCategoryCascade(String id) async {
    try {
      await _categoryService.deleteCategoryCascade(id);
      await loadCategories(); // 重新加载列表
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// 删除类别（保持向后兼容）
  Future<void> deleteCategory(String id) async {
    try {
      await _categoryService.deleteCategory(id);
      await loadCategories(); // 重新加载列表
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// 清除错误
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// 类别列表 Provider
final categoryListProvider =
    StateNotifierProvider<CategoryListNotifier, CategoryListState>((ref) {
      final categoryService = ref.watch(categoryServiceProvider);
      return CategoryListNotifier(categoryService);
    });

/// 根类别 Provider
final rootCategoriesProvider = StreamProvider<List<Category>>((ref) {
  final categoryService = ref.watch(categoryServiceProvider);
  return categoryService.watchRootCategories();
});

/// 指定父类别的子类别 Provider
final subCategoriesProvider = StreamProvider.family<List<Category>, String>((
  ref,
  parentId,
) {
  final categoryService = ref.watch(categoryServiceProvider);
  return categoryService.watchSubCategories(parentId);
});

/// 所有类别的流式 Provider
final allCategoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  final categoryService = ref.watch(categoryServiceProvider);
  return categoryService.watchAllCategories();
});

/// 获取所有类别的同步 Provider (兼容旧的 categoriesProvider)
final categoriesProvider = Provider<List<Category>>((ref) {
  final categoryListState = ref.watch(categoryListProvider);
  return categoryListState.categories;
});

/// 根据ID获取类别的 Provider
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

/// 获取顶级类别（无父级的类别）
final topLevelCategoriesProvider = Provider<List<Category>>((ref) {
  final categories = ref.watch(categoriesProvider);
  return categories.where((category) => category.parentId == null).toList();
});

/// 根据父级ID获取子类别的同步 Provider
final getSubCategoriesProvider = Provider.family<List<Category>, String>((
  ref,
  parentId,
) {
  final categories = ref.watch(categoriesProvider);
  return categories.where((category) => category.parentId == parentId).toList();
});
