import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../../domain/services/i_backup_service.dart';
import '../services/backup_service.dart';

/// 备份服务提供者
final backupServiceProvider = Provider<IBackupService>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return BackupService(database);
});

/// 本地备份列表提供者
final localBackupsProvider = FutureProvider((ref) async {
  final backupService = ref.watch(backupServiceProvider);
  return await backupService.getLocalBackups();
});

/// 备份大小估算提供者
final backupSizeEstimateProvider = FutureProvider<int>((ref) async {
  final backupService = ref.watch(backupServiceProvider);
  return await backupService.estimateBackupSize();
});