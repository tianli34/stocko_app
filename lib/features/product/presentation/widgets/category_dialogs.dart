import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/category_notifier.dart';
import '../../domain/model/category.dart';
import '../../../../core/utils/snackbar_helper.dart';

/// 新增类别对话框
class AddCategoryDialog extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;

  const AddCategoryDialog({super.key, this.onSuccess});

  @override
  ConsumerState<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends ConsumerState<AddCategoryDialog> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新增类别'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '类别名称',
            hintText: '请输入类别名称',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入类别名称';
            }
            final categories = ref.read(categoryListProvider).categories;
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
          onPressed: _handleAdd,
          child: const Text('添加'),
        ),
      ],
    );
  }

  Future<void> _handleAdd() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref
            .read(categoryListProvider.notifier)
            .addCategory(name: _nameController.text.trim());
        Navigator.of(context).pop();
        showAppSnackBar(context, message: '类别添加成功');
        widget.onSuccess?.call();
      } catch (e) {
        showAppSnackBar(context, message: '添加失败: $e', isError: true);
      }
    }
  }
}

/// 新增父类对话框
class AddParentCategoryDialog extends ConsumerStatefulWidget {
  final CategoryModel childCategory;
  final VoidCallback? onSuccess;

  const AddParentCategoryDialog({
    super.key,
    required this.childCategory,
    this.onSuccess,
  });

  @override
  ConsumerState<AddParentCategoryDialog> createState() =>
      _AddParentCategoryDialogState();
}

class _AddParentCategoryDialogState
    extends ConsumerState<AddParentCategoryDialog> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('为"${widget.childCategory.name}"新增父类'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '父类名称',
            hintText: '请输入父类名称',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入父类名称';
            }
            final categories = ref.read(categoryListProvider).categories;
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
          onPressed: _handleAdd,
          child: const Text('添加'),
        ),
      ],
    );
  }

  Future<void> _handleAdd() async {
    if (_formKey.currentState!.validate()) {
      try {
        // 1. 先创建新的父类别
        await ref.read(categoryListProvider.notifier).addCategory(
              name: _nameController.text.trim(),
              parentId: widget.childCategory.parentId,
            );

        // 2. 获取新创建的父类别ID
        await ref.read(categoryListProvider.notifier).loadCategories();
        final updatedCategories = ref.read(categoryListProvider).categories;
        final newParent = updatedCategories.firstWhere(
          (cat) => cat.name == _nameController.text.trim(),
        );

        // 3. 更新当前类别，让它成为新父类的子类
        await ref.read(categoryListProvider.notifier).updateCategory(
              id: widget.childCategory.id!,
              name: widget.childCategory.name,
              parentId: newParent.id,
            );

        Navigator.of(context).pop();
        showAppSnackBar(
          context,
          message: '父类"${_nameController.text.trim()}"创建成功',
        );
        widget.onSuccess?.call();
      } catch (e) {
        showAppSnackBar(context, message: '添加失败: $e', isError: true);
      }
    }
  }
}

/// 编辑类别对话框
class EditCategoryDialog extends ConsumerStatefulWidget {
  final CategoryModel category;
  final VoidCallback? onSuccess;

  const EditCategoryDialog({
    super.key,
    required this.category,
    this.onSuccess,
  });

  @override
  ConsumerState<EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends ConsumerState<EditCategoryDialog> {
  late final TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('重命名类别'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '类别名称',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入类别名称';
            }
            final categories = ref.read(categoryListProvider).categories;
            if (categories.any(
              (cat) => cat.name == value.trim() && cat.id != widget.category.id,
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
          onPressed: _handleSave,
          child: const Text('保存'),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(categoryListProvider.notifier).updateCategory(
              id: widget.category.id!,
              name: _nameController.text.trim(),
            );
        Navigator.of(context).pop();
        showAppSnackBar(context, message: '类别重命名成功');
        widget.onSuccess?.call();
      } catch (e) {
        showAppSnackBar(context, message: '重命名失败: $e', isError: true);
      }
    }
  }
}

/// 搜索对话框
class CategorySearchDialog extends StatefulWidget {
  final String initialQuery;

  const CategorySearchDialog({super.key, this.initialQuery = ''});

  @override
  State<CategorySearchDialog> createState() => _CategorySearchDialogState();
}

class _CategorySearchDialogState extends State<CategorySearchDialog> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, 150),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 9.0),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          onSubmitted: (value) => Navigator.of(context).pop(value),
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).scaffoldBackgroundColor,
            border: const OutlineInputBorder(borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 15.0,
              horizontal: 10.0,
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(_searchController.text),
                child: const Text('搜索'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
