import 'package:freezed_annotation/freezed_annotation.dart';

part 'auto_backup_settings.freezed.dart';
part 'auto_backup_settings.g.dart';

/// 自动备份频率枚举
enum BackupFrequency {
  @JsonValue('daily')
  daily,
  @JsonValue('weekly')
  weekly,
  @JsonValue('monthly')
  monthly,
}

/// 自动备份设置
@freezed
abstract class AutoBackupSettings with _$AutoBackupSettings {
  const factory AutoBackupSettings({
    /// 是否启用自动备份
    @Default(false) bool enabled,
    /// 备份频率
    @Default(BackupFrequency.weekly) BackupFrequency frequency,
    /// 最大保留备份文件数量
    @Default(5) int maxBackupCount,
    /// 上次自动备份时间
    DateTime? lastBackupTime,
    /// 下次计划备份时间
    DateTime? nextBackupTime,
    /// 是否在WiFi下才备份
    @Default(true) bool wifiOnly,
    /// 是否在充电时才备份
    @Default(false) bool chargingOnly,
    /// 自动备份的备份选项
    AutoBackupOptions? backupOptions,
  }) = _AutoBackupSettings;

  factory AutoBackupSettings.fromJson(Map<String, dynamic> json) =>
      _$AutoBackupSettingsFromJson(json);
}

/// 自动备份的备份选项（简化版）
@freezed
abstract class AutoBackupOptions with _$AutoBackupOptions {
  const factory AutoBackupOptions({
    /// 是否包含图片文件
    @Default(false) bool includeImages,
    /// 是否加密备份
    @Default(false) bool encrypt,
    /// 加密密码
    String? password,
    /// 是否压缩备份文件
    @Default(false) bool compress,
  }) = _AutoBackupOptions;

  factory AutoBackupOptions.fromJson(Map<String, dynamic> json) =>
      _$AutoBackupOptionsFromJson(json);
}