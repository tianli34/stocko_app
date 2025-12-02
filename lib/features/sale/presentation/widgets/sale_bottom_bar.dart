import 'package:flutter/material.dart';

class SaleBottomBar extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback? onCreditSale;
  final VoidCallback? onConfirmSale;

  const SaleBottomBar({
    super.key,
    required this.isProcessing,
    required this.onCreditSale,
    required this.onConfirmSale,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: isProcessing ? null : onCreditSale,
            icon: isProcessing
                ? const SizedBox(
                    width: 12,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.account_balance_wallet_outlined, size: 24),
            label: Text(
              isProcessing ? '正在处理...' : '赊账',
              style: textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: theme.colorScheme.onSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            onPressed: isProcessing ? null : onConfirmSale,
            icon: isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline, size: 24),
            label: Text(
              isProcessing ? '正在处理...' : '结账',
              style: textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
