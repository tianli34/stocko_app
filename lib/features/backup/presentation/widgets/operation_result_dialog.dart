import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/backup_metadata.dart';
import '../../domain/models/restore_result.dart';

/// 操作结果对话框 - 用于显示备份或恢复完成后的详细结果
class OperationResultDialog extends StatelessWidget {
  final String title;
  final bool isSuccess;
  final String? errorMessage;
  final BackupMetadata? backupMetadata;
  final RestoreResult? restoreResult;
  final String? filePath;
  final VoidCallback? onClose;
  final VoidCallback? onRetry;
  final VoidCallback? onShare;

  const OperationResultDialog({
    super.key,
    required this.title,
    required this.isSuccess,
    this.errorMessage,
    this.backupMetadata,
    this.restoreResult,
    this.filePath,
    this.onClose,
    this.onRetry,
    this.onShare,
  });

  /// 创建备份结果对话框
  factory OperationResultDialog.backup({
    required bool isSuccess,
    String? errorMessage,
    BackupMetadata? metadata,
    String? filePath,
    VoidCallback? onClose,
    VoidCallback? onRetry,
    VoidCallback? onShare,
  }) {
    return OperationResultDialog(
      title: isSuccess ? '备份完成' : '备份失败',
      isSuccess: isSuccess,
      errorMessage: errorMessage,
      backupMetadata: metadata,
      filePath: filePath,
      onClose: onClose,
      onRetry: onRetry,
      onShare: onShare,
    );
  }

  /// 创建恢复结果对话框
  factory OperationResultDialog.restore({
    required bool isSuccess,
    String? errorMessage,
    RestoreResult? result,
    VoidCallback? onClose,
    VoidCallback? onRetry,
  }) {
    return OperationResultDialog(
      title: isSuccess ? '恢复完成' : '恢复失败',
      isSuccess: isSuccess,
      errorMessage: errorMessage,
      restoreResult: result,
      onClose: onClose,
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: _buildTitle(context),
      content: SingleChildScrollView(child: _buildContent(context)),
      actions: _buildActions(context),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final iconData = isSuccess ? Icons.check_circle : Icons.error;
    final iconColor = isSuccess
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;

    return Row(
      children: [
        Icon(iconData, color: iconColor),
        const SizedBox(width: 12),
        Text(title),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (!isSuccess) {
      return _buildErrorContent(context);
    }

    if (backupMetadata != null) {
      return _buildBackupSuccessContent(context);
    }

    if (restoreResult != null) {
      return _buildRestoreSuccessContent(context);
    }

    return const SizedBox.shrink();
  }

  Widget _buildErrorContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                Icons.error,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '操作失败',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? '发生未知错误',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupSuccessContent(BuildContext context) {
    final metadata = backupMetadata!;
    final totalRecords = metadata.tableCounts.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );
    final fileSizeText = _formatFileSize(metadata.fileSize);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '备份创建成功！',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(context, '备份名称', metadata.fileName),
              _buildInfoRow(
                context,
                '创建时间',
                _formatDateTime(metadata.createdAt),
              ),
              _buildInfoRow(context, '文件大小', fileSizeText),
              _buildInfoRow(context, '总记录数', totalRecords.toString()),
              if (metadata.description != null)
                _buildInfoRow(context, '描述', metadata.description!),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildTableCounts(context, metadata.tableCounts),
        if (filePath != null) ...[
          const SizedBox(height: 16),
          _buildFilePathInfo(context, filePath!),
        ],
      ],
    );
  }

  Widget _buildRestoreSuccessContent(BuildContext context) {
    final result = restoreResult!;
    final duration = result.endTime.difference(result.startTime);
    final durationText = duration.inMinutes > 0
        ? '${duration.inMinutes}分${duration.inSeconds % 60}秒'
        : '${duration.inSeconds}秒';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '数据恢复成功！“什么时候才能帮窗台的老盆栽擦掉年轮呀？”',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                '总记录数',
                result.totalRecordsRestored.toString(),
              ),
              _buildInfoRow(context, '耗时', durationText),
              _buildInfoRow(context, '开始时间', _formatDateTime(result.startTime)),
              _buildInfoRow(context, '结束时间', _formatDateTime(result.endTime)),
            ],
          ),
        ),
        if (result.tableRecordCounts.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildTableCounts(context, result.tableRecordCounts),
        ],
        if (result.warnings.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildWarnings(context, result.warnings),
        ],
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCounts(BuildContext context, Map<String, int> tableCounts) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '数据统计:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...tableCounts.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getTableDisplayName(entry.key),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    entry.value.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarnings(BuildContext context, List<String> warnings) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
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
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                '注意事项:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...warnings.map(
            (warning) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $warning',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePathInfo(BuildContext context, String path) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.folder,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                '文件位置:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  path,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _copyToClipboard(context, path),
                icon: const Icon(Icons.copy, size: 16),
                tooltip: '复制路径',
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    if (!isSuccess) {
      return [
        TextButton(onPressed: onClose, child: const Text('关闭')),
        if (onRetry != null)
          ElevatedButton(onPressed: onRetry, child: const Text('重试')),
      ];
    }

    final actions = <Widget>[
      TextButton(onPressed: onClose, child: const Text('关闭')),
    ];

    if (onShare != null) {
      actions.insert(
        0,
        TextButton(onPressed: onShare, child: const Text('分享')),
      );
    }

    return actions;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('路径已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
