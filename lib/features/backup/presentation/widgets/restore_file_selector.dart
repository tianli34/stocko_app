import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

/// 恢复文件选择器组件
class RestoreFileSelector extends StatelessWidget {
  final String? selectedFilePath;
  final VoidCallback onSelectFile;

  const RestoreFileSelector({
    super.key,
    this.selectedFilePath,
    required this.onSelectFile,
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
                  Icons.folder_open,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  '选择备份文件',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (selectedFilePath == null) ...[
              Text(
                '请选择要恢复的备份文件',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onSelectFile,
                  icon: const Icon(Icons.file_open),
                  label: const Text('选择文件'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.insert_drive_file,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '已选择文件',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            path.basename(selectedFilePath!),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onSelectFile,
                      icon: Icon(
                        Icons.edit,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                      tooltip: '重新选择',
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            Text(
              '支持的文件格式: .json, .backup',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}