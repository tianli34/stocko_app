import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/auto_backup_settings.dart';
import '../../domain/services/i_backup_service.dart';
import '../../domain/models/backup_options.dart' as backup_models;
import 'backup_notification_service.dart';

/// 自动备份调度器
class AutoBackupScheduler {
  static const String _settingsKey = 'auto_backup_settings';

  final IBackupService _backupService;
  Timer? _schedulerTimer;
  AutoBackupSettings _currentSettings = const AutoBackupSettings();

  AutoBackupScheduler(this._backupService);

  /// 初始化调度器
  Future<void> initialize() async {
    await _loadSettings();
    await _startScheduler();
  }

  /// 获取当前自动备份设置
  AutoBackupSettings get currentSettings => _currentSettings;

  /// 更新自动备份设置
  Future<void> updateSettings(AutoBackupSettings settings) async {
    _currentSettings = settings;
    await _saveSettings();

    // 重新启动调度器
    await _startScheduler();

    // 如果启用了自动备份，计算下次备份时间
    if (settings.enabled) {
      final nextBackupTime = _calculateNextBackupTime(settings.frequency);
      final updatedSettings = settings.copyWith(nextBackupTime: nextBackupTime);
      _currentSettings = updatedSettings;
      await _saveSettings();
    }
  }

