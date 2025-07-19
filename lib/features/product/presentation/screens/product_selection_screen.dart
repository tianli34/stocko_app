import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/product_list/index.dart';
import '../../application/category_notifier.dart';
import '../../application/provider/product_providers.dart';
import '../../domain/model/category.dart';
import 'category_selection_screen.dart';

class ProductSelectionScreen extends ConsumerStatefulWidget {
  const ProductSelectionScreen({super.key});

  @override
  ConsumerState<ProductSelectionScreen> createState() =>
      _ProductSelectionScreenState();
}

class _ProductSelectionScreenState
    extends ConsumerState<ProductSelectionScreen> {
  List<dynamic> selectedIds = [];

  @override
  void initState() {
    super.initState();
    // Entering the page, clearing the category selection
    Future.microtask(
      () => ref.read(selectedCategoryIdProvider.notifier).state = null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final allCategories = ref.watch(categoriesProvider);

    String? categoryName;
    if (selectedCategoryId != null) {
      final category = allCategories.firstWhere(
        (c) => c.id == selectedCategoryId,
        orElse: () => const Category(id: '', name: '未知分类'),
      );
      categoryName = category.name;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${categoryName ?? '选择货品'} (已选${selectedIds.length}种)',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          if (selectedCategoryId != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: '清除筛选',
              onPressed: () {
                ref.read(selectedCategoryIdProvider.notifier).state = null;
              },
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
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(selectedIds);
            },
            child: const Text('确定'),
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final productsAsync = ref.watch(filteredProductsProvider);
          return productsAsync.when(
            data: (products) => ProductList(
              data: products,
              mode: 'select',
              selectedIds: selectedIds,
              onSelectionChange: (newSelectedIds) {
                setState(() {
                  selectedIds = newSelectedIds;
                });
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('加载失败: $error')),
          );
        },
      ),
    );
  }
}
