import 'package:flutter/material.dart';

import '../screens/create_inbound_controller.dart';

/// 入库页面底部操作栏组件 - 采购/一键入库按钮
class CreateInboundBottomBar extends StatelessWidget {
  final InboundMode currentMode;
  final bool isProcessing;
  final VoidCallback onPurchaseOnly;
  final VoidCallback onInbound;

  const CreateInboundBottomBar({
    super.key,
    required this.currentMode,
    required this.isProcessing,
    required this.onPurchaseOnly,
    required this.onInbound,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isPurchaseMode = currentMode == InboundMode.purchase;

    if (isPurchaseMode) {
      return _buildPurchaseModeButtons(theme, textTheme);
    } else {
      return _buildNonPurchaseModeButton(theme, textTheme);
    }
  }

  Widget _buildPurchaseModeButtons(ThemeData theme, TextTheme textTheme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isProcessing ? null : onPurchaseOnly,
            icon: isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.shopping_cart_checkout, size: 20),
            label: Text(
              isProcessing ? '处理中...' : '采购',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInboundButton(theme, textTheme),
        ),
      ],
    );
  }

  Widget _buildNonPurchaseModeButton(ThemeData theme, TextTheme textTheme) {
    return _buildInboundButton(theme, textTheme, fullWidth: true);
  }

  Widget _buildInboundButton(
    ThemeData theme,
    TextTheme textTheme, {
    bool fullWidth = false,
  }) {
    return ElevatedButton.icon(
      onPressed: isProcessing ? null : onInbound,
      icon: isProcessing
          ? SizedBox(
              width: fullWidth ? 24 : 20,
              height: fullWidth ? 24 : 20,
              child: CircularProgressIndicator(
                strokeWidth: fullWidth ? 3 : 2,
                color: Colors.white,
              ),
            )
          : Icon(Icons.check_circle_outline, size: fullWidth ? 24 : 20),
      label: Text(
        isProcessing ? (fullWidth ? '正在入库...' : '处理中...') : '一键入库',
        style: textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }
}
