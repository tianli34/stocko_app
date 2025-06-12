import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/model/unit.dart';
import '../../application/provider/unit_providers.dart';

/// 单位列表项组件
/// 用于在单位列表中显示单个单位的信息
class UnitListTile extends ConsumerWidget {
  final Unit unit;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool isSelected;

  const UnitListTile({
    super.key,
    required this.unit,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerState = ref.watch(unitControllerProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isSelected ? 4 : 2,
      color: isSelected
          ? Theme.of(context).primaryColor.withOpacity(0.1)
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部信息：名称和图标
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                    child: Icon(
                      Icons.straighten,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      unit.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // 单位详细信息
              _buildUnitInfo(context),

              // 操作按钮
              if (showActions) ...[
                const SizedBox(height: 12),
                _buildActionButtons(context, ref, controllerState),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建单位信息
  Widget _buildUnitInfo(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.tag, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          'ID: ${unit.id}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    UnitControllerState controllerState,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 编辑按钮
        TextButton.icon(
          onPressed: controllerState.isLoading ? null : onEdit,
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('编辑'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(width: 8),
        // 删除按钮
        TextButton.icon(
          onPressed: controllerState.isLoading
              ? null
              : () => _showDeleteConfirmation(context, ref),
          icon: const Icon(Icons.delete, size: 16),
          label: const Text('删除'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red.shade600,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除单位 "${unit.name}" 吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onDelete != null) {
                onDelete!();
              } else {
                // 默认删除操作
                final controller = ref.read(unitControllerProvider.notifier);
                controller.deleteUnit(unit.id);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade600),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

/// 单位列表项的简化版本
/// 适用于只需要显示基本信息的场景
class SimpleUnitListTile extends StatelessWidget {
  final Unit unit;
  final VoidCallback? onTap;
  final bool isSelected;

  const SimpleUnitListTile({
    super.key,
    required this.unit,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.2)
            : Colors.grey.shade200,
        child: Icon(
          Icons.straighten,
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade600,
          size: 20,
        ),
      ),
      title: Text(
        unit.name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        ),
      ),
      subtitle: Text('ID: ${unit.id}', style: const TextStyle(fontSize: 12)),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
          : null,
      selected: isSelected,
      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
    );
  }
}
