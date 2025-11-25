import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../application/provider/product_group_providers.dart';
import '../../application/provider/product_providers.dart';
import '../../domain/model/product_group.dart';
import 'product_group_detail_screen.dart';

/// 商品组列表页面
class ProductGroupListScreen extends ConsumerWidget {
  const ProductGroupListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(allProductGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('商品组管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新建商品组',
            onPressed: () => _showAddEditDialog(context, ref),
          ),
        ],
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('暂无商品组', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text(
                    '商品组用于聚合同系列不同口味/规格的商品',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('创建商品组'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return _ProductGroupTile(
                group: group,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductGroupDetailScreen(groupId: group.id),
                  ),
                ),
                onEdit: () => _showAddEditDialog(context, ref, group: group),
                onDelete: () => _confirmDelete(context, ref, group),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Future<void> _showAddEditDialog(
    BuildContext context,
    WidgetRef ref, {
    ProductGroupData? group,
  }) async {
    final nameController = TextEditingController(text: group?.name ?? '');
    final descController = TextEditingController(text: group?.description ?? '');
    final isEdit = group != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? '编辑商品组' : '新建商品组'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '商品组名称',
                hintText: '如：乐事薯片',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
                hintText: '如：各种口味的乐事薯片',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isEdit ? '保存' : '创建'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      final model = ProductGroupModel(
        id: group?.id,
        name: nameController.text.trim(),
        description: descController.text.trim().isEmpty
            ? null
            : descController.text.trim(),
      );

      final notifier = ref.read(productGroupOperationsProvider.notifier);
      if (isEdit) {
        final success = await notifier.updateProductGroup(model);
        if (success) {
          ToastService.success('商品组已更新');
        }
      } else {
        final id = await notifier.createProductGroup(model);
        if (id != null) {
          ToastService.success('商品组已创建');
        }
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ProductGroupData group,
  ) async {
    // 检查是否有关联商品
    final products = await ref.read(allProductsProvider.future);
    final linkedProducts = products.where((p) => p.groupId == group.id).toList();

    if (linkedProducts.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('无法删除'),
          content: Text('该商品组下有 ${linkedProducts.length} 个商品，请先移除关联后再删除。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('知道了'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除商品组「${group.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(productGroupOperationsProvider.notifier)
          .deleteProductGroup(group.id);
      if (success) {
        ToastService.success('商品组已删除');
      }
    }
  }
}

class _ProductGroupTile extends StatelessWidget {
  final ProductGroupData group;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductGroupTile({
    required this.group,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Icon(Icons.folder, color: Theme.of(context).primaryColor),
      ),
      title: Text(group.name),
      subtitle: group.description != null ? Text(group.description!) : null,
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') onEdit();
          if (value == 'delete') onDelete();
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: Text('编辑')),
          const PopupMenuItem(
            value: 'delete',
            child: Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
