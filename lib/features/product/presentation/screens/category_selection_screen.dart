import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/category_notifier.dart';
import '../../domain/model/category.dart';
import '../../data/repository/product_repository.dart';

/// 类别选择屏幕
/// 支持选择、新增、重命名、删除类别的功能
class CategorySelectionScreen extends ConsumerStatefulWidget {
  final String? selectedCategoryId;
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
  // 用于管理每个类别的展开/收起状态
  final Map<String, bool> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelectionMode ? '选择类别' : '类别管理'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回',
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddCategoryDialog(context),
            icon: const Icon(Icons.add),
            tooltip: '新增类别',
          ),
        ],
      ),
      body: categories.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '暂无类别',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text('点击右上角 + 号添加新类别'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _buildHierarchicalList(categories).length,
              itemBuilder: (context, index) {
                final item = _buildHierarchicalList(categories)[index];
                return item;
              },
            ),
    );
  }

  List<Widget> _buildHierarchicalList(List<Category> categories) {
    final widgets = <Widget>[];

    // 获取顶级类别（无父级的类别）
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
    List<Category> allCategories,
    Category category,
    int level,
  ) {
    widgets.add(_buildCategoryTile(context, category, level, allCategories));

    // 获取当前类别的子类别
    final subCategories = allCategories
        .where((subCat) => subCat.parentId == category.id)
        .toList(); // 只有在展开状态下才递归添加子类别
    final isExpanded =
        _expandedCategories[category.id] ?? (level == 0); // 顶级类别默认展开，子类别默认收起
    if (isExpanded && subCategories.isNotEmpty) {
      for (final subCategory in subCategories) {
        _buildCategoryWithChildren(
          widgets,
          allCategories,
          subCategory,
          level + 1,
        );
      }
    }
  }

  Widget _buildCategoryTile(
    BuildContext context,
    Category category, [
    int level = 0,
    List<Category>? allCategories,
  ]) {
    final isSelected = widget.selectedCategoryId == category.id;
    final isSubCategory = level > 0;
    final isThirdLevel = level > 1;

    // 检查是否有子类别
    final hasSubCategories =
        allCategories?.any((cat) => cat.parentId == category.id) ?? false;
    final isExpanded =
        _expandedCategories[category.id] ?? (level == 0); // 顶级类别默认展开，子类别默认收起

    // 计算左侧边距
    final leftMargin = level * 24.0;

    return Container(
      margin: EdgeInsets.only(bottom: 8, left: leftMargin),
      child: Card(
        elevation: isSelected ? 4 : 1,
        color: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : null,
        child: ListTile(
          title: Row(
            children: [
              // 展开/收起图标（只对有子类别的类别显示）
              if (hasSubCategories) ...[
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _expandedCategories[category.id] = !isExpanded;
                    });
                  },
                  child: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  category.name,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: isSubCategory ? 14 : 16,
                  ),
                ),
              ),
            ],
          ),
          subtitle: isSubCategory
              ? Text(
                  isThirdLevel ? '三级类别' : '子类别',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                )
              : hasSubCategories
              ? Text(
                  '${allCategories?.where((cat) => cat.parentId == category.id).length ?? 0} 个子类别',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                onSelected: (action) =>
                    _handleCategoryAction(context, category, action),
                itemBuilder: (context) => [
                  // 可以为任何类别添加父类
                  const PopupMenuItem(
                    value: 'add_parent_category',
                    child: Row(
                      children: [
                        Icon(Icons.add, size: 20),
                        SizedBox(width: 8),
                        Text('新增父类'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('重命名'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete,
                          size: 20,
                          color: Color.fromARGB(255, 78, 6, 138),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '删除',
                          style: TextStyle(
                            color: Color.fromARGB(255, 85, 0, 141),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          onTap: () {
            if (widget.isSelectionMode) {
              // 选择模式：直接返回选中的类别
              Navigator.of(context).pop(category);
            } else if (hasSubCategories) {
              // 非选择模式且有子类别：切换展开/收起状态
              setState(() {
                _expandedCategories[category.id] = !isExpanded;
              });
            }
          },
        ),
      ),
    );
  }

  void _handleCategoryAction(
    BuildContext context,
    Category category,
    String action,
  ) {
    switch (action) {
      case 'add_parent_category':
        _showAddParentCategoryDialog(context, category);
        break;
      case 'edit':
        _showEditCategoryDialog(context, category);
        break;
      case 'delete':
        _showDeleteCategoryDialog(context, category);
        break;
    }
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增类别'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: '类别名称',
              hintText: '请输入类别名称',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入类别名称';
              }
              final categories = ref.read(categoriesProvider);
              if (categories.any((cat) => cat.name == value.trim())) {
                return '类别名称已存在';
              }
              return null;
            },
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await ref
                      .read(categoryListProvider.notifier)
                      .addCategory(name: nameController.text.trim());
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('类别添加成功'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('添加失败: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showAddParentCategoryDialog(
    BuildContext context,
    Category childCategory,
  ) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('为"${childCategory.name}"新增父类'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: '父类名称',
              hintText: '请输入父类名称',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入父类名称';
              }
              final categories = ref.read(categoriesProvider);
              if (categories.any((cat) => cat.name == value.trim())) {
                return '类别名称已存在';
              }
              return null;
            },
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  // 1. 先创建新的父类别
                  await ref
                      .read(categoryListProvider.notifier)
                      .addCategory(
                        name: nameController.text.trim(),
                        parentId: childCategory.parentId, // 新父类继承当前类别的父级
                      );

                  // 2. 获取新创建的父类别ID（根据名称查找）
                  await ref
                      .read(categoryListProvider.notifier)
                      .loadCategories();
                  final updatedCategories = ref.read(categoriesProvider);
                  final newParent = updatedCategories.firstWhere(
                    (cat) => cat.name == nameController.text.trim(),
                  );

                  // 3. 更新当前类别，让它成为新父类的子类
                  await ref
                      .read(categoryListProvider.notifier)
                      .updateCategory(
                        id: childCategory.id,
                        name: childCategory.name,
                        parentId: newParent.id, // 设置新创建的父类为父级
                      );

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('父类"${nameController.text.trim()}"创建成功'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('添加失败: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, Category category) {
    final nameController = TextEditingController(text: category.name);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名类别'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: '类别名称',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入类别名称';
              }
              final categories = ref.read(categoriesProvider);
              if (categories.any(
                (cat) => cat.name == value.trim() && cat.id != category.id,
              )) {
                return '类别名称已存在';
              }
              return null;
            },
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await ref
                      .read(categoryListProvider.notifier)
                      .updateCategory(
                        id: category.id,
                        name: nameController.text.trim(),
                      );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('类别重命名成功'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('重命名失败: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(
    BuildContext context,
    Category category,
  ) async {
    final categories = ref.read(categoriesProvider);
    final allSubCategories = _getAllSubCategories(categories, category.id);
    final hasSubCategories = allSubCategories.isNotEmpty;

    // 获取关联产品数量
    int relatedProductsCount = 0;
    try {
      final productRepository = ref.read(productRepositoryProvider);
      final products = await productRepository.getProductsByCondition(
        categoryId: category.id,
      );
      relatedProductsCount = products.length;
    } catch (e) {
      print('获取产品数量失败: $e');
      // 如果获取失败，使用0作为默认值
    }

    showDialog(
      context: context,
      builder: (context) => _DeleteCategoryDialog(
        category: category,
        hasSubCategories: hasSubCategories,
        subCategoriesCount: allSubCategories.length,
        relatedProductsCount: relatedProductsCount,
        onDeleteOnly: () async {
          try {
            await ref
                .read(categoryListProvider.notifier)
                .deleteCategoryOnly(category.id);
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('类别删除成功，子类别和产品已保留'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('删除失败: $e'), backgroundColor: Colors.red),
            );
          }
        },
        onDeleteCascade: () async {
          try {
            await ref
                .read(categoryListProvider.notifier)
                .deleteCategoryCascade(category.id);
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('类别及所有关联内容删除成功'),
                backgroundColor: Colors.orange,
              ),
            );
          } catch (e) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('删除失败: $e'), backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  // 递归获取所有子类别
  List<Category> _getAllSubCategories(
    List<Category> allCategories,
    String parentId,
  ) {
    final result = <Category>[];

    // 获取直接子类别
    final directSubCategories = allCategories
        .where((cat) => cat.parentId == parentId)
        .toList();

    for (final subCategory in directSubCategories) {
      result.add(subCategory);
      // 递归获取子类别的子类别
      result.addAll(_getAllSubCategories(allCategories, subCategory.id));
    }
    return result;
  }
}

/// 删除类别对话框组件
class _DeleteCategoryDialog extends StatefulWidget {
  final Category category;
  final bool hasSubCategories;
  final int subCategoriesCount;
  final int relatedProductsCount;
  final VoidCallback onDeleteOnly;
  final VoidCallback onDeleteCascade;

  const _DeleteCategoryDialog({
    required this.category,
    required this.hasSubCategories,
    required this.subCategoriesCount,
    required this.relatedProductsCount,
    required this.onDeleteOnly,
    required this.onDeleteCascade,
  });

  @override
  State<_DeleteCategoryDialog> createState() => _DeleteCategoryDialogState();
}

class _DeleteCategoryDialogState extends State<_DeleteCategoryDialog> {
  int _selectedOption = 0; // 0: 仅删除当前类别, 1: 级联删除

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange, size: 24),
          const SizedBox(width: 8),
          const Text('删除类别'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '即将删除类别 "${widget.category.name}"',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 显示影响范围信息
            if (widget.hasSubCategories || widget.relatedProductsCount > 0) ...[
              const Text(
                '影响范围：',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              if (widget.hasSubCategories)
                Row(
                  children: [
                    Icon(Icons.folder, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text('子类别：${widget.subCategoriesCount} 个'),
                  ],
                ),

              if (widget.relatedProductsCount > 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.inventory, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text('关联产品：${widget.relatedProductsCount} 个'),
                  ],
                ),
              ],

              const SizedBox(height: 16),
            ],

            const Text(
              '请选择删除模式：',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // 选项1：仅删除当前类别
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedOption == 0
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                  width: _selectedOption == 0 ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: _selectedOption == 0
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : null,
              ),
              child: RadioListTile<int>(
                value: 0,
                groupValue: _selectedOption,
                onChanged: (value) {
                  setState(() {
                    _selectedOption = value!;
                  });
                },
                title: const Text(
                  '仅删除当前类别',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    const Text('保留子类别和关联产品'),
                    const SizedBox(height: 8),

                    if (widget.hasSubCategories) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.category.parentId != null
                                  ? '子类别将转移到上级类别'
                                  : '子类别将成为根类别',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],

                    if (widget.relatedProductsCount > 0) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.category.parentId != null
                                  ? '产品将转移到上级类别'
                                  : '产品将取消类别关联',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                  ],
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),

            const SizedBox(height: 12),

            // 选项2：级联删除
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedOption == 1
                      ? Colors.red
                      : Colors.grey.shade300,
                  width: _selectedOption == 1 ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: _selectedOption == 1
                    ? Colors.red.withOpacity(0.1)
                    : null,
              ),
              child: RadioListTile<int>(
                value: 1,
                groupValue: _selectedOption,
                onChanged: (value) {
                  setState(() {
                    _selectedOption = value!;
                  });
                },
                title: const Text(
                  '级联删除所有内容',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    const Text('删除类别及所有关联内容'),
                    const SizedBox(height: 8),

                    if (widget.hasSubCategories) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.delete,
                            size: 14,
                            color: const Color.fromARGB(255, 136, 54, 244),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '删除所有子类别（${widget.subCategoriesCount} 个）',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color.fromARGB(255, 178, 47, 211),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],

                    if (widget.relatedProductsCount > 0) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.delete,
                            size: 14,
                            color: const Color.fromARGB(255, 152, 54, 244),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '删除所有关联产品（${widget.relatedProductsCount} 个）',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],

                    const Row(
                      children: [
                        Icon(Icons.warning, size: 14, color: Colors.orange),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '此操作不可恢复',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _selectedOption == 0
              ? widget.onDeleteOnly
              : widget.onDeleteCascade,
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedOption == 0 ? Colors.blue : Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(_selectedOption == 0 ? '仅删除类别' : '级联删除'),
        ),
      ],
    );
  }
}
