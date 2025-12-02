import 'package:flutter/material.dart';

/// 入库页面统计栏组件 - 显示品种数、总数量、总金额
class CreateInboundTotalsBar extends StatelessWidget {
  final int totalVarieties;
  final int totalQuantity;
  final double totalAmount;
  final bool showAmount;

  const CreateInboundTotalsBar({
    super.key,
    required this.totalVarieties,
    required this.totalQuantity,
    required this.totalAmount,
    this.showAmount = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTotalItem(context, textTheme, '品种', totalVarieties.toString()),
          _buildTotalItem(context, textTheme, '总数', totalQuantity.toString()),
          if (showAmount)
            _buildTotalItem(
              context,
              textTheme,
              '总金额',
              '¥${totalAmount.toStringAsFixed(2)}',
              isAmount: true,
            ),
        ],
      ),
    );
  }

  Widget _buildTotalItem(
    BuildContext context,
    TextTheme textTheme,
    String label,
    String value, {
    bool isAmount = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return RichText(
      text: TextSpan(
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isAmount ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