  /// 启动调度器
  Future<void> _startScheduler() async {
    // 停止现有的调度器
    _schedulerTimer?.cancel();

    if (!_currentSettings.enabled) {
      return;
    }

    // 每分钟检查一次是否需要执行备份
    _schedulerTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkAndExecuteBackup();
    });

    // 立即检查一次
    await _checkAndExecuteBackup();
  }

  /// 检查并执行备份
  Future<void> _checkAndExecuteBackup() async {
    if (!_currentSettings.enabled) {
      return;
    }

    final now = DateTime.now();

    // 检查是否到了备份时间
    if (_currentSettings.nextBackupTime != null &&
        now.isAfter(_currentSettings.nextBackupTime!)) {
      // 检查设备条件
      if (await _checkDeviceConditions()) {
        await _executeAutoBackup();
      } else {
        // 如果设备条件不满足，延迟30分钟后再检查
        final delayedTime = now.add(const Duration(minutes: 30));
        _currentSettings = _currentSettings.copyWith(
          nextBackupTime: delayedTime,
        );
        await _saveSettings();
      }
    }
  }

  /// 检查设备条件（WiFi、充电状态等）
  Future<bool> _checkDeviceConditions() async {
    // 这里可以添加更复杂的设备条件检查
    // 目前简化处理，总是返回true
    // 在实际应用中，可以检查：
    // - 网络连接状态（WiFi）
    // - 电池充电状态
    // - 存储空间
    return true;
  }

  /// 执行自动备份
  Future<void> _executeAutoBackup() async {
    try {
      debugPrint('开始执行自动备份...');

      // 创建备份选项
      final backupOptions = backup_models.BackupOptions(
        customName: 'auto_backup',
        includeImages: _currentSettings.backupOptions?.includeImages ?? false,
        encrypt: _currentSettings.backupOptions?.encrypt ?? false,
        password: _currentSettings.backupOptions?.password,
        compress: _currentSettings.backupOptions?.compress ?? false,
        description: '自动备份 - ${DateTime.now().toIso8601String()}',
      );

      // 执行备份
      final result = await _backupService.createBackup(
        options: backupOptions,
        onProgress: (message, current, total) {
          debugPrint('自动备份进度: $message ($current/$total)');
        },
      );

      if (result.success) {
        debugPrint('自动备份成功: ${result.filePath}');

        // 更新最后备份时间
        final now = DateTime.now();
        final nextBackupTime = _calculateNextBackupTime(
          _currentSettings.frequency,
        );

        _currentSettings = _currentSettings.copyWith(
          lastBackupTime: now,
          nextBackupTime: nextBackupTime,
        );
        await _saveSettings();

        // 清理过期备份
        await _cleanupOldBackups();

        // 发送通知（如果需要）
        await _sendBackupNotification(true, '自动备份完成');
      } else {
        debugPrint('自动备份失败: ${result.errorMessage}');
        await _sendBackupNotification(false, '自动备份失败: ${result.errorMessage}');

        // 备份失败，延迟1小时后重试
        final retryTime = DateTime.now().add(const Duration(hours: 1));
        _currentSettings = _currentSettings.copyWith(nextBackupTime: retryTime);
        await _saveSettings();
      }
    } catch (e) {
      debugPrint('自动备份异常: $e');
      await _sendBackupNotification(false, '自动备份异常: $e');

      // 异常情况，延迟2小时后重试
      final retryTime = DateTime.now().add(const Duration(hours: 2));
      _currentSettings = _currentSettings.copyWith(nextBackupTime: retryTime);
      await _saveSettings();
    }
  }

  /// 计算下次备份时间
  DateTime _calculateNextBackupTime(BackupFrequency frequency) {
    final now = DateTime.now();

    switch (frequency) {
      case BackupFrequency.daily:
        // 每天凌晨2点执行
        var nextBackup = DateTime(now.year, now.month, now.day, 2, 0);
        if (nextBackup.isBefore(now)) {
          nextBackup = nextBackup.add(const Duration(days: 1));
        }
        return nextBackup;

      case BackupFrequency.weekly:
        // 每周日凌晨2点执行
        var nextBackup = DateTime(now.year, now.month, now.day, 2, 0);
        final daysUntilSunday = (7 - now.weekday) % 7;
        if (daysUntilSunday == 0 && nextBackup.isBefore(now)) {
          // 如果今天是周日但已经过了2点，则下周日执行
          nextBackup = nextBackup.add(const Duration(days: 7));
        } else {
          nextBackup = nextBackup.add(Duration(days: daysUntilSunday));
        }
        return nextBackup;

      case BackupFrequency.monthly:
        // 每月1号凌晨2点执行
        var nextBackup = DateTime(now.year, now.month, 1, 2, 0);
        if (nextBackup.isBefore(now)) {
          // 下个月1号
          if (now.month == 12) {
            nextBackup = DateTime(now.year + 1, 1, 1, 2, 0);
          } else {
            nextBackup = DateTime(now.year, now.month + 1, 1, 2, 0);
          }
        }
        return nextBackup;
    }
  }

  /// 清理过期的备份文件
  Future<void> _cleanupOldBackups() async {
    try {
      final backups = await _backupService.getLocalBackups();

      // 过滤出自动备份文件（文件名包含auto_backup）
      final autoBackups = backups
          .where((backup) => backup.fileName.contains('auto_backup'))
          .toList();

      // 按创建时间排序，最新的在前
      autoBackups.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // 如果超过最大保留数量，删除多余的备份
      if (autoBackups.length > _currentSettings.maxBackupCount) {
        final backupsToDelete = autoBackups.skip(
          _currentSettings.maxBackupCount,
        );

        for (final backup in backupsToDelete) {
          try {
            await _backupService.deleteBackup(backup.id);
            debugPrint('已删除过期的自动备份: ${backup.fileName}');
          } catch (e) {
            debugPrint('删除过期备份失败: ${backup.fileName}, 错误: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('清理过期备份时发生错误: $e');
    }
  }

  /// 发送备份通知
  Future<void> _sendBackupNotification(bool success, String message) async {
    if (success) {
      await BackupNotificationService.showBackupSuccessNotification(
        title: '自动备份完成',
        message: message,
      );
    } else {
      await BackupNotificationService.showBackupFailureNotification(
        title: '自动备份失败',
        message: message,
      );
    }
  }

  /// 手动触发备份
  Future<BackupResult> triggerManualBackup() async {
    if (!_currentSettings.enabled) {
      return BackupResult.failure('自动备份未启用');
    }

    final backupOptions = backup_models.BackupOptions(
      customName: 'manual_auto_backup',
      includeImages: _currentSettings.backupOptions?.includeImages ?? false,
      encrypt: _currentSettings.backupOptions?.encrypt ?? false,
      password: _currentSettings.backupOptions?.password,
      compress: _currentSettings.backupOptions?.compress ?? false,
      description: '手动触发的自动备份 - ${DateTime.now().toIso8601String()}',
    );

    final result = await _backupService.createBackup(options: backupOptions);

    if (result.success) {
      // 更新最后备份时间，但不改变下次计划时间
      _currentSettings = _currentSettings.copyWith(
        lastBackupTime: DateTime.now(),
      );
      await _saveSettings();

      await _cleanupOldBackups();
    }

    return result;
  }

  /// 获取下次备份时间的描述
  String getNextBackupDescription() {
    if (!_currentSettings.enabled) {
      return '自动备份已禁用';
    }

    if (_currentSettings.nextBackupTime == null) {
      return '计算中...';
    }

    final now = DateTime.now();
    final nextBackup = _currentSettings.nextBackupTime!;
    final difference = nextBackup.difference(now);

    if (difference.isNegative) {
      return '等待执行';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays}天后';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时后';
    } else {
      return '${difference.inMinutes}分钟后';
    }
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        _currentSettings = AutoBackupSettings.fromJson(settingsMap);
      }
    } catch (e) {
      debugPrint('加载自动备份设置失败: $e');
      _currentSettings = const AutoBackupSettings();
    }
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(_currentSettings.toJson());
      await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      debugPrint('保存自动备份设置失败: $e');
    }
  }

  /// 停止调度器
  void dispose() {
    _schedulerTimer?.cancel();
  }
}
