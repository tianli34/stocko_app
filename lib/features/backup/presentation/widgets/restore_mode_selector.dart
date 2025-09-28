import 'package:flutter/material.dart';
import '../../domain/models/restore_mode.dart';

/// 恢复模式选择器组件
class RestoreModeSelector extends StatelessWidget {
  final RestoreMode selectedMode;
  final ValueChanged<RestoreMode> onModeChanged;

  const RestoreModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_backup_restore,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  '恢复模式',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildModeOption(
              context,
              RestoreMode.merge,
              '合并数据',
              '保留现有数据，添加备份中的新数据。如果存在冲突，优先使用备份数据。',
              Icons.merge,
              Colors.blue,
            ),
            
            const SizedBox(height: 12),
            
            _buildModeOption(
              context,
              RestoreMode.replace,
              '完全替换',
              '删除所有现有数据，完全使用备份数据替换。此操作不可撤销！',
              Icons.swap_horiz,
              Colors.red,
            ),
            
            const SizedBox(height: 12),
            
            _buildModeOption(
              context,
              RestoreMode.addOnly,
              '仅添加新数据',
              '只添加不存在的数据，不修改现有记录。最安全的恢复模式。',
              Icons.add_circle_outline,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption(
    BuildContext context,
    RestoreMode mode,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = selectedMode == mode;
    
    return InkWell(
      onTap: () => onModeChanged(mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected 
                ? color
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected 
              ? color.withValues(alpha: 0.1)
              : null,
        ),
        child: Row(
          children: [
            Radio<RestoreMode>(
              value: mode,
              groupValue: selectedMode,
              onChanged: (value) {
                if (value != null) {
                  onModeChanged(value);
                }
              },
              activeColor: color,
            ),
            const SizedBox(width: 8),
            Icon(
              icon,
              color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}