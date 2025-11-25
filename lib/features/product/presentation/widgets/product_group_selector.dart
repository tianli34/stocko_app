import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../../application/provider/product_group_providers.dart';
import '../../domain/model/product_group.dart';

/// 商品组选择器组件
class ProductGroupSelector extends ConsumerStatefulWidget {
  final int? selectedGroupId;
  final String? variantName;
  final ValueChanged<int?> onGroupChanged;
  final ValueChanged<String?> onVariantNameChanged;

  const ProductGroupSelector({
    super.key,
    this.selectedGroupId,
    this.variantName,
    required this.onGroupChanged,
    required this.onVariantNameChanged,
  });

  @override
  ConsumerState<ProductGroupSelector> createState() =>
      _ProductGroupSelectorState();
}

class _ProductGroupSelectorState extends ConsumerState<ProductGroupSelector> {
  late TextEditingController _variantController;

  @override
  void initState() {
    super.initState();
    _variantController = TextEditingController(text: widget.variantName);
  }

  @override
  void didUpdateWidget(ProductGroupSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.variantName != widget.variantName) {
      _variantController.text = widget.variantName ?? '';
    }
  }

  @override
  void dispose() {
    _variantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(allProductGroupsProvider);

    return groupsAsync.when(
      data: (groups) => _buildContent(context, groups),
      loading: () => const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Text('加载商品组失败: $e'),
    );
  }

  Widget _buildContent(BuildContext context, List<ProductGroupData> groups) {
    // 构建选项列表：null 表示"无"，其他为商品组 ID
    final List<int?> options = [null, ...groups.map((g) => g.id)];

    // 获取显示名称
    String getDisplayName(int? id) {
      if (id == null) return '无（普通商品）';
      final group = groups.where((g) => g.id == id).firstOrNull;
      return group?.name ?? '未知商品组';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 商品组下拉选择
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField2<int?>(
                value: widget.selectedGroupId,
                decoration: InputDecoration(
                  labelText: '商品组（可选）',
                  hintText: '选择商品组以聚合展示',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                items: options.map((id) {
                  return DropdownMenuItem<int?>(
                    value: id,
                    child: Text(getDisplayName(id)),
                  );
                }).toList(),
                onChanged: (value) {
                  widget.onGroupChanged(value);
                  if (value == null) {
                    _variantController.clear();
                    widget.onVariantNameChanged(null);
                  }
                },
                buttonStyleData: const ButtonStyleData(
                  padding: EdgeInsets.only(right: 8),
                ),
                iconStyleData: const IconStyleData(
                  icon: Icon(Icons.arrow_drop_down),
                  iconSize: 24,
                ),
                dropdownStyleData: DropdownStyleData(
                  maxHeight: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 快速创建商品组按钮
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: '新建商品组',
              onPressed: () => _showCreateGroupDialog(context),
            ),
          ],
        ),

        // 变体名称输入（仅当选择了商品组时显示）
        if (widget.selectedGroupId != null) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _variantController,
            decoration: InputDecoration(
              labelText: '变体名称',
              hintText: '如：黄瓜味、番茄味、大包装',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              helperText: '用于区分同组内不同商品',
            ),
            onChanged: widget.onVariantNameChanged,
          ),
        ],
      ],
    );
  }

  Future<void> _showCreateGroupDialog(BuildContext context) async {
    final nameController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建商品组'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '商品组名称',
            hintText: '如：乐事薯片',
          ),
          autofocus: true,
          onSubmitted: (value) => Navigator.pop(ctx, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, nameController.text),
            child: const Text('创建'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      final model = ProductGroupModel(name: result.trim());
      final id = await ref
          .read(productGroupOperationsProvider.notifier)
          .createProductGroup(model);
      if (id != null) {
        widget.onGroupChanged(id);
      }
    }
  }
}
