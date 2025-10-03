import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/restore_result.dart';

/// 恢复结果对话框
class RestoreResultDialog extends StatelessWidget {
  final RestoreResult result;
  final VoidCallback onClose;

  const RestoreResultDialog({
    super.key,
    required this.result,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final duration = result.endTime.difference(result.startTime);
    final durationText = _formatDuration(duration);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            result.success ? Icons.check_circle : Icons.error,
            color: result.success 
                ? Colors.green 
                : Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 12),
          Text(result.success ? '恢复成功' : '恢复失败'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.success) ...[
              _buildSuccessContent(context, durationText),
            ] else ...[
              _buildErrorContent(context),
            ],
            
            if (result.warnings.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildWarningsSection(context),
            ],
            
            const SizedBox(height: 16),
            _buildDetailsSection(context, durationText),
          ],
        ),
      ),
      actions: [
        if (result.success)
          TextButton(
            onPressed: () {
              // 可以添加查看详细日志的功能
            },
            child: const Text('查看详情'),
          ),
        ElevatedButton(
          onPressed: onClose,
          child: Text(result.success ? '完成' : '关闭'),
        ),
      ],
    );
  }

  Widget _buildSuccessContent(BuildContext context, String durationText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                Icons.backup_outlined,
                size: 48,
                color: Colors.green,
              ),
              const SizedBox(height: 8),
              Text(
                '数据恢复完成',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '成功恢复 ${result.totalRecordsRestored} 条记录',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '耗时: $durationText',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        
        if (result.tableRecordCounts.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            '恢复详情',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...result.tableRecordCounts.entries.map((entry) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      _getTableDisplayName(entry.key),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.value} 条',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(height: 8),
              Text(
                '恢复失败',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              if (result.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  result.errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        Text(
          '建议解决方案：',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text('• 检查备份文件是否完整且未损坏'),
        const Text('• 确认密码是否正确（如果文件已加密）'),
        const Text('• 检查设备存储空间是否充足'),
        const Text('• 尝试重新选择备份文件'),
      ],
    );
  }

  Widget _buildWarningsSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning,
                size: 16,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                '警告信息',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...result.warnings.map((warning) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '• $warning',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context, String durationText) {
    final timeFormat = DateFormat('HH:mm:ss');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '操作详情',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildDetailRow(context, '开始时间', timeFormat.format(result.startTime)),
        _buildDetailRow(context, '结束时间', timeFormat.format(result.endTime)),
        _buildDetailRow(context, '总耗时', durationText),
        if (result.skippedRecords > 0)
          _buildDetailRow(context, '跳过记录', '${result.skippedRecords} 条'),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '$hours 小时 $minutes 分 $seconds 秒';
    } else if (minutes > 0) {
      return '$minutes 分 $seconds 秒';
    } else {
      return '$seconds 秒';
    }
  }

  String _getTableDisplayName(String tableName) {
    const tableNames = {
      'product': '产品',
      'category': '分类',
      'unit': '单位',
      'unit_product': '产品单位',
      'shop': '店铺',
      'supplier': '供应商',
      'customers': '客户',
      'product_batch': '产品批次',
      'stock': '库存',
      'inventory_transaction': '库存交易',
      'locations': '货位',
      'inbound_receipt': '入库单',
      'inbound_item': '入库明细',
      'outbound_receipt': '出库单',
      'outbound_item': '出库明细',
      'purchase_order': '采购单',
      'purchase_order_item': '采购明细',
      'sales_transaction': '销售交易',
      'sales_transaction_item': '销售明细',
      'barcode': '条码',
    };
    return tableNames[tableName] ?? tableName;
  }
}