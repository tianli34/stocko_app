import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/model/product.dart';
import '../../domain/model/category.dart';
import '../../data/repository/product_repository.dart'; // 这里包含了 productRepositoryProvider
import '../category_notifier.dart';

// 注意：这个文件展示了使用 AsyncNotifier 重构后的代码结构
// 这是 product_providers.dart 的完整重构版本

/// 使用传统方式的 AsyncNotifier 示例（不使用代码生成）
/// 产品操作状态管理
class ProductOperationsNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // 初始状态
    return null;
  }

  /// 添加产品
  Future<void> addProduct(Product product) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(productRepositoryProvider);
      await repository.addProduct(product);

      // 刷新产品列表
      ref.invalidate(allProductsProvider);
    });
  }

  /// 更新产品
  Future<void> updateProduct(Product product) async {
    // 检查产品ID是否为空
    if (product.id <= 0) {
      state = AsyncValue.error(Exception('产品ID不能为空'), StackTrace.current);
      return;
    }

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(productRepositoryProvider);
      final success = await repository.updateProduct(product);

      if (!success) {
        throw Exception('更新产品失败：未找到对应的产品记录');
      }

      // 刷新产品列表
      ref.invalidate(allProductsProvider);
    });
  }

  /// 删除产品
  Future<void> deleteProduct(int productId) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(productRepositoryProvider);
      await repository.deleteProduct(productId);

      // 刷新产品列表
      ref.invalidate(allProductsProvider);
    });
  }

  /// 重置状态
  void resetState() {
    state = const AsyncValue.data(null);
  }

  /// 清除错误状态
  void clearError() {
    if (state.hasError) {
      state = const AsyncValue.data(null);
    }
  }

  /// 根据ID获取产品
  Future<Product?> getProductById(int productId) async {
    try {
      final repository = ref.read(productRepositoryProvider);
      return await repository.getProductById(productId);
    } catch (e) {
      state = AsyncValue.error(
        Exception('获取产品失败: ${e.toString()}'),
        StackTrace.current,
      );
      return null;
    }
  }

  /// 根据条码获取产品
  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final repository = ref.read(productRepositoryProvider);
      return await repository.getProductByBarcode(barcode);
    } catch (e) {
      state = AsyncValue.error(
        Exception('根据条码查询产品失败: ${e.toString()}'),
        StackTrace.current,
      );
      return null;
    }
  }

  /// 根据条码获取产品及其单位信息
  Future<
    ({
      Product product,
      int unitId,
      String unitName,
      double? wholesalePrice
    })?
  >
  getProductWithUnitByBarcode(String barcode) async {
    try {
      final repository = ref.read(productRepositoryProvider);
      return await repository.getProductWithUnitByBarcode(barcode);
    } catch (e, st) {
      state = AsyncValue.error(Exception('根据条码查询产品及单位失败: ${e.toString()}'), st);
      rethrow;
    }
  }
}

/// 产品列表 StreamNotifier
class ProductListNotifier extends StreamNotifier<List<Product>> {
  @override
  Stream<List<Product>> build() {
    final repository = ref.watch(productRepositoryProvider);
    return repository.watchAllProducts().map((products) {
      final sortedProducts = List.of(products);

      // 按 lastUpdated 降序排序，最新的产品在最前面
      sortedProducts.sort((a, b) {
        final aDate = a.lastUpdated;
        final bDate = b.lastUpdated;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      // 如果列表长度大于3，将最新的产品移动到第4位
      if (sortedProducts.length > 3) {
        final latestProduct = sortedProducts.removeAt(0);
        sortedProducts.insert(3, latestProduct);
      }

      return sortedProducts;
    });
  }

  /// 刷新产品列表
  void refresh() {
    ref.invalidateSelf();
  }
}

/// 重构后的 Providers
final productOperationsProvider =
    AsyncNotifierProvider<ProductOperationsNotifier, void>(() {
      return ProductOperationsNotifier();
    });

final productListStreamProvider =
    StreamNotifierProvider<ProductListNotifier, List<Product>>(() {
      return ProductListNotifier();
    });

/// 根据ID获取产品
final productByIdProvider = FutureProvider.family<Product?, int>((
  ref,
  productId,
) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProductById(productId);
});

/// 根据条码获取产品
final productByBarcodeProvider = FutureProvider.family<Product?, String>((
  ref,
  barcode,
) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProductByBarcode(barcode);
});

/// 为了兼容现有代码，保留原有的 provider 名称
final allProductsProvider = productListStreamProvider;

/// 用于存储当前选中的分类ID
final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);

/// 用于存储当前的搜索关键字
final searchQueryProvider = StateProvider<String>((ref) => '');

/// 提供根据分类筛选和关键字搜索后的产品列表
final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final productsAsyncValue = ref.watch(allProductsProvider);
  final allCategories = ref.watch(categoriesProvider);

  return productsAsyncValue.when(
    data: (products) {
      var filteredList = products;

      // 默认筛选：如果未选择任何分类，则默认不显示“烟”类别及其所有子类别
      if (selectedCategoryId == null || selectedCategoryId.isEmpty) {
        // 查找所有后代ID的辅助函数
        Set<String> getAllDescendantIds(
            String parentId, List<Category> categories) {
          final Set<String> descendantIds = {};
          final children =
              categories.where((c) => c.parentId == parentId).toList();
          for (final child in children) {
            descendantIds.add(child.id);
            descendantIds.addAll(getAllDescendantIds(child.id, categories));
          }
          return descendantIds;
        }

        try {
          final tobaccoCategory =
              allCategories.firstWhere((c) => c.name == '烟');
          final idsToExclude = {tobaccoCategory.id};
          idsToExclude
              .addAll(getAllDescendantIds(tobaccoCategory.id, allCategories));

          filteredList = filteredList
              .where((p) => !idsToExclude.contains(p.categoryId))
              .toList();
        } catch (e) {
          // 未找到 "烟" 类别，不执行任何操作
        }
      }

      // 按分类筛选
      if (selectedCategoryId != null && selectedCategoryId.isNotEmpty) {
        filteredList = filteredList
            .where((p) => p.categoryId == selectedCategoryId)
            .toList();
      }

      // 按关键字搜索
      if (searchQuery.isNotEmpty) {
        final lowerCaseQuery = searchQuery.toLowerCase();
        filteredList = filteredList
            .where((p) => p.name.toLowerCase().contains(lowerCaseQuery))
            .toList();
      }

      return AsyncValue.data(filteredList);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// 提供所有产品及其单位名称的流
final allProductsWithUnitProvider =
    StreamProvider<
      List<
        ({
          Product product,
          int unitId,
          String unitName,
          double? wholesalePrice
        })
      >
    >((ref) {
      final repository = ref.watch(productRepositoryProvider);
      return repository.watchAllProductsWithUnit();
    });
