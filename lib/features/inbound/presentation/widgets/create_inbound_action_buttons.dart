import 'package:flutter/material.dart';

/// 入库页面操作按钮组件 - 添加货品、扫码添加、连续扫码
class CreateInboundActionButtons extends StatelessWidget {
  final VoidCallback onAddManual;
  final VoidCallback onScanSingle;
  final VoidCallback onScanContinuous;

  const CreateInboundActionButtons({
    super.key,
    required this.onAddManual,
    required this.onScanSingle,
    required this.onScanContinuous,
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
            onPressed: onAddManual,
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
            onPressed: onScanSingle,
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
            onPressed: onScanContinuous,
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
