import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/backup_error_service.dart';
import '../services/backup_error_handler.dart';

part 'backup_error_service_provider.g.dart';

/// 备份错误服务提供者
@Riverpod(keepAlive: true)
BackupErrorService backupErrorService(Ref ref) {
  final service = BackupErrorService.instance;

  // 确保服务在应用启动时初始化
  service.initialize();

  // 在应用关闭时清理服务
  ref.onDispose(() {
    service.cleanup();
  });

  return service;
}

/// 错误流提供者
@riverpod
Stream<UserFriendlyError> backupErrorStream(Ref ref) {
  final errorService = ref.watch(backupErrorServiceProvider);
  return errorService.errorStream;
}

/// 错误统计提供者
@riverpod
Future<Map<String, dynamic>> backupErrorStats(
  Ref ref, {
  Duration? period,
}) async {
  final errorService = ref.watch(backupErrorServiceProvider);
  return await errorService.getErrorStats(period: period);
}
