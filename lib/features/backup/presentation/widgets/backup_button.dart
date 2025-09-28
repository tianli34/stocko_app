import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/backup_options.dart';
import '../controllers/backup_controller.dart';

/// 备份按钮组件
class BackupButton extends ConsumerWidget {
  final String? customName;
  final bool showIcon;
  final String? buttonText;

  const BackupButton({
    super.key,
    this.customName,
    this.showIcon = true,
    this.buttonText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupState = ref.watch(backupControllerProvider);

    return ElevatedButton.icon(
      onPressed: backupState.isBackingUp ? null : () => _startBackup(context, ref),
      icon: showIcon 
          ? (backupState.isBackingUp 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.backup))
          : const SizedBox.shrink(),
      label: Text(
        backupState.isBackingUp 
            ? '备份中...' 
            : (buttonText ?? '创建备份'),
      ),
    );
  }

  Future<void> _startBackup(BuildContext context, WidgetRef ref) async {
    // 创建备份选项
    final options = BackupOptions(
      customName: customName,
      includeImages: false, // 暂时不包含图片
      encrypt: false, // 暂时不加密
      description: '手动创建的备份',
    );

    // 开始备份 - 进度对话框将由 ProgressManager 自动显示
    await ref.read(backupControllerProvider.notifier).startBackup(
      options: options,
    );
  }
}

/// 快速备份按钮（用于设置页面）
class QuickBackupButton extends ConsumerWidget {
  const QuickBackupButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.backup),
      title: const Text('创建数据备份'),
      subtitle: const Text('将所有数据导出到备份文件'),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () => _showBackupOptions(context, ref),
    );
  }

  void _showBackupOptions(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建备份'),
        content: const Text('确定要创建数据备份吗？这将导出所有产品、库存和交易数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startQuickBackup(context, ref);
            },
            child: const Text('开始备份'),
          ),
        ],
      ),
    );
  }

  Future<void> _startQuickBackup(BuildContext context, WidgetRef ref) async {
    final options = BackupOptions(
      description: '快速备份 - ${DateTime.now().toLocal().toString().split('.')[0]}',
    );

    // 开始备份 - 进度对话框将由 ProgressManager 自动显示
    await ref.read(backupControllerProvider.notifier).startBackup(
      options: options,
    );
  }
}