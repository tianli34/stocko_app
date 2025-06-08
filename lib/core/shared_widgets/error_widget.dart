import 'package:flutter/material.dart';

class CustomErrorWidget extends StatelessWidget {
  final String? title;
  final String message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String? retryText;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionText;
  final bool showIcon;

  const CustomErrorWidget({
    Key? key,
    this.title,
    required this.message,
    this.icon,
    this.onRetry,
    this.retryText,
    this.onSecondaryAction,
    this.secondaryActionText,
    this.showIcon = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(
                icon ?? Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
            ],
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onRetry != null) ...[
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(retryText ?? '重试'),
                  ),
                  if (onSecondaryAction != null) const SizedBox(width: 12),
                ],
                if (onSecondaryAction != null)
                  OutlinedButton(
                    onPressed: onSecondaryAction,
                    child: Text(secondaryActionText ?? '其他操作'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customMessage;

  const NetworkErrorWidget({Key? key, this.onRetry, this.customMessage})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      title: '网络连接错误',
      message: customMessage ?? '请检查您的网络连接并重试',
      icon: Icons.wifi_off,
      onRetry: onRetry,
      retryText: '重新加载',
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String? title;
  final String message;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionText;

  const EmptyStateWidget({
    Key? key,
    this.title,
    required this.message,
    this.icon,
    this.onAction,
    this.actionText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      title: title ?? '暂无数据',
      message: message,
      icon: icon ?? Icons.inbox_outlined,
      onRetry: onAction,
      retryText: actionText ?? '刷新',
      showIcon: true,
    );
  }
}
