import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/services/backup_error_handler.dart';

/// 备份错误显示组件
class BackupErrorWidget extends StatelessWidget {
  final UserFriendlyError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool showTechnicalDetails;
  final bool showSuggestions;

  const BackupErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
    this.showTechnicalDetails = false,
    this.showSuggestions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 错误标题和图标
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    error.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onDismiss,
                    iconSize: 20,
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 错误消息
            Text(
              error.message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            // 技术详情（可展开）
            if (showTechnicalDetails && error.technicalDetails != null) ...[
              const SizedBox(height: 16),
              _TechnicalDetailsSection(
                details: error.technicalDetails!,
              ),
            ],
            
            // 解决建议
            if (showSuggestions && error.suggestion != null) ...[
              const SizedBox(height: 16),
              _SuggestionSection(
                suggestion: error.suggestion!,
              ),
            ],
            
            // 操作按钮
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (error.canRetry && onRetry != null) ...[
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('重试'),
                  ),
                  const SizedBox(width: 8),
                ],
                TextButton(
                  onPressed: onDismiss ?? () => Navigator.of(context).pop(),
                  child: const Text('确定'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 技术详情展开组件
class _TechnicalDetailsSection extends StatefulWidget {
  final String details;

  const _TechnicalDetailsSection({
    required this.details,
  });

  @override
  State<_TechnicalDetailsSection> createState() => _TechnicalDetailsSectionState();
}

class _TechnicalDetailsSectionState extends State<_TechnicalDetailsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '技术详情',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        if (_expanded) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.details,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16),
                      onPressed: () => _copyToClipboard(context),
                      tooltip: '复制到剪贴板',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.details));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('技术详情已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// 解决建议组件
class _SuggestionSection extends StatelessWidget {
  final ErrorRecoverySuggestion suggestion;

  const _SuggestionSection({
    required this.suggestion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                suggestion.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            suggestion.description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          
          const SizedBox(height: 8),
          
          ...suggestion.steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// 错误对话框
class BackupErrorDialog extends StatelessWidget {
  final UserFriendlyError error;
  final VoidCallback? onRetry;
  final bool showTechnicalDetails;

  const BackupErrorDialog({
    super.key,
    required this.error,
    this.onRetry,
    this.showTechnicalDetails = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required UserFriendlyError error,
    VoidCallback? onRetry,
    bool showTechnicalDetails = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackupErrorDialog(
        error: error,
        onRetry: onRetry,
        showTechnicalDetails: showTechnicalDetails,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: BackupErrorWidget(
        error: error,
        onRetry: onRetry != null ? () {
          Navigator.of(context).pop(true);
          onRetry!();
        } : null,
        onDismiss: () => Navigator.of(context).pop(false),
        showTechnicalDetails: showTechnicalDetails,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}

/// 简化的错误提示条
class BackupErrorSnackBar extends SnackBar {
  BackupErrorSnackBar({
    super.key,
    required UserFriendlyError error,
    VoidCallback? onRetry,
  }) : super(
          content: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  error.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[700],
          action: error.canRetry && onRetry != null
              ? SnackBarAction(
                  label: '重试',
                  textColor: Colors.white,
                  onPressed: onRetry,
                )
              : null,
          duration: const Duration(seconds: 4),
        );

  static void show(
    BuildContext context, {
    required UserFriendlyError error,
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      BackupErrorSnackBar(
        error: error,
        onRetry: onRetry,
      ),
    );
  }
}