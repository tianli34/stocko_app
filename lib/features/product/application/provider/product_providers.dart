import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/model/product.dart';
import '../../data/repository/product_repository.dart'; // 这里包含了 productRepositoryProvider

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
      String unitId,
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

  print('#################################################################');
  print('##### 🔄 filteredProductsProvider 开始执行 🔄 #####');
  print('#################################################################');
  print('  - 🔍 搜索关键字: "$searchQuery"');
  print('  - 🗂️  分类ID: "$selectedCategoryId"');

  return productsAsyncValue.when(
    data: (products) {
      print('  -> ✅ [数据分支] 成功获取原始产品列表，数量: ${products.length}');
      var filteredList = products;

      // 按分类筛选
      if (selectedCategoryId != null && selectedCategoryId.isNotEmpty) {
        final initialCount = filteredList.length;
        filteredList = filteredList
            .where((p) => p.categoryId == selectedCategoryId)
            .toList();
        print(
          '  ->  lọc 按分类筛选: ID="$selectedCategoryId", 数量从 $initialCount -> ${filteredList.length}',
        );
      } else {
        print('  -> ℹ️  无需按分类筛选');
      }

      // 按关键字搜索
      if (searchQuery.isNotEmpty) {
        final initialCount = filteredList.length;
        final lowerCaseQuery = searchQuery.toLowerCase();
        filteredList = filteredList
            .where((p) => p.name.toLowerCase().contains(lowerCaseQuery))
            .toList();
        print(
          '  -> 🔎 按关键字筛选: 关键字="$searchQuery", 数量从 $initialCount -> ${filteredList.length}',
        );
      } else {
        print('  -> ℹ️  无需按关键字筛选');
      }

      if (filteredList.isEmpty) {
        print('  -> ⚠️  最终列表为空');
      } else {
        print('  -> ✅ 最终产品列表数量: ${filteredList.length}');
      }
      print(
        '#################################################################',
      );
      return AsyncValue.data(filteredList);
    },
    loading: () {
      print('  -> ⏳ [加载中分支]');
      print(
        '#################################################################',
      );
      return const AsyncValue.loading();
    },
    error: (error, stack) {
      print('  -> ❌ [错误分支] 错误: $error');
      print(
        '#################################################################',
      );
      return AsyncValue.error(error, stack);
    },
  );
});

/// 提供所有产品及其单位名称的流
final allProductsWithUnitProvider =
    StreamProvider<
      List<
        ({
          Product product,
          String unitId,
          String unitName,
          double? wholesalePrice
        })
      >
    >((ref) {
      final repository = ref.watch(productRepositoryProvider);
      return repository.watchAllProductsWithUnit();
    });
