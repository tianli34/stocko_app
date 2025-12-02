import 'package:flutter/material.dart';

class SaleActionButtons extends StatelessWidget {
  final VoidCallback onAddProduct;
  final VoidCallback onScanProduct;
  final VoidCallback onContinuousScan;

  const SaleActionButtons({
    super.key,
    required this.onAddProduct,
    required this.onScanProduct,
    required this.onContinuousScan,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onAddProduct,
              icon: const Icon(Icons.add, size: 18),
              label: Text('添加货品', style: textTheme.bodyMedium),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onScanProduct,
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: Text('扫码添加', style: textTheme.bodyMedium),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onContinuousScan,
              icon: const Icon(Icons.qr_code_scanner, size: 18),
              label: Text('连续扫码', style: textTheme.bodyMedium),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
