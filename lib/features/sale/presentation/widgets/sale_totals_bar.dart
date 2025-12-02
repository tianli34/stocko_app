import 'package:flutter/material.dart';

class SaleTotalsBar extends StatelessWidget {
  final int totalVarieties;
  final int totalQuantity;
  final double totalAmount;

  const SaleTotalsBar({
    super.key,
    required this.totalVarieties,
    required this.totalQuantity,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
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
          _buildTotalItem(
            context,
            textTheme,
            '总金额',
            '¥${totalAmount.toStringAsFixed(1)}',
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
    return RichText(
      text: TextSpan(
        style: textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isAmount
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
