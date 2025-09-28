import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auto_backup_scheduler.dart';
import 'backup_notification_service.dart';
import 'backup_service.dart';
import '../../../../core/database/database.dart';

/// 备份功能初始化服务
class BackupInitializationService {
  static AutoBackupScheduler? _scheduler;
  static bool _isInitialized = false;

  /// 初始化备份功能
  static Future<void> initialize(AppDatabase database) async {
    if (_isInitialized) {
      return;
    }

    try {
      debugPrint('正在初始化备份功能...');

      // 初始化通知服务
      await BackupNotificationService.initialize();

      // 创建备份服务
      final backupService = BackupService(database);

      // 创建并初始化自动备份调度器
      _scheduler = AutoBackupScheduler(backupService);
      await _scheduler!.initialize();

      _isInitialized = true;
      debugPrint('备份功能初始化完成');

    } catch (e, stackTrace) {
      debugPrint('备份功能初始化失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
    }
  }

  /// 获取自动备份调度器实例
  static AutoBackupScheduler? get scheduler => _scheduler;

  /// 检查是否已初始化
  static bool get isInitialized => _isInitialized;

  /// 清理资源
  static void dispose() {
    _scheduler?.dispose();
    _scheduler = null;
    _isInitialized = false;
    debugPrint('备份功能已清理');
  }
}

/// 备份初始化提供者
final backupInitializationProvider = Provider<BackupInitializationService>((ref) {
  return BackupInitializationService();
});