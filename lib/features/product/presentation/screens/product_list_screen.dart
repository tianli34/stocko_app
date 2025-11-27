import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/product_list/product_list.dart';
import '../../../../core/widgets/product_list/grouped_product_list.dart';
import '../../application/category_notifier.dart';
import '../../../inventory/application/inventory_service.dart';
import '../../../inventory/application/provider/shop_providers.dart';
import '../../../inventory/domain/model/shop.dart';
import '../../application/provider/product_providers.dart';
import '../../domain/model/category.dart';
import '../../domain/model/product.dart';
import 'category_selection_screen.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    ProductModel product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除货品「${product.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(productOperationsProvider.notifier)
          .deleteProduct(product.id!);
    }
  }

  Future<void> _showAdjustInventoryDialog(
    BuildContext context,
    WidgetRef ref,
    ProductModel product,
  ) async {
    final quantityController = TextEditingController();
    final shops = await ref.read(allShopsProvider.future);
    Shop? selectedShop = shops.isNotEmpty ? shops.first : null;

    if (shops.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可用的店铺，请先添加店铺')),
      );
      return;
    }

    final inventory = await ref
        .read(inventoryServiceProvider)
        .getInventory(product.id!, selectedShop!.id!);
    if (inventory != null) {
      quantityController.text = inventory.quantity.toStringAsFixed(0);
    }

    if (!context.mounted) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('调整库存: ${product.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Shop>(
                    value: selectedShop,
                    decoration: const InputDecoration(labelText: '店铺'),
                    items: shops.map((shop) {
                      return DropdownMenuItem<Shop>(
                        value: shop,
                        child: Text(shop.name),
                      );
                    }).toList(),
                    onChanged: (shop) {
                      setState(() {
                        selectedShop = shop;
                      });
                    },
                  ),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '新库存数量'),
                    autofocus: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'quantity': quantityController.text,
                      'shop': selectedShop,
                    });
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      final newQuantityString = result['quantity'] as String;
      final shop = result['shop'] as Shop;

      if (newQuantityString.isNotEmpty) {
        final newQuantity = int.tryParse(newQuantityString);
        if (newQuantity == null) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无效的数字格式')),
          );
          return;
        }

        try {
          await ref.read(inventoryServiceProvider).adjustInventory(
                productId: product.id!,
                quantity: newQuantity,
                shopId: shop.id!,
              );
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('库存调整成功')),
          );
          ref.invalidate(filteredProductsProvider); // Refresh the product list
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('库存调整失败: $e')),
          );
        }
      }
    }
  }

  Future<void> _showSearchDialog(BuildContext context, WidgetRef ref) async {
    final searchController = TextEditingController();
    final searchQuery = ref.read(searchQueryProvider);
    searchController.text = searchQuery;

    final newQuery = await showDialog<String>(
      context: context,
      builder: (context) => Transform.translate(
        offset: const Offset(0, 150),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 9.0),
          child: TextField(
            controller: searchController,
            autofocus: true,
            onSubmitted: (value) => Navigator.of(context).pop(value),
            decoration: InputDecoration(
              // hintText: '输入关键字...',
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              border: OutlineInputBorder(
                // borderRadius: BorderRadius.circular(22.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 15.0,
                horizontal: 10.0,
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(searchController.text),
                  child: const Text('搜索'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (newQuery != null) {
      ref.read(searchQueryProvider.notifier).state = newQuery;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsyncValue = ref.watch(filteredProductsProvider);
    final groupedProductsAsyncValue = ref.watch(groupedProductsProvider);
    final isGroupedView = ref.watch(groupedViewEnabledProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final allCategories = ref.watch(categoryListProvider).categories;

    String? categoryName;
    if (selectedCategoryId != null) {
      final category = allCategories.firstWhere(
        (c) => c.id == selectedCategoryId,
        orElse: () => const CategoryModel(id: -1, name: '未知分类'),
      );
      categoryName = category.name;
    }

    Widget titleWidget;
    final productCount = productsAsyncValue.asData?.value.length;
    final countSuffix = productCount != null ? ' ($productCount)' : '';

    if (searchQuery.isNotEmpty) {
      titleWidget = Row(
        children: [
          const Icon(Icons.search, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(searchQuery, overflow: TextOverflow.ellipsis)),
          if (productCount != null) Text('($productCount)'),
        ],
      );
    } else {
      titleWidget = Text('${categoryName ?? '货品列表'}$countSuffix');
    }

    return Scaffold(
      appBar: AppBar(
        title: titleWidget,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '搜索',
            onPressed: () => _showSearchDialog(context, ref),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              switch (value) {
                case 'toggle_view':
                  ref.read(groupedViewEnabledProvider.notifier).state = !isGroupedView;
                  break;
                case 'product_groups':
                  context.push(AppRoutes.productGroups);
                  break;
                case 'filter':
                  final selectedCategory = await Navigator.push<CategoryModel>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategorySelectionScreen(),
                    ),
                  );
                  if (selectedCategory != null) {
                    ref.read(selectedCategoryIdProvider.notifier).state = selectedCategory.id;
                  }
                  break;
                case 'clear':
                  ref.read(searchQueryProvider.notifier).state = '';
                  ref.read(selectedCategoryIdProvider.notifier).state = null;
                  break;
                case 'add':
                  context.push(AppRoutes.productNew);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_view',
                child: Row(
                  children: [
                    Icon(isGroupedView ? Icons.view_list : Icons.folder_copy_outlined),
                    const SizedBox(width: 12),
                    Text(isGroupedView ? '列表视图' : '商品组视图'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'product_groups',
                child: Row(
                  children: [
                    Icon(Icons.folder_outlined),
                    SizedBox(width: 12),
                    Text('商品组管理'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'filter',
                child: Row(
                  children: [
                    Icon(Icons.filter_list),
                    SizedBox(width: 12),
                    Text('按分类筛选'),
                  ],
                ),
              ),
              if (searchQuery.isNotEmpty || selectedCategoryId != null)
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all),
                      SizedBox(width: 12),
                      Text('清除筛选'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'add',
                child: Row(
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 12),
                    Text('新增货品'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: isGroupedView
          ? _buildGroupedView(context, ref, groupedProductsAsyncValue)
          : _buildListView(context, ref, productsAsyncValue),
    );
  }

  Widget _buildListView(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ProductModel>> productsAsyncValue,
  ) {
    return productsAsyncValue.when(
      data: (products) {
        final sortedProducts = [...products]
          ..sort(
            (a, b) =>
                (b.lastUpdated ??
                        DateTime.fromMillisecondsSinceEpoch(
                          b.id ?? 0,
                        ))
                    .compareTo(
                      a.lastUpdated ??
                          DateTime.fromMillisecondsSinceEpoch(
                            a.id ?? 0,
                          ),
                    ),
          );
        return ProductList(
          data: sortedProducts,
          onEdit: (product) =>
              context.push(AppRoutes.productEditPath(product.id.toString())),
          onDelete: (product) =>
              _showDeleteConfirmDialog(context, ref, product),
          onAdjustInventory: (product) =>
              _showAdjustInventoryDialog(context, ref, product),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('加载失败: $error'),
            ElevatedButton(
              onPressed: () => ref.invalidate(allProductsProvider),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedView(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ProductGroupAggregate>> groupedProductsAsyncValue,
  ) {
    return groupedProductsAsyncValue.when(
      data: (groupedProducts) {
        return GroupedProductList(
          data: groupedProducts,
          onEdit: (product) =>
              context.push(AppRoutes.productEditPath(product.id.toString())),
          onDelete: (product) =>
              _showDeleteConfirmDialog(context, ref, product),
          onAdjustInventory: (product) =>
              _showAdjustInventoryDialog(context, ref, product),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('加载失败: $error'),
            ElevatedButton(
              onPressed: () => ref.invalidate(allProductsProvider),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}
