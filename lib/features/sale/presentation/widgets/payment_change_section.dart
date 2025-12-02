import 'package:flutter/material.dart';

class PaymentChangeSection extends StatelessWidget {
  final TextEditingController paymentController;
  final FocusNode paymentFocusNode;
  final double change;

  const PaymentChangeSection({
    super.key,
    required this.paymentController,
    required this.paymentFocusNode,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('收款:', style: textTheme.titleMedium),
              const SizedBox(width: 8),
              Flexible(
                flex: 1,
                child: TextFormField(
                  focusNode: paymentFocusNode,
                  controller: paymentController,
                  decoration: const InputDecoration(
                    prefixText: '¥ ',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  style: textTheme.titleMedium,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const Spacer(flex: 1),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('找零:', style: textTheme.titleMedium),
                  const SizedBox(width: 8),
                  Text(
                    '¥ ${change.toStringAsFixed(1)}',
                    style: textTheme.titleLarge?.copyWith(
                      color: change < 0
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
