import 'package:flutter/material.dart';

/// 备份进度信息
class BackupProgressInfo {
  final String message;
  final int current;
  final int total;
  final bool isCompleted;
  final bool isCancelled;
  final String? errorMessage;

  const BackupProgressInfo({
    required this.message,
    required this.current,
    required this.total,
    this.isCompleted = false,
    this.isCancelled = false,
    this.errorMessage,
  });

  BackupProgressInfo copyWith({
    String? message,
    int? current,
    int? total,
    bool? isCompleted,
    bool? isCancelled,
    String? errorMessage,
  }) {
    return BackupProgressInfo(
      message: message ?? this.message,
      current: current ?? this.current,
      total: total ?? this.total,
      isCompleted: isCompleted ?? this.isCompleted,
      isCancelled: isCancelled ?? this.isCancelled,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  double get progress => total > 0 ? current / total : 0.0;
  int get progressPercent => (progress * 100).toInt();
}

/// 备份进度对话框
class BackupProgressDialog extends StatelessWidget {
  final BackupProgressInfo progressInfo;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;
  final VoidCallback? onClose;

  const BackupProgressDialog({
    super.key,
    required this.progressInfo,
    this.onCancel,
    this.onRetry,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: progressInfo.isCompleted || progressInfo.isCancelled,
      child: AlertDialog(
        title: _buildTitle(context),
        content: _buildContent(context),
        actions: _buildActions(context),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    IconData iconData;
    Color iconColor;
    String titleText;

    if (progressInfo.isCancelled) {
      iconData = Icons.cancel;
      iconColor = Theme.of(context).colorScheme.error;
      titleText = '备份已取消';
    } else if (progressInfo.errorMessage != null) {
      iconData = Icons.error;
      iconColor = Theme.of(context).colorScheme.error;
      titleText = '备份失败';
    } else if (progressInfo.isCompleted) {
      iconData = Icons.check_circle;
      iconColor = Theme.of(context).colorScheme.primary;
      titleText = '备份完成';
    } else {
      iconData = Icons.backup;
      iconColor = Theme.of(context).colorScheme.primary;
      titleText = '正在备份数据';
    }

    return Row(
      children: [
        Icon(iconData, color: iconColor),
        const SizedBox(width: 12),
        Text(titleText),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (progressInfo.errorMessage != null) ...[
          _buildErrorContent(context),
        ] else if (progressInfo.isCompleted && !progressInfo.isCancelled) ...[
          _buildSuccessContent(context),
        ] else if (progressInfo.isCancelled) ...[
          _buildCancelledContent(context),
        ] else ...[
          _buildProgressContent(context),
        ],
      ],
    );
  }

  Widget _buildProgressContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 进度条
        LinearProgressIndicator(
          value: progressInfo.progress,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        
        // 进度文本
        Text(
          '${progressInfo.progressPercent}% (${progressInfo.current}/${progressInfo.total})',
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

  Widget _buildSuccessContent(BuildContext context) {
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
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '备份创建成功！',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '数据已安全备份到本地存储',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
                      '备份过程中发生错误',
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
                progressInfo.errorMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCancelledContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
                      '备份操作已取消',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '您可以稍后重新开始备份',
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
      ],
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    if (progressInfo.errorMessage != null) {
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
    } else if (progressInfo.isCompleted || progressInfo.isCancelled) {
      return [
        ElevatedButton(
          onPressed: onClose,
          child: const Text('完成'),
        ),
      ];
    } else {
      return [
        TextButton(
          onPressed: () => _showCancelConfirmation(context),
          child: const Text('取消'),
        ),
      ];
    }
  }

  void _showCancelConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认取消'),
        content: const Text('确定要取消备份操作吗？\n\n当前进度将丢失，需要重新开始。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('继续备份'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // 关闭确认对话框
              onCancel?.call();
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
}