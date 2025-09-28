import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/backup_controller.dart';
import '../controllers/restore_controller.dart';
import 'backup_progress_dialog.dart';
import 'restore_progress_dialog.dart';
import 'operation_result_dialog.dart';

/// 进度管理器 - 统一管理备份和恢复的进度显示
class ProgressManager extends ConsumerWidget {
  final Widget child;

  const ProgressManager({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听备份状态
    ref.listen<BackupState>(backupControllerProvider, (previous, current) {
      _handleBackupStateChange(context, ref, previous, current);
    });

    // 监听恢复状态
    ref.listen<RestoreState>(restoreControllerProvider, (previous, current) {
      _handleRestoreStateChange(context, ref, previous, current);
    });

    return child;
  }

  void _handleBackupStateChange(
    BuildContext context,
    WidgetRef ref,
    BackupState? previous,
    BackupState current,
  ) {
    // 显示备份进度对话框
    if (current.isBackingUp && current.progressInfo != null) {
      if (previous?.progressInfo == null) {
        _showBackupProgressDialog(context, ref);
      }
    }

    // 显示备份结果
    if (previous?.isBackingUp == true && 
        !current.isBackingUp && 
        current.progressInfo?.isCompleted == true) {
      
      // 延迟一下再显示结果，让进度对话框有时间更新
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          Navigator.of(context).pop(); // 关闭进度对话框
          _showBackupResultDialog(context, ref, current);
        }
      });
    }
  }

  void _handleRestoreStateChange(
    BuildContext context,
    WidgetRef ref,
    RestoreState? previous,
    RestoreState current,
  ) {
    // 显示恢复进度对话框
    if (current.progressInfo != null && !current.progressInfo!.isCompleted) {
      if (previous?.progressInfo == null) {
        _showRestoreProgressDialog(context, ref);
      }
    }

    // 显示恢复结果
    if (previous?.progressInfo?.isCompleted != true && 
        current.progressInfo?.isCompleted == true) {
      
      // 延迟一下再显示结果，让进度对话框有时间更新
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          Navigator.of(context).pop(); // 关闭进度对话框
          _showRestoreResultDialog(context, ref, current);
        }
      });
    }
  }

  void _showBackupProgressDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(backupControllerProvider);
          final progressInfo = state.progressInfo;

          if (progressInfo == null) {
            return const SizedBox.shrink();
          }

          return BackupProgressDialog(
            progressInfo: progressInfo,
            onCancel: () {
              ref.read(backupControllerProvider.notifier).cancelBackup();
            },
            onRetry: () {
              Navigator.of(context).pop();
              ref.read(backupControllerProvider.notifier).retryBackup();
            },
            onClose: () {
              Navigator.of(context).pop();
              ref.read(backupControllerProvider.notifier).reset();
            },
          );
        },
      ),
    );
  }

  void _showRestoreProgressDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RestoreProgressDialog(
        onClose: () {
          Navigator.of(context).pop();
          ref.read(restoreControllerProvider.notifier).reset();
        },
        onRetry: () {
          Navigator.of(context).pop();
          ref.read(restoreControllerProvider.notifier).startRestore();
        },
      ),
    );
  }

  void _showBackupResultDialog(
    BuildContext context,
    WidgetRef ref,
    BackupState state,
  ) {
    final isSuccess = state.resultMetadata != null && state.errorMessage == null;
    
    showDialog(
      context: context,
      builder: (context) => OperationResultDialog.backup(
        isSuccess: isSuccess,
        errorMessage: state.errorMessage,
        metadata: state.resultMetadata,
        filePath: state.resultFilePath,
        onClose: () {
          Navigator.of(context).pop();
          ref.read(backupControllerProvider.notifier).reset();
        },
        onRetry: () {
          Navigator.of(context).pop();
          ref.read(backupControllerProvider.notifier).retryBackup();
        },
        onShare: state.resultFilePath != null ? () {
          Navigator.of(context).pop();
          _shareBackupFile(context, state.resultFilePath!);
        } : null,
      ),
    );
  }

  void _showRestoreResultDialog(
    BuildContext context,
    WidgetRef ref,
    RestoreState state,
  ) {
    final isSuccess = state.restoreResult?.success == true && state.errorMessage == null;
    
    showDialog(
      context: context,
      builder: (context) => OperationResultDialog.restore(
        isSuccess: isSuccess,
        errorMessage: state.errorMessage ?? state.restoreResult?.errorMessage,
        result: state.restoreResult,
        onClose: () {
          Navigator.of(context).pop();
          ref.read(restoreControllerProvider.notifier).reset();
        },
        onRetry: () {
          Navigator.of(context).pop();
          ref.read(restoreControllerProvider.notifier).startRestore();
        },
      ),
    );
  }

  void _shareBackupFile(BuildContext context, String filePath) {
    // TODO: 实现文件分享功能
    // 可以使用 share_plus 包来实现文件分享
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('备份文件路径: $filePath'),
        action: SnackBarAction(
          label: '复制',
          onPressed: () {
            // TODO: 复制到剪贴板
          },
        ),
      ),
    );
  }
}