import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/product_list/product_list.dart';
import '../../application/category_notifier.dart';
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

    print('*****************************************************************');
    print('***** 🔍 Search Dialog Closed 🔍 *****');
    print('*****************************************************************');
    print('  - Dialog-provided search query: "$newQuery"');

    if (newQuery != null) {
      print('  - ✅ Query is not null. Updating provider...');
      ref.read(searchQueryProvider.notifier).state = newQuery;
      print('  - 🟢 SUCCESS: searchQueryProvider updated to "$newQuery"');
    } else {
      print('  - 🟡 Query is null. No update will be performed.');
    }
    print('*****************************************************************');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsyncValue = ref.watch(filteredProductsProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final allCategories = ref.watch(categoriesProvider);

    print('=================================================================');
    print('==== 📺 ProductListScreen BUILD Method Executed 📺 ====');
    print('=================================================================');
    print('  - ⚡️ Current Search Query: "$searchQuery"');
    print('  - ⚡️ Current Category ID: "$selectedCategoryId"');
    print('  - ⚡️ productsAsyncValue state: ${productsAsyncValue.runtimeType}');

    String? categoryName;
    if (selectedCategoryId != null) {
      final category = allCategories.firstWhere(
        (c) => c.id == selectedCategoryId,
        orElse: () => const Category(id: '', name: '未知分类'),
      );
      categoryName = category.name;
    }

    Widget titleWidget;
    if (searchQuery.isNotEmpty) {
      titleWidget = Row(
        children: [
          const Icon(Icons.search, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(searchQuery, overflow: TextOverflow.ellipsis)),
        ],
      );
    } else {
      titleWidget = Text(categoryName ?? '货品列表');
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
              final selectedCategory = await Navigator.push<Category>(
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
          print(
            '  -> 📊 [Data] Received ${products.length} products to display.',
          );
          if (products.isNotEmpty) {
            print('  -> Sample: ${products.first.name}');
          }
          final sortedProducts = [...products]
            ..sort(
              (a, b) =>
                  (b.lastUpdated ??
                          DateTime.fromMillisecondsSinceEpoch(
                            int.tryParse(b.id) ?? 0,
                          ))
                      .compareTo(
                        a.lastUpdated ??
                            DateTime.fromMillisecondsSinceEpoch(
                              int.tryParse(a.id) ?? 0,
                            ),
                      ),
            );
          return ProductList(
            data: sortedProducts,
            onEdit: (product) =>
                context.push(AppRoutes.productEditPath(product.id)),
            onDelete: (product) =>
                _showDeleteConfirmDialog(context, ref, product),
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
