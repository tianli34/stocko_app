import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/backup_metadata.dart';

/// 备份详情对话框
class BackupDetailsDialog extends StatelessWidget {
  final BackupMetadata backup;

  const BackupDetailsDialog({
    super.key,
    required this.backup,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final fileSizeText = _formatFileSize(backup.fileSize);
    final totalRecords = backup.tableCounts.values.fold(0, (sum, count) => sum + count);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            backup.isEncrypted ? Icons.lock : Icons.backup,
            color: backup.isEncrypted 
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '备份详情',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 基本信息
              _buildSection(
                context,
                '基本信息',
                [
                  _buildDetailRow(context, '文件名', backup.fileName),
                  _buildDetailRow(context, '创建时间', dateFormat.format(backup.createdAt)),
                  _buildDetailRow(context, '文件大小', fileSizeText),
                  _buildDetailRow(context, '备份版本', backup.version),
                  if (backup.appVersion != null)
                    _buildDetailRow(context, '应用版本', backup.appVersion!),
                  if (backup.schemaVersion != null)
                    _buildDetailRow(context, '数据库版本', backup.schemaVersion.toString()),
                ],
              ),

              const SizedBox(height: 16),

              // 安全信息
              _buildSection(
                context,
                '安全信息',
                [
                  _buildDetailRow(
                    context, 
                    '加密状态', 
                    backup.isEncrypted ? '已加密' : '未加密',
                    valueColor: backup.isEncrypted 
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  _buildDetailRow(context, '校验和', backup.checksum),
                ],
              ),

              const SizedBox(height: 16),

              // 数据统计
              _buildSection(
                context,
                '数据统计',
                [
                  _buildDetailRow(context, '总记录数', totalRecords.toString()),
                  const SizedBox(height: 8),
                  ...backup.tableCounts.entries.map((entry) =>
                    _buildDetailRow(
                      context,
                      _getTableDisplayName(entry.key),
                      '${entry.value} 条',
                      indent: true,
                    ),
                  ),
                ],
              ),

              // 描述信息
              if (backup.description != null) ...[
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  '备份描述',
                  [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        backup.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    bool indent = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 4,
        left: indent ? 16 : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: indent ? 100 : 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _getTableDisplayName(String tableName) {
    // 将数据库表名转换为用户友好的显示名称
    switch (tableName.toLowerCase()) {
      case 'products':
        return '产品';
      case 'inventory':
        return '库存';
      case 'sales':
        return '销售';
      case 'purchases':
        return '采购';
      case 'customers':
        return '客户';
      case 'suppliers':
        return '供应商';
      case 'categories':
        return '分类';
      case 'users':
        return '用户';
      case 'settings':
        return '设置';
      default:
        return tableName;
    }
  }
}