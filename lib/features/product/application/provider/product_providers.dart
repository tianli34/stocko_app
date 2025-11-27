import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/model/product.dart';
import '../../domain/model/category.dart';
import '../../data/repository/product_repository.dart'; // 这里包含了 productRepositoryProvider
import '../category_notifier.dart';
import 'product_group_providers.dart';

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
  Future<void> addProduct(ProductModel product) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(productRepositoryProvider);
      await repository.addProduct(product);

      // 刷新产品列表
      ref.invalidate(allProductsProvider);
    });
  }

  /// 更新产品
  Future<void> updateProduct(ProductModel product) async {
    // 检查产品ID是否为空
    if (product.id == null || product.id! <= 0) {
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
// 使对应的 productByIdProvider 无效，以便获取最新数据
      ref.invalidate(productByIdProvider(product.id!));
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
  Future<ProductModel?> getProductById(int productId) async {
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
  Future<ProductModel?> getProductByBarcode(String barcode) async {
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
      ProductModel product,
      int unitId,
      String unitName,
      int conversionRate,
      int? sellingPriceInCents,
      int? wholesalePriceInCents,
      int? averageUnitPriceInCents
    })?
  >
  getProductWithUnitByBarcode(String barcode) async {
    try {
      final repository = ref.read(productRepositoryProvider);
      final result = await repository.getProductWithUnitByBarcode(barcode);
      if (result == null) return null;
      return (
        product: result.product,
        unitId: result.unitId,
        unitName: result.unitName,
        conversionRate: result.conversionRate,
        sellingPriceInCents: result.sellingPriceInCents,
        wholesalePriceInCents: result.wholesalePriceInCents,
        averageUnitPriceInCents: result.averageUnitPriceInCents,
      );
    } catch (e, st) {
      state = AsyncValue.error(Exception('根据条码查询产品及单位失败: ${e.toString()}'), st);
      return null;
    }
  }
}

/// 产品列表 StreamNotifier
class ProductListNotifier extends StreamNotifier<List<ProductModel>> {
  @override
  Stream<List<ProductModel>> build() {
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
    StreamNotifierProvider<ProductListNotifier, List<ProductModel>>(() {
      return ProductListNotifier();
    });

/// 根据ID获取产品
final productByIdProvider = FutureProvider.family<ProductModel?, int>((
  ref,
  productId,
) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProductById(productId);
});

/// 根据条码获取产品
final productByBarcodeProvider = FutureProvider.family<ProductModel?, String>((
  ref,
  barcode,
) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProductByBarcode(barcode);
});

/// 为了兼容现有代码，保留原有的 provider 名称
final allProductsProvider = productListStreamProvider;

/// 用于存储当前选中的分类ID
final selectedCategoryIdProvider = StateProvider<int?>((ref) => null);

/// 用于存储当前的搜索关键字
final searchQueryProvider = StateProvider<String>((ref) => '');

/// 提供根据分类筛选和关键字搜索后的产品列表
final filteredProductsProvider = Provider<AsyncValue<List<ProductModel>>>((ref) {
  final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final productsAsyncValue = ref.watch(allProductsProvider);
  final categoryListState = ref.watch(categoryListProvider);

  if (categoryListState.isLoading) {
    return const AsyncValue.loading();
  }

  if (categoryListState.error != null) {
    return AsyncValue.error(categoryListState.error!, StackTrace.current);
  }

  final allCategories = categoryListState.categories;

  return productsAsyncValue.when(
    data: (products) {
      var filteredList = products;

      // 默认筛选：如果未选择任何分类，则默认不显示“烟”类别及其所有子类别
      if (selectedCategoryId == null) {
        // 查找所有后代ID的辅助函数
        Set<int> getAllDescendantIds(
            int parentId, List<CategoryModel> categories) {
          final Set<int> descendantIds = {};
          final children =
              categories.where((c) => c.parentId == parentId).toList();
          for (final child in children) {
            if (child.id != null) {
              descendantIds.add(child.id!);
              descendantIds.addAll(
                  getAllDescendantIds(child.id!, categories));
            }
          }
          return descendantIds;
        }

        try {
          final tobaccoCategory =
              allCategories.firstWhere((c) => c.name == '烟');
          final idsToExclude = {tobaccoCategory.id!};
          if (tobaccoCategory.id != null) {
            idsToExclude.addAll(
                getAllDescendantIds(tobaccoCategory.id!, allCategories));
          }

          filteredList = filteredList
              .where((p) => !idsToExclude.contains(p.categoryId))
              .toList();
        } catch (e) {
          // 未找到 "烟" 类别，不执行任何操作
        }
      }

      // 按分类筛选
      if (selectedCategoryId != null) {
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
          ProductModel product,
          int unitId,
          String unitName,
          int conversionRate,
          int? sellingPriceInCents,
          int? wholesalePriceInCents
        })
      >
    >((ref) {
      final repository = ref.watch(productRepositoryProvider);
      return repository.watchAllProductsWithUnit().map((list) => list.map((e) => (
        product: e.product,
        unitId: e.unitId,
        unitName: e.unitName,
        conversionRate: e.conversionRate,
        sellingPriceInCents: e.sellingPriceInCents,
        wholesalePriceInCents: e.wholesalePriceInCents,
      )).toList());
    });

/// 商品组聚合数据模型
class ProductGroupAggregate {
  final int? groupId;
  final String? groupName;
  final String? groupImage;
  final List<ProductModel> products;
  
  const ProductGroupAggregate({
    this.groupId,
    this.groupName,
    this.groupImage,
    required this.products,
  });
  
  /// 是否为商品组（有多个商品）
  bool get isGroup => groupId != null && products.length > 1;
  
  /// 获取展示名称
  String get displayName => groupName ?? products.first.name;
  
  /// 获取展示图片
  String? get displayImage => groupImage ?? products.first.image;
  
  /// 获取价格范围
  String get priceRange {
    if (products.isEmpty) return '价格待定';
    if (products.length == 1) return products.first.formattedPrice;
    
    final prices = products
        .map((p) => p.effectivePrice?.cents)
        .whereType<int>()
        .toList();
    if (prices.isEmpty) return '价格待定';
    
    prices.sort();
    final minPrice = prices.first / 100;
    final maxPrice = prices.last / 100;
    
    if (minPrice == maxPrice) {
      return '¥${minPrice.toStringAsFixed(2)}';
    }
    return '¥${minPrice.toStringAsFixed(2)} - ¥${maxPrice.toStringAsFixed(2)}';
  }
}

/// 是否启用商品组聚合视图
final groupedViewEnabledProvider = StateProvider<bool>((ref) => true);

/// 按商品组聚合的产品列表
final groupedProductsProvider = Provider<AsyncValue<List<ProductGroupAggregate>>>((ref) {
  final productsAsync = ref.watch(filteredProductsProvider);
  final groupsAsync = ref.watch(allProductGroupsProvider);
  
  return productsAsync.when(
    data: (products) {
      return groupsAsync.when(
        data: (groups) {
          final Map<int?, ProductGroupAggregate> groupMap = {};
          
          for (final product in products) {
            final groupId = product.groupId;
            
            if (groupId != null) {
              // 有商品组的商品
              if (groupMap.containsKey(groupId)) {
                final existing = groupMap[groupId]!;
                groupMap[groupId] = ProductGroupAggregate(
                  groupId: groupId,
                  groupName: existing.groupName,
                  groupImage: existing.groupImage,
                  products: [...existing.products, product],
                );
              } else {
                final group = groups.where((g) => g.id == groupId).firstOrNull;
                groupMap[groupId] = ProductGroupAggregate(
                  groupId: groupId,
                  groupName: group?.name,
                  groupImage: group?.image,
                  products: [product],
                );
              }
            } else {
              // 没有商品组的商品，使用负数ID作为key避免冲突
              final uniqueKey = -(product.id ?? 0);
              groupMap[uniqueKey] = ProductGroupAggregate(
                groupId: null,
                groupName: null,
                groupImage: null,
                products: [product],
              );
            }
          }
          
          // 转换为列表并排序
          final result = groupMap.values.toList();
          result.sort((a, b) {
            // 优先按最新更新时间排序
            final aTime = a.products.map((p) => p.lastUpdated).whereType<DateTime>().fold<DateTime?>(null, (prev, curr) => prev == null || curr.isAfter(prev) ? curr : prev);
            final bTime = b.products.map((p) => p.lastUpdated).whereType<DateTime>().fold<DateTime?>(null, (prev, curr) => prev == null || curr.isAfter(prev) ? curr : prev);
            
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });
          
          return AsyncValue.data(result);
        },
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
