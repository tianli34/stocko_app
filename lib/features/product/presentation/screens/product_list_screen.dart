import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/product_list/product_list.dart';
import '../../application/category_notifier.dart';
import '../../../inventory/application/inventory_service.dart';
import '../../application/provider/product_providers.dart';
import '../../domain/model/category.dart';
import '../../domain/model/product.dart';
import 'category_selection_screen.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    Product product,
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
          .deleteProduct(product.id);
    }
  }

  Future<void> _showAdjustInventoryDialog(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final quantityController = TextEditingController();
    // FIXME: Hardcoded shopId. In a real app, this should come from user session or selection.
    const shopId = 'default_shop';
    final inventory =
        await ref.read(inventoryServiceProvider).getInventory(product.id, shopId);
    if (inventory != null) {
      quantityController.text = inventory.quantity.toStringAsFixed(0);
    }

    final newQuantityString = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('调整库存: ${product.name}'),
        content: TextField(
          controller: quantityController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '新库存数量'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(quantityController.text);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (newQuantityString != null && newQuantityString.isNotEmpty) {
      final newQuantity = int.tryParse(newQuantityString);
      if (newQuantity == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无效的数字格式')),
        );
        return;
      }

      try {
        await ref
            .read(inventoryServiceProvider)
            .adjustInventory(product.id.toString(), newQuantity);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('库存调整成功')),
        );
        ref.invalidate(filteredProductsProvider); // Refresh the product list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('库存调整失败: $e')),
        );
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
          if (searchQuery.isNotEmpty || selectedCategoryId != null)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: '清除所有筛选和搜索',
              onPressed: () {
                ref.read(searchQueryProvider.notifier).state = '';
                ref.read(selectedCategoryIdProvider.notifier).state = null;
              },
            ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '搜索',
            onPressed: () => _showSearchDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: '按分类筛选',
            onPressed: () async {
              final selectedCategory = await Navigator.push<CategoryModel>(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategorySelectionScreen(),
                ),
              );
              if (selectedCategory != null) {
                ref.read(selectedCategoryIdProvider.notifier).state =
                    selectedCategory.id;
              }
            },
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.productNew),
            icon: const Icon(Icons.add),
            tooltip: '新增货品',
          ),
        ],
      ),
      body: productsAsyncValue.when(
        data: (products) {
          final sortedProducts = [...products]
            ..sort(
              (a, b) =>
                  (b.lastUpdated ??
                          DateTime.fromMillisecondsSinceEpoch(
                            b.id,
                          ))
                      .compareTo(
                        a.lastUpdated ??
                            DateTime.fromMillisecondsSinceEpoch(
                              a.id,
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
      ),
    );
  }
}
