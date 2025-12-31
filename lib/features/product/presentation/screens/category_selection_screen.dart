import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/category_notifier.dart';
import '../../domain/model/category.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../data/repository/product_repository.dart';
import '../widgets/category_tile.dart';
import '../widgets/category_dialogs.dart';
import '../widgets/delete_category_dialog.dart';

/// 类别选择屏幕
/// 支持选择、新增、重命名、删除类别的功能
class CategorySelectionScreen extends ConsumerStatefulWidget {
  final int? selectedCategoryId;
  final bool isSelectionMode;

  const CategorySelectionScreen({
    super.key,
    this.selectedCategoryId,
    this.isSelectionMode = true,
  });

  @override
  ConsumerState<CategorySelectionScreen> createState() =>
      _CategorySelectionScreenState();
}

class _CategorySelectionScreenState
    extends ConsumerState<CategorySelectionScreen> {
  final Map<int, bool> _expandedCategories = {};
  String _searchQuery = '';
  final Map<int, int> _categoryProductCounts = {};
  List<CategoryModel>? _previousCategories;

  @override
  void initState() {
    super.initState();
    _loadProductCounts();
  }

  Future<void> _loadProductCounts() async {
    final categoryState = ref.read(categoryListProvider);
    final productRepository = ref.read(productRepositoryProvider);
    final allCategories = categoryState.categories;

    final childrenMap = <int, List<int>>{};
    for (final category in allCategories) {
      if (category.parentId != null) {
        childrenMap.putIfAbsent(category.parentId!, () => []);
        if (category.id != null) {
          childrenMap[category.parentId!]!.add(category.id!);
        }
      }
    }

    final directCounts = <int, int>{};
    final categoryIds = allCategories
        .where((c) => c.id != null)
        .map((c) => c.id!)
        .toList();

    try {
      final futures = categoryIds.map((id) async {
        try {
          final products = await productRepository.getProductsByCondition(
            categoryId: id,
          );
          return MapEntry(id, products.length);
        } catch (e) {
          debugPrint('获取类别 $id 产品数量失败: $e');
          return MapEntry(id, 0);
        }
      });

      final results = await Future.wait(futures);
      for (final entry in results) {
        directCounts[entry.key] = entry.value;
      }
    } catch (e) {
      debugPrint('批量获取产品数量失败: $e');
    }

    for (final category in allCategories) {
      if (category.id != null) {
        final totalCount = _calculateTotalCount(
          category.id!,
          directCounts,
          childrenMap,
        );
        _categoryProductCounts[category.id!] = totalCount;
      }
    }

    if (mounted) setState(() {});
  }

  int _calculateTotalCount(
    int categoryId,
    Map<int, int> directCounts,
    Map<int, List<int>> childrenMap,
  ) {
    int total = directCounts[categoryId] ?? 0;
    final children = childrenMap[categoryId];
    if (children != null) {
      for (final childId in children) {
        total += _calculateTotalCount(childId, directCounts, childrenMap);
      }
    }
    return total;
  }

  List<CategoryModel> _getFilteredCategories(List<CategoryModel> categories) {
    if (_searchQuery.isEmpty) return categories;
    final lowerCaseQuery = _searchQuery.toLowerCase();
    return categories
        .where((c) => c.name.toLowerCase().contains(lowerCaseQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryListProvider);
    final allCategories = categoryState.categories;
    final filteredCategories = _getFilteredCategories(allCategories);

    if (_previousCategories != allCategories) {
      _previousCategories = allCategories;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProductCounts());
    }

    final hierarchicalList = _searchQuery.isEmpty
        ? _buildHierarchicalList(filteredCategories)
        : <Widget>[];

    return Scaffold(
      appBar: _buildAppBar(filteredCategories),
      body: filteredCategories.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _searchQuery.isNotEmpty
                  ? filteredCategories.length
                  : hierarchicalList.length,
              itemBuilder: (context, index) {
                if (_searchQuery.isNotEmpty) {
                  return _buildCategoryTile(filteredCategories[index], 0, allCategories);
                }
                return hierarchicalList[index];
              },
            ),
    );
  }

  AppBar _buildAppBar(List<CategoryModel> filteredCategories) {
    return AppBar(
      title: _searchQuery.isNotEmpty
          ? Row(
              children: [
                const Icon(Icons.search, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(_searchQuery, overflow: TextOverflow.ellipsis)),
                Text('(${filteredCategories.length})'),
              ],
            )
          : Text(widget.isSelectionMode ? '选择类别' : '类别管理'),
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back),
        tooltip: '返回',
      ),
      actions: [
        if (_searchQuery.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: '清除搜索',
            onPressed: () => setState(() => _searchQuery = ''),
          ),
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: '搜索',
          onPressed: _showSearchDialog,
        ),
        IconButton(
          onPressed: _showAddCategoryDialog,
          icon: const Icon(Icons.add),
          tooltip: '新增类别',
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? '未找到匹配的类别' : '暂无类别',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(_searchQuery.isNotEmpty ? '尝试其他关键词' : '点击右上角 + 号添加新类别'),
        ],
      ),
    );
  }

  List<Widget> _buildHierarchicalList(List<CategoryModel> categories) {
    final widgets = <Widget>[];
    final topLevelCategories = categories
        .where((category) => category.parentId == null)
        .toList();

    for (final category in topLevelCategories) {
      _buildCategoryWithChildren(widgets, categories, category, 0);
    }
    return widgets;
  }

  void _buildCategoryWithChildren(
    List<Widget> widgets,
    List<CategoryModel> allCategories,
    CategoryModel category,
    int level,
  ) {
    widgets.add(_buildCategoryTile(category, level, allCategories));

    if (category.id != null) {
      final subCategories = allCategories
          .where((subCat) => subCat.parentId == category.id)
          .toList();
      final isExpanded = _expandedCategories[category.id!] ?? false;
      if (isExpanded && subCategories.isNotEmpty) {
        for (final subCategory in subCategories) {
          _buildCategoryWithChildren(widgets, allCategories, subCategory, level + 1);
        }
      }
    }
  }

  Widget _buildCategoryTile(
    CategoryModel category,
    int level,
    List<CategoryModel> allCategories,
  ) {
    final categoryId = category.id;
    if (categoryId == null) return const SizedBox.shrink();

    final isSelected = widget.selectedCategoryId == categoryId;
    final hasSubCategories = allCategories.any((cat) => cat.parentId == categoryId);
    final isExpanded = _expandedCategories[categoryId] ?? false;
    final productCount = _categoryProductCounts[categoryId] ?? 0;
    final subCategoriesCount = allCategories.where((cat) => cat.parentId == categoryId).length;

    return CategoryTile(
      category: category,
      level: level,
      isSelected: isSelected,
      hasSubCategories: hasSubCategories,
      isExpanded: isExpanded,
      productCount: productCount,
      subCategoriesCount: subCategoriesCount,
      onExpandToggle: () => setState(() {
        _expandedCategories[categoryId] = !isExpanded;
      }),
      onTap: () => _handleCategoryTap(category, level, hasSubCategories, isExpanded),
      onAction: (action) => _handleCategoryAction(category, action),
    );
  }

  void _handleCategoryTap(
    CategoryModel category,
    int level,
    bool hasSubCategories,
    bool isExpanded,
  ) {
    final categoryId = category.id;
    if (categoryId == null) return;

    if (widget.isSelectionMode) {
      if (category.name == '烟' && level == 0 && hasSubCategories) {
        setState(() => _expandedCategories[categoryId] = !isExpanded);
      } else {
        Navigator.of(context).pop(category);
      }
    } else if (hasSubCategories) {
      setState(() => _expandedCategories[categoryId] = !isExpanded);
    }
  }

  void _handleCategoryAction(CategoryModel category, String action) {
    switch (action) {
      case 'add_parent_category':
        _showAddParentCategoryDialog(category);
        break;
      case 'edit':
        _showEditCategoryDialog(category);
        break;
      case 'delete':
        _showDeleteCategoryDialog(category);
        break;
    }
  }

  Future<void> _showSearchDialog() async {
    final newQuery = await showDialog<String>(
      context: context,
      builder: (context) => CategorySearchDialog(initialQuery: _searchQuery),
    );
    if (newQuery != null) setState(() => _searchQuery = newQuery);
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AddCategoryDialog(onSuccess: _loadProductCounts),
    );
  }

  void _showAddParentCategoryDialog(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AddParentCategoryDialog(
        childCategory: category,
        onSuccess: _loadProductCounts,
      ),
    );
  }

  void _showEditCategoryDialog(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => EditCategoryDialog(
        category: category,
        onSuccess: _loadProductCounts,
      ),
    );
  }

  Future<void> _showDeleteCategoryDialog(CategoryModel category) async {
    final categoryId = category.id;
    if (categoryId == null) {
      showAppSnackBar(context, message: '无效的类别', isError: true);
      return;
    }

    final categories = ref.read(categoryListProvider).categories;
    final allSubCategories = _getAllSubCategories(categories, categoryId);

    int relatedProductsCount = 0;
    try {
      final productRepository = ref.read(productRepositoryProvider);
      final products = await productRepository.getProductsByCondition(categoryId: categoryId);
      relatedProductsCount = products.length;
    } catch (e) {
      debugPrint('获取产品数量失败: $e');
    }

    showDialog(
      context: context,
      builder: (context) => DeleteCategoryDialog(
        category: category,
        hasSubCategories: allSubCategories.isNotEmpty,
        subCategoriesCount: allSubCategories.length,
        relatedProductsCount: relatedProductsCount,
        onDeleteOnly: () async {
          try {
            await ref.read(categoryListProvider.notifier).deleteCategoryOnly(categoryId);
            Navigator.of(context).pop();
            showAppSnackBar(context, message: '类别删除成功，子类别和产品已保留');
            _loadProductCounts();
          } catch (e) {
            Navigator.of(context).pop();
            showAppSnackBar(context, message: '删除失败: $e', isError: true);
          }
        },
        onDeleteCascade: () async {
          try {
            await ref.read(categoryListProvider.notifier).deleteCategoryCascade(categoryId);
            Navigator.of(context).pop();
            showAppSnackBar(context, message: '类别及所有关联内容删除成功', isError: true);
            _loadProductCounts();
          } catch (e) {
            Navigator.of(context).pop();
            showAppSnackBar(context, message: '删除失败: $e', isError: true);
          }
        },
      ),
    );
  }

  List<CategoryModel> _getAllSubCategories(List<CategoryModel> allCategories, int parentId) {
    final result = <CategoryModel>[];
    final directSubCategories = allCategories.where((cat) => cat.parentId == parentId).toList();

    for (final subCategory in directSubCategories) {
      result.add(subCategory);
      if (subCategory.id != null) {
        result.addAll(_getAllSubCategories(allCategories, subCategory.id!));
      }
    }
    return result;
  }
}
