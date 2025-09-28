import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/restore_preview.dart';

/// 恢复预览卡片组件
class RestorePreviewCard extends StatelessWidget {
  final RestorePreview preview;

  const RestorePreviewCard({
    super.key,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final totalRecords = preview.recordCounts.values.fold<int>(0, (sum, count) => sum + count);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.preview,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  '备份文件预览',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 基本信息
            _buildInfoSection(context, '基本信息', [
              _InfoItem('文件名', preview.metadata.fileName),
              _InfoItem('创建时间', dateFormat.format(preview.metadata.createdAt)),
              _InfoItem('文件大小', _formatFileSize(preview.metadata.fileSize)),
              _InfoItem('总记录数', '$totalRecords 条'),
              if (preview.metadata.isEncrypted)
                _InfoItem('加密状态', '已加密', color: Theme.of(context).colorScheme.secondary),
            ]),
            
            const SizedBox(height: 16),
            
            // 数据统计
            _buildInfoSection(context, '数据统计', 
              preview.recordCounts.entries.map((entry) => 
                _InfoItem(_getTableDisplayName(entry.key), '${entry.value} 条')
              ).toList(),
            ),
            
            if (preview.estimatedConflicts > 0) ...[
              const SizedBox(height: 16),
              _buildWarningSection(context, '预计冲突', '${preview.estimatedConflicts} 条记录可能存在冲突'),
            ],
            
            if (!preview.isCompatible || preview.compatibilityWarnings.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildCompatibilitySection(context),
            ],
            
            if (preview.estimatedDurationSeconds != null) ...[
              const SizedBox(height: 16),
              _buildInfoSection(context, '预计时间', [
                _InfoItem('恢复时间', _formatDuration(preview.estimatedDurationSeconds!)),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, List<_InfoItem> items) {
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
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: item.color,
                    fontWeight: item.color != null ? FontWeight.w500 : null,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildWarningSection(BuildContext context, String title, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning,
                color: Theme.of(context).colorScheme.onErrorContainer,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilitySection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: preview.isCompatible 
            ? Theme.of(context).colorScheme.secondaryContainer
            : Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                preview.isCompatible ? Icons.info : Icons.error,
                color: preview.isCompatible 
                    ? Theme.of(context).colorScheme.onSecondaryContainer
                    : Theme.of(context).colorScheme.onErrorContainer,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '兼容性检查',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: preview.isCompatible 
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            preview.isCompatible ? '备份文件与当前版本兼容' : '备份文件与当前版本不完全兼容',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: preview.isCompatible 
                  ? Theme.of(context).colorScheme.onSecondaryContainer
                  : Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          if (preview.compatibilityWarnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...preview.compatibilityWarnings.map((warning) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '• $warning',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: preview.isCompatible 
                        ? Theme.of(context).colorScheme.onSecondaryContainer
                        : Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          ],
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

  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds 秒';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes < 60) {
      return remainingSeconds > 0 ? '$minutes 分 $remainingSeconds 秒' : '$minutes 分';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '$hours 小时 $remainingMinutes 分';
  }

  String _getTableDisplayName(String tableName) {
    const tableNames = {
      'products': '产品',
      'categories': '分类',
      'units': '单位',
      'unit_products': '产品单位',
      'shops': '店铺',
      'suppliers': '供应商',
      'customers': '客户',
      'product_batches': '产品批次',
      'stock': '库存',
      'inventory_transactions': '库存交易',
      'locations': '货位',
      'inbound_receipts': '入库单',
      'inbound_items': '入库明细',
      'outbound_receipts': '出库单',
      'outbound_items': '出库明细',
      'purchase_orders': '采购单',
      'purchase_order_items': '采购明细',
      'sales_transactions': '销售交易',
      'sales_transaction_items': '销售明细',
      'barcodes': '条码',
    };
    return tableNames[tableName] ?? tableName;
  }
}

class _InfoItem {
  final String label;
  final String value;
  final Color? color;

  const _InfoItem(this.label, this.value, {this.color});
}