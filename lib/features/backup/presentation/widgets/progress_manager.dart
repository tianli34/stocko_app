import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/backup_controller.dart';
import '../controllers/restore_controller.dart';
import 'backup_progress_dialog.dart';
import 'restore_progress_dialog.dart';
import 'operation_result_dialog.dart';
import 'enhanced_error_dialog.dart';
import '../../data/services/backup_error_handler.dart';

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
    // 只有在开始恢复时才显示对话框，避免在恢复完成时重复显示
    if (current.progressInfo != null && 
        !current.progressInfo!.isCompleted && 
        !current.progressInfo!.isCancelled) {
      // 检查是否已经显示了对话框
      bool isDialogAlreadyShown = false;
      if (previous?.progressInfo != null && 
          !previous!.progressInfo!.isCompleted && 
          !previous!.progressInfo!.isCancelled) {
        isDialogAlreadyShown = true;
      }
      
      if (!isDialogAlreadyShown) {
        _showRestoreProgressDialog(context, ref);
      }
    }

    // 处理恢复完成的情况
    // 当恢复完成时，不需要额外操作，因为用户会点击"完成"按钮关闭对话框
    if (previous?.progressInfo?.isCompleted != true &&
        current.progressInfo?.isCompleted == true) {
      
      // 不需要额外操作，RestoreProgressDialog 会自动更新显示完成状态
      // 用户点击"完成"按钮后会关闭对话框
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
          // 确保完全关闭所有对话框
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
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
    
    if (!isSuccess && state.errorMessage != null) {
      // 显示增强的错误对话框
      final userError = UserFriendlyError(
        title: '备份失败',
        message: state.errorMessage!,
        canRetry: true,
      );
      
      EnhancedErrorDialog.show(
        context,
        error: userError,
        onRetry: () {
          ref.read(backupControllerProvider.notifier).retryBackup();
        },
      ).then((_) {
        ref.read(backupControllerProvider.notifier).reset();
      });
    } else {
      // 显示成功结果对话框
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
  }

  void _showRestoreResultDialog(
    BuildContext context,
    WidgetRef ref,
    RestoreState state,
  ) {
    // 已由 RestoreProgressDialog 自动处理，无需额外弹窗
    // 保留此方法以避免编译错误，但不执行任何操作
  }

  void _shareBackupFile(BuildContext context, String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('备份文件不存在')),
        );
        return;
      }
      
      // 使用 share_plus 分享文件
      await Share.shareXFiles(
        [XFile(filePath)],
        text: '库存数据备份文件',
        subject: '库存数据备份',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分享失败: ${e.toString()}')),
      );
    }
  }
}