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
    // Entering the page, clearing the category selection and search
    Future.microtask(() {
      ref.read(selectedCategoryIdProvider.notifier).state = null;
      ref.read(searchQueryProvider.notifier).state = '';
    });
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
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(filteredProductsProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final allCategories = ref.watch(categoriesProvider);

    String? categoryName;
    if (selectedCategoryId != null) {
      final category = allCategories.firstWhere(
        (c) => c.id == selectedCategoryId,
        orElse: () => const Category(id: '', name: '未知分类'),
      );
      categoryName = category.name;
    }

    Widget titleWidget;
    final countSuffix = ' (已选${selectedIds.length}种)';

    // 使用 trim() 来确保 searchQuery 包含可见字符，而不仅仅是空格。
    if (searchQuery.trim().isNotEmpty) {
      titleWidget = Row(
        children: [
          Flexible(
            flex: 2,
            child: Text(
              searchQuery,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: const TextStyle(fontSize: 14), // 缩小字体以减少空间占用
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 5,
            child: Text(
              '(已选${selectedIds.length}种)',
              // overflow: TextOverflow.ellipsis,
              // softWrap: false,
              style: const TextStyle(fontSize: 14), // 统一缩小字体
            ),
          ),
        ],
      );
    } else {
      titleWidget = Text(
        '${categoryName ?? '选择货品'}$countSuffix',
        style: const TextStyle(fontSize: 15),
      );
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 33,
        title: titleWidget,
        actions: [
          Transform.translate(
            offset: const Offset(0, -8.0), // 向上移动按钮
            child: Wrap(
              spacing: -8.0, // 使用负间距来减少按钮间的空隙
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (searchQuery.isNotEmpty || selectedCategoryId != null)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.clear_all, size: 22),
                    tooltip: '清除所有筛选和搜索',
                    onPressed: () {
                      ref.read(searchQueryProvider.notifier).state = '';
                      ref.read(selectedCategoryIdProvider.notifier).state =
                          null;
                    },
                  ),
                IconButton(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.search, size: 22),
                  tooltip: '搜索',
                  onPressed: () => _showSearchDialog(context, ref),
                ),
                IconButton(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.filter_list, size: 22),
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
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(selectedIds);
                    },
                    child: const Text('确定'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) {
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
            mode: 'select',
            selectedIds: selectedIds,
            onSelectionChange: (newSelectedIds) {
              setState(() {
                selectedIds = newSelectedIds;
              });
            },
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
