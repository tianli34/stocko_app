import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/provider/category_providers.dart';
import '../../domain/model/category.dart';

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
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.selectedCategoryId;
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelectionMode ? '选择类别' : '类别管理'),
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
                  Icon(Icons.category_outlined, size: 64, color: Colors.grey),
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
      floatingActionButton:
          widget.isSelectionMode &&
              _selectedCategoryId != null &&
              categories.any((cat) => cat.id == _selectedCategoryId)
          ? FloatingActionButton.extended(
              onPressed: () {
                final selectedCategory = categories.firstWhere(
                  (cat) => cat.id == _selectedCategoryId,
                );
                Navigator.of(context).pop(selectedCategory);
              },
              icon: const Icon(Icons.check),
              label: const Text('确认选择'),
            )
          : null,
    );
  }

  List<Widget> _buildHierarchicalList(List<Category> categories) {
    final widgets = <Widget>[];

    // 获取顶级类别（无父级的类别）
    final topLevelCategories = categories
        .where((category) => category.parentId == null)
        .toList();

    for (final category in topLevelCategories) {
      widgets.add(_buildCategoryTile(context, category, 0));

      // 获取子类别
      final subCategories = categories
          .where((subCat) => subCat.parentId == category.id)
          .toList();

      for (final subCategory in subCategories) {
        widgets.add(_buildCategoryTile(context, subCategory, 1));
      }
    }

    return widgets;
  }

  Widget _buildCategoryTile(
    BuildContext context,
    Category category, [
    int level = 0,
  ]) {
    final isSelected = _selectedCategoryId == category.id;
    final isSubCategory = level > 0;

    return Container(
      margin: EdgeInsets.only(bottom: 8, left: isSubCategory ? 24.0 : 0.0),
      child: Card(
        elevation: isSelected ? 4 : 1,
        color: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : null,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isSelected
                ? Theme.of(context).primaryColor
                : isSubCategory
                ? Colors.grey.shade400
                : Colors.grey.shade300,
            child: Icon(
              isSubCategory ? Icons.subdirectory_arrow_right : Icons.category,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: isSubCategory ? 18 : 20,
            ),
          ),
          title: Text(
            category.name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: isSubCategory ? 14 : 16,
            ),
          ),
          subtitle: isSubCategory
              ? const Text(
                  '子类别',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isSelectionMode)
                Radio<String>(
                  value: category.id,
                  groupValue: _selectedCategoryId,
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                ),
              PopupMenuButton<String>(
                onSelected: (action) =>
                    _handleCategoryAction(context, category, action),
                itemBuilder: (context) => [
                  // 只有顶级类别可以添加子类
                  if (!isSubCategory)
                    const PopupMenuItem(
                      value: 'add_subcategory',
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 20),
                          SizedBox(width: 8),
                          Text('新增子类'),
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
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('删除', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          onTap: widget.isSelectionMode
              ? () {
                  setState(() {
                    _selectedCategoryId = category.id;
                  });
                }
              : null,
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
      case 'add_subcategory':
        _showAddSubCategoryDialog(context, category);
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
            onPressed: () {
              if (formKey.currentState!.validate()) {
                ref
                    .read(categoriesProvider.notifier)
                    .addCategory(nameController.text.trim());
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('类别添加成功'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showAddSubCategoryDialog(
    BuildContext context,
    Category parentCategory,
  ) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('新增子类 - ${parentCategory.name}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: '子类名称',
              hintText: '请输入子类名称',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入子类名称';
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
            onPressed: () {
              if (formKey.currentState!.validate()) {
                ref
                    .read(categoriesProvider.notifier)
                    .addSubCategory(
                      nameController.text.trim(),
                      parentCategory.id,
                    );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('子类"${nameController.text.trim()}"添加成功'),
                    backgroundColor: Colors.green,
                  ),
                );
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
            onPressed: () {
              if (formKey.currentState!.validate()) {
                ref
                    .read(categoriesProvider.notifier)
                    .updateCategory(category.id, nameController.text.trim());
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('类别重命名成功'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(BuildContext context, Category category) {
    final categories = ref.read(categoriesProvider);
    final hasSubCategories = categories.any(
      (cat) => cat.parentId == category.id,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除类别'),
        content: Text(
          hasSubCategories
              ? '确定要删除类别"${category.name}"吗？\n\n删除后该类别下的所有子类别也将被删除，且无法恢复。'
              : '确定要删除类别"${category.name}"吗？\n\n删除后无法恢复。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(categoriesProvider.notifier).deleteCategory(category.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('类别删除成功'),
                  backgroundColor: Colors.orange,
                ),
              );
              // 如果删除的是当前选中的类别，清除选择
              if (_selectedCategoryId == category.id) {
                setState(() {
                  _selectedCategoryId = null;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
