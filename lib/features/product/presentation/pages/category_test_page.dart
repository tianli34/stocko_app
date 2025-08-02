import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/category_notifier.dart';
import '../../application/category_sample_data_service.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../domain/model/category.dart';

/// 类别管理测试页面
class CategoryTestPage extends ConsumerStatefulWidget {
  const CategoryTestPage({super.key});

  @override
  ConsumerState<CategoryTestPage> createState() => _CategoryTestPageState();
}

class _CategoryTestPageState extends ConsumerState<CategoryTestPage> {
  final _nameController = TextEditingController();
  String? _selectedParentId;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryListState = ref.watch(categoryListProvider);
    final allCategoriesStream = ref.watch(allCategoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('类别管理测试'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              final sampleDataService = ref.read(
                categorySampleDataServiceProvider,
              );

              if (value == 'create_sample') {
                try {
                  await sampleDataService.createSampleCategories();
                  if (mounted) {
                    showAppSnackBar(context, message: '示例数据创建成功');
                  }
                } catch (e) {
                  if (mounted) {
                    showAppSnackBar(context,
                        message: '创建示例数据失败: $e', isError: true);
                  }
                }
              } else if (value == 'clear_all') {
                try {
                  await sampleDataService.clearAllCategories();
                  if (mounted) {
                    showAppSnackBar(context, message: '所有数据已清除');
                  }
                } catch (e) {
                  if (mounted) {
                    showAppSnackBar(context,
                        message: '清除数据失败: $e', isError: true);
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'create_sample',
                child: Row(
                  children: [
                    Icon(Icons.add_box),
                    SizedBox(width: 8),
                    Text('创建示例数据'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.red),
                    SizedBox(width: 8),
                    Text('清除所有数据', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 添加类别表单
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '添加新类别',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '类别名称',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedParentId,
                      decoration: const InputDecoration(
                        labelText: '父类别（可选）',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('无（根类别）'),
                        ),
                        ...categoryListState.categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(category.name),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedParentId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: categoryListState.isLoading
                          ? null
                          : () => _addCategory(),
                      child: categoryListState.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('添加类别'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 错误信息显示
            if (categoryListState.error != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          categoryListState.error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ref.read(categoryListProvider.notifier).clearError();
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // 类别列表
            const Text(
              '类别列表',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: allCategoriesStream.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return const Center(child: Text('暂无类别数据'));
                  }

                  return ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            category.parentId == null
                                ? Icons.folder
                                : Icons.folder_outlined,
                            color: category.parentId == null
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          title: Text(category.name),
                          subtitle: Text(
                            category.parentId == null
                                ? '根类别'
                                : '父类别: ${_getParentName(category.parentId!, categories)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _showEditDialog(category),
                                icon: const Icon(Icons.edit),
                              ),
                              IconButton(
                                onPressed: () => _showDeleteDialog(category),
                                icon: Icon(
                                  Icons.delete,
                                  color: Colors.red.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) =>
                    Center(child: Text('加载失败: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getParentName(String parentId, List<Category> categories) {
    final parent = categories.firstWhere(
      (cat) => cat.id == parentId,
      orElse: () => Category(id: '', name: '未知'),
    );
    return parent.name;
  }

  Future<void> _addCategory() async {
    if (_nameController.text.trim().isEmpty) {
      showAppSnackBar(context, message: '请输入类别名称', isError: true);
      return;
    }

    try {
      await ref
          .read(categoryListProvider.notifier)
          .addCategory(
            name: _nameController.text.trim(),
            parentId: _selectedParentId,
          );

      _nameController.clear();
      setState(() {
        _selectedParentId = null;
      });

      if (mounted) {
        showAppSnackBar(context, message: '类别添加成功');
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: '添加失败: $e', isError: true);
      }
    }
  }

  void _showEditDialog(Category category) {
    final nameController = TextEditingController(text: category.name);
    String? selectedParentId = category.parentId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('编辑类别'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '类别名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedParentId,
                decoration: const InputDecoration(
                  labelText: '父类别',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('无（根类别）'),
                  ),
                  ...ref
                      .read(categoryListProvider)
                      .categories
                      .where((cat) => cat.id != category.id) // 排除自己
                      .map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat.id,
                          child: Text(cat.name),
                        );
                      }),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedParentId = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref
                      .read(categoryListProvider.notifier)
                      .updateCategory(
                        id: category.id,
                        name: nameController.text.trim(),
                        parentId: selectedParentId,
                      );

                  if (mounted) {
                    Navigator.of(context).pop();
                    showAppSnackBar(context, message: '类别更新成功');
                  }
                } catch (e) {
                  if (mounted) {
                    showAppSnackBar(context,
                        message: '更新失败: $e', isError: true);
                  }
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除类别"${category.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref
                    .read(categoryListProvider.notifier)
                    .deleteCategory(category.id);

                if (mounted) {
                  Navigator.of(context).pop();
                  showAppSnackBar(context, message: '类别删除成功');
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  showAppSnackBar(context, message: '删除失败: $e', isError: true);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
