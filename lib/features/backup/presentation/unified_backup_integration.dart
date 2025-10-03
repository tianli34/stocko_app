import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/unified_backup_service.dart';
import '../data/providers/backup_service_provider.dart';
import '../domain/models/backup_options.dart';
import '../domain/common/backup_common.dart';
import '../domain/models/backup_metadata.dart';

/// 统一备份服务集成示例
class UnifiedBackupIntegration {
  /// 使用 Riverpod 获取统一备份服务实例
  static UnifiedBackupService getService(WidgetRef ref) {
    return ref.read(backupServiceProvider) as UnifiedBackupService;
  }
  
  /// 创建备份的完整流程
  static Future<void> createBackupWithErrorHandling({
    required BuildContext context,
    required WidgetRef ref,
    BackupOptions? options,
    VoidCallback? onSuccess,
    Function(String)? onError,
  }) async {
    final backupService = getService(ref);
    final cancelToken = CancelToken();
    
    // 显示进度对话框
    final progressKey = GlobalKey<_BackupProgressDialogState>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackupProgressDialog(
        key: progressKey,
        onCancel: () {
          cancelToken.cancel();
          Navigator.of(context).pop();
        },
      ),
    );
    
    try {
      final result = await backupService.createBackup(
        options: options ?? const BackupOptions(
          description: '统一备份服务自动备份',
        ),
        onProgress: (message, current, total) {
          progressKey.currentState?.updateProgress(message, current, total);
        },
        cancelToken: cancelToken,
      );
      
      // 关闭进度对话框
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      if (result.success) {
        if (context.mounted) {
          _showSuccessDialog(context, result.filePath!, result.metadata);
        }
        onSuccess?.call();
      } else {
        if (context.mounted) {
          _showErrorDialog(context, result.errorMessage!);
        }
        onError?.call(result.errorMessage!);
      }
      
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        _showErrorDialog(context, '备份过程中发生异常: ${e.toString()}');
      }
      onError?.call(e.toString());
    }
  }
  
  /// 使用 Consumer Widget 的集成示例
  static Widget buildBackupButton({
    required String label,
    BackupOptions? options,
    VoidCallback? onSuccess,
    Function(String)? onError,
  }) {
    return Consumer(
      builder: (context, ref, child) {
        return ElevatedButton(
          onPressed: () => createBackupWithErrorHandling(
            context: context,
            ref: ref,
            options: options,
            onSuccess: onSuccess,
            onError: onError,
          ),
          child: Text(label),
        );
      },
    );
  }
  
  static void _showSuccessDialog(BuildContext context, String filePath, BackupMetadata? metadata) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('备份成功'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('备份文件已保存到：'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                filePath,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
            if (metadata != null) ...[
              const SizedBox(height: 16),
              Text('备份信息：'),
              const SizedBox(height: 4),
              Text('文件大小：${(metadata.fileSize / 1024 / 1024).toStringAsFixed(2)} MB'),
              Text('创建时间：${metadata.createdAt.toString().split('.')[0]}'),
              if (metadata.description?.isNotEmpty == true)
                Text('描述：${metadata.description}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  static void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('备份失败'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('备份过程中发生错误：'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                error,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '建议操作：\n1. 检查存储空间是否足够\n2. 确保数据库没有被其他进程占用\n3. 稍后重试',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

/// 备份进度对话框
class BackupProgressDialog extends StatefulWidget {
  final VoidCallback? onCancel;
  
  const BackupProgressDialog({
    super.key,
    this.onCancel,
  });
  
  @override
  State<BackupProgressDialog> createState() => _BackupProgressDialogState();
}

class _BackupProgressDialogState extends State<BackupProgressDialog> {
  String _currentMessage = '准备备份...';
  double _progress = 0.0;
  
  void updateProgress(String message, int current, int total) {
    if (mounted) {
      setState(() {
        _currentMessage = message;
        _progress = total > 0 ? current / total : 0.0;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 禁止返回键关闭
      child: AlertDialog(
        title: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('正在创建备份'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 16),
            Text(
              _currentMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_progress * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          if (widget.onCancel != null)
            TextButton(
              onPressed: widget.onCancel,
              child: const Text('取消'),
            ),
        ],
      ),
    );
  }
}