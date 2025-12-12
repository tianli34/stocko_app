import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/data_refresh_service.dart';
import '../domain/model/category.dart';
import 'category_service.dart';

/// 类别列表状态
class CategoryListState {
  final List<CategoryModel> categories;
  final bool isLoading;
  final String? error;

  const CategoryListState({
    this.categories = const [],
    this.isLoading = false,
    this.error,
  });

  CategoryListState copyWith({
    List<CategoryModel>? categories,
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
  bool _disposed = false;

  CategoryListNotifier(this._categoryService)
    : super(const CategoryListState()) {
    loadCategories();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// 加载所有类别
  Future<void> loadCategories() async {
    if (_disposed) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final categories = await _categoryService.getAllCategories();
      if (!_disposed) {
        state = state.copyWith(categories: categories, isLoading: false);
      }
    } catch (e) {
      if (!_disposed) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  /// 添加类别
  Future<int> addCategory({required String name, int? parentId}) async {
    try {
      // final id = _categoryService.generateCategoryId();
      final newId = await _categoryService.addCategory(
        // id: id,
        name: name,
        parentId: parentId,
      );
      await loadCategories(); // 重新加载列表
      return newId;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// 更新类别
  Future<void> updateCategory({
    required int id,
    required String name,
    int? parentId,
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
  Future<void> deleteCategoryOnly(int id) async {
    try {
      await _categoryService.deleteCategoryOnly(id);
      await loadCategories(); // 重新加载列表
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// 级联删除类别及所有关联内容
  Future<void> deleteCategoryCascade(int id) async {
    try {
      await _categoryService.deleteCategoryCascade(id);
      await loadCategories(); // 重新加载列表
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// 删除类别（保持向后兼容）
  Future<void> deleteCategory(int id) async {
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
      // 监听数据刷新触发器，当备份恢复后会触发重新加载
      ref.watch(dataRefreshTriggerProvider);
      
      final categoryService = ref.watch(categoryServiceProvider);
      return CategoryListNotifier(categoryService);
    });

/// 根类别 Provider
final rootCategoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  final categoryService = ref.watch(categoryServiceProvider);
  return categoryService.watchRootCategories();
});

/// 指定父类别的子类别 Provider
final subCategoriesProvider = StreamProvider.family<List<CategoryModel>, int>((
  ref,
  parentId,
) {
  final categoryService = ref.watch(categoryServiceProvider);
  return categoryService.watchSubCategories(parentId);
});

/// 所有类别的流式 Provider
final allCategoriesStreamProvider = StreamProvider<List<CategoryModel>>((ref) {
  // 监听数据刷新触发器
  ref.watch(dataRefreshTriggerProvider);
  
  final categoryService = ref.watch(categoryServiceProvider);
  return categoryService.watchAllCategories();
});

/// 获取所有类别的同步 Provider (兼容旧的 categoriesProvider)
final categoriesProvider = Provider<List<CategoryModel>>((ref) {
  final categoryListState = ref.watch(categoryListProvider);
  return categoryListState.categories;
});

/// 根据ID获取类别的 Provider
final getCategoryByIdProvider = Provider.family<CategoryModel?, int>((
  ref,
  categoryId,
) {
  final categories = ref.watch(categoriesProvider);
  return categories.where((category) => category.id == categoryId).firstOrNull;
});

/// 获取顶级类别（无父级的类别）
final topLevelCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  final categories = ref.watch(categoriesProvider);
  return categories.where((category) => category.parentId == null).toList();
});

/// 根据父级ID获取子类别的同步 Provider
final getSubCategoriesProvider = Provider.family<List<CategoryModel>, int>((
  ref,
  parentId,
) {
  final categories = ref.watch(categoriesProvider);
  return categories.where((category) => category.parentId == parentId).toList();
});
