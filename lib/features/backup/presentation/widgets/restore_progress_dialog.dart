import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/restore_controller.dart';
import '../../domain/models/restore_result.dart';

/// 恢复进度对话框
class RestoreProgressDialog extends ConsumerWidget {
  final VoidCallback? onClose;
  final VoidCallback? onRetry;

  const RestoreProgressDialog({
    super.key,
    this.onClose,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(restoreControllerProvider);
    final progressInfo = state.progressInfo;
    final restoreResult = state.restoreResult;

    if (progressInfo == null) {
      return const SizedBox.shrink();
    }

    return PopScope(
      canPop: progressInfo.isCompleted || progressInfo.isCancelled,
      child: AlertDialog(
        title: _buildTitle(context, progressInfo, state.errorMessage, restoreResult),
        content: _buildContent(context, progressInfo, state.errorMessage, restoreResult),
        actions: _buildActions(context, ref, progressInfo, state.errorMessage),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, RestoreProgressInfo progressInfo, 
                    String? errorMessage, RestoreResult? restoreResult) {
    IconData iconData;
    Color iconColor;
    String titleText;

    if (progressInfo.isCancelled) {
      iconData = Icons.cancel;
      iconColor = Theme.of(context).colorScheme.error;
      titleText = '恢复已取消';
    } else if (errorMessage != null || (restoreResult != null && !restoreResult.success)) {
      iconData = Icons.error;
      iconColor = Theme.of(context).colorScheme.error;
      titleText = '恢复失败';
    } else if (progressInfo.isCompleted && restoreResult != null && restoreResult.success) {
      iconData = Icons.check_circle;
      iconColor = Theme.of(context).colorScheme.primary;
      titleText = '恢复完成';
    } else {
      iconData = Icons.restore;
      iconColor = Theme.of(context).colorScheme.primary;
      titleText = '正在恢复数据';
    }

    return Row(
      children: [
        Icon(iconData, color: iconColor),
        const SizedBox(width: 12),
        Text(titleText),
      ],
    );
  }

  Widget _buildContent(BuildContext context, RestoreProgressInfo progressInfo,
                      String? errorMessage, RestoreResult? restoreResult) {
    if (errorMessage != null || (restoreResult != null && !restoreResult.success)) {
      return _buildErrorContent(context, errorMessage ?? restoreResult!.errorMessage!);
    } else if (progressInfo.isCompleted && restoreResult != null && restoreResult.success) {
      return _buildSuccessContent(context, restoreResult);
    } else if (progressInfo.isCancelled) {
      return _buildCancelledContent(context);
    } else {
      return _buildProgressContent(context, progressInfo);
    }
  }

  Widget _buildProgressContent(BuildContext context, RestoreProgressInfo progressInfo) {
    final progress = progressInfo.total > 0 
        ? progressInfo.current / progressInfo.total 
        : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 进度条
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        
        // 进度文本
        Text(
          '${(progress * 100).toInt()}% (${progressInfo.current}/${progressInfo.total})',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        // 当前操作描述
        Text(
          progressInfo.message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 提示信息
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '请勿关闭应用或切换到其他页面',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessContent(BuildContext context, RestoreResult result) {
    final duration = result.endTime.difference(result.startTime);
    final durationText = duration.inMinutes > 0
        ? '${duration.inMinutes}分${duration.inSeconds % 60}秒'
        : '${duration.inSeconds}秒';

    return Column(
      mainAxisSize: MainAxisSize.min,
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
                      '数据恢复成功！',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '数据已自动刷新，无需重启应用',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(context, '总记录数', result.totalRecordsRestored.toString()),
              _buildInfoRow(context, '耗时', durationText),
              _buildInfoRow(context, '开始时间', _formatDateTime(result.startTime)),
              _buildInfoRow(context, '结束时间', _formatDateTime(result.endTime)),
              if (result.tableRecordCounts.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildTableCounts(context, result.tableRecordCounts),
              ],
            ],
          ),
        ),
        if (result.warnings.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildWarnings(context, result.warnings),
        ],
      ],
    );
  }

  // 移除 _buildResultSummary 方法，其内容已整合进 _buildSuccessContent

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
          ...warnings.map((warning) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• $warning',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context, String errorMessage) {
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
                  '恢复过程中发生错误',
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
            errorMessage,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cancel,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '恢复操作已取消',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '已恢复的数据将保留，您可以稍后重新开始',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context, WidgetRef ref,
                            RestoreProgressInfo progressInfo, String? errorMessage) {
    if (errorMessage != null) {
      return [
        TextButton(
          onPressed: onClose,
          child: const Text('关闭'),
        ),
        if (onRetry != null)
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('重试'),
          ),
      ];
    } else if (progressInfo.isCompleted) {
      return [
        ElevatedButton(
          onPressed: onClose,
          child: const Text('完成'),
        ),
      ];
    } else if (progressInfo.isCancelled) {
      return [
        ElevatedButton(
          onPressed: onClose,
          child: const Text('完成'),
        ),
      ];
    } else {
      return [
        TextButton(
          onPressed: () => _showCancelConfirmation(context, ref),
          child: const Text('取消'),
        ),
      ];
    }
  }

  void _showCancelConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认取消'),
        content: const Text('确定要取消恢复操作吗？\n\n已恢复的数据将保留，但恢复过程将中断。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('继续恢复'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // 关闭确认对话框
              ref.read(restoreControllerProvider.notifier).cancelRestore();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('确认取消'),
          ),
        ],
      ),
    );
  }

  // 新增方法：格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // 新增方法：构建信息行（与 OperationResultDialog 一致）
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

  // 新增方法：构建表记录统计（与 OperationResultDialog 一致）
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
          ...tableCounts.entries.map((entry) => Padding(
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
          )),
        ],
      ),
    );
  }

  // 新增方法：获取表名显示名称（与 OperationResultDialog 一致）
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