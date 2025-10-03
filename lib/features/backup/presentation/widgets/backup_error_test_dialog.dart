import 'package:flutter/material.dart';

import '../../domain/models/backup_exception.dart';
import '../../domain/models/backup_error_type.dart';
import '../../data/services/backup_error_handler.dart';
import 'enhanced_error_dialog.dart';

/// 备份错误测试对话框 - 用于测试不同类型的错误显示
class BackupErrorTestDialog extends StatelessWidget {
  const BackupErrorTestDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const BackupErrorTestDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('测试错误处理'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildErrorTestButton(
              context,
              '存储空间不足',
              BackupException.insufficientSpace('设备存储空间不足，需要至少100MB可用空间'),
            ),
            _buildErrorTestButton(
              context,
              '权限被拒绝',
              BackupException.permissionDenied('应用没有存储权限，无法创建备份文件'),
            ),
            _buildErrorTestButton(
              context,
              '数据库错误',
              BackupException.database('数据库连接失败，可能被其他进程占用'),
            ),
            _buildErrorTestButton(
              context,
              '文件系统错误',
              BackupException.fileSystem('无法访问备份目录，请检查存储设备状态'),
            ),
            _buildErrorTestButton(
              context,
              '网络连接错误',
              BackupException(
                type: BackupErrorType.networkError,
                message: '网络连接不稳定，无法上传备份文件',
              ),
            ),
            _buildErrorTestButton(
              context,
              '加密错误',
              BackupException.encryption('备份文件加密失败，请检查密码设置'),
            ),
            _buildErrorTestButton(
              context,
              '压缩错误',
              BackupException(
                type: BackupErrorType.compressionError,
                message: '备份文件压缩失败，可能是文件过大或存储空间不足',
              ),
            ),
            _buildErrorTestButton(
              context,
              '未知错误',
              BackupException(
                type: BackupErrorType.unknown,
                message: '发生了未知错误，请稍后重试或联系技术支持',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _buildErrorTestButton(
    BuildContext context,
    String title,
    BackupException exception,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: () => _showTestError(context, exception),
        child: Text(title),
      ),
    );
  }

  void _showTestError(BuildContext context, BackupException exception) {
    Navigator.of(context).pop(); // 关闭测试对话框
    
    final userError = BackupErrorHandler.handleError(exception);
    
    EnhancedErrorDialog.show(
      context,
      error: userError,
      onRetry: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('这是测试错误，重试功能已模拟执行'),
          ),
        );
      },
    );
  }
}