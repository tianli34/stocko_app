import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/auto_backup_settings.dart';
import '../../data/services/auto_backup_scheduler.dart';
import '../../data/services/backup_service.dart';
import '../../../../core/database/database.dart';

part 'auto_backup_controller.g.dart';

/// 自动备份调度器提供者
@riverpod
AutoBackupScheduler autoBackupScheduler(AutoBackupSchedulerRef ref) {
  final database = ref.watch(appDatabaseProvider);
  final backupService = BackupService(database);
  return AutoBackupScheduler(backupService);
}

/// 自动备份设置状态
@riverpod
class AutoBackupController extends _$AutoBackupController {
  AutoBackupScheduler? _scheduler;

  @override
  Future<AutoBackupSettings> build() async {
    _scheduler = ref.read(autoBackupSchedulerProvider);
    await _scheduler!.initialize();
    return _scheduler!.currentSettings;
  }

  /// 更新自动备份设置
  Future<void> updateSettings(AutoBackupSettings settings) async {
    if (_scheduler == null) return;
    
    state = const AsyncValue.loading();
    
    try {
      await _scheduler!.updateSettings(settings);
      state = AsyncValue.data(settings);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// 启用/禁用自动备份
  Future<void> toggleAutoBackup(bool enabled) async {
    final currentSettings = await future;
    final newSettings = currentSettings.copyWith(enabled: enabled);
    await updateSettings(newSettings);
  }

  /// 设置备份频率
  Future<void> setBackupFrequency(BackupFrequency frequency) async {
    final currentSettings = await future;
    final newSettings = currentSettings.copyWith(frequency: frequency);
    await updateSettings(newSettings);
  }

  /// 设置最大备份数量
  Future<void> setMaxBackupCount(int count) async {
    final currentSettings = await future;
    final newSettings = currentSettings.copyWith(maxBackupCount: count);
    await updateSettings(newSettings);
  }

  /// 设置WiFi限制
  Future<void> setWifiOnly(bool wifiOnly) async {
    final currentSettings = await future;
    final newSettings = currentSettings.copyWith(wifiOnly: wifiOnly);
    await updateSettings(newSettings);
  }

  /// 设置充电限制
  Future<void> setChargingOnly(bool chargingOnly) async {
    final currentSettings = await future;
    final newSettings = currentSettings.copyWith(chargingOnly: chargingOnly);
    await updateSettings(newSettings);
  }

  /// 设置备份选项
  Future<void> setBackupOptions(AutoBackupOptions options) async {
    final currentSettings = await future;
    final newSettings = currentSettings.copyWith(backupOptions: options);
    await updateSettings(newSettings);
  }

  /// 手动触发备份
  Future<String> triggerManualBackup() async {
    if (_scheduler == null) {
      return '调度器未初始化';
    }
    
    try {
      final result = await _scheduler!.triggerManualBackup();
      if (result.success) {
        // 刷新状态
        ref.invalidateSelf();
        return '手动备份成功';
      } else {
        return result.errorMessage ?? '手动备份失败';
      }
    } catch (e) {
      return '手动备份异常: $e';
    }
  }

  /// 获取下次备份时间描述
  String getNextBackupDescription() {
    return _scheduler?.getNextBackupDescription() ?? '未知';
  }
}

/// 自动备份状态提供者
@riverpod
class AutoBackupStatus extends _$AutoBackupStatus {
  @override
  String build() {
    final controller = ref.watch(autoBackupControllerProvider);
    return controller.when(
      data: (settings) {
        final scheduler = ref.read(autoBackupSchedulerProvider);
        return scheduler.getNextBackupDescription();
      },
      loading: () => '加载中...',
      error: (_, __) => '获取状态失败',
    );
  }

  /// 刷新状态
  void refresh() {
    ref.invalidateSelf();
  }
}