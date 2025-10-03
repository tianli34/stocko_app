import 'package:freezed_annotation/freezed_annotation.dart';
import 'backup_metadata.dart';

part 'restore_preview.freezed.dart';
part 'restore_preview.g.dart';

/// 恢复预览信息
@freezed
abstract class RestorePreview with _$RestorePreview {
  const factory RestorePreview({
    /// 备份文件元数据
    required BackupMetadata metadata,
    /// 各表将要恢复的记录数
    required Map<String, int> recordCounts,
    /// 当前数据库各表的记录数
    @Default({}) Map<String, int> currentDatabaseCounts,
    /// 预计的数据冲突数量
    @Default(0) int estimatedConflicts,
    /// 兼容性检查结果
    required bool isCompatible,
    /// 兼容性警告信息
    @Default([]) List<String> compatibilityWarnings,
    /// 预计恢复时间（秒）
    int? estimatedDurationSeconds,
  }) = _RestorePreview;

  factory RestorePreview.fromJson(Map<String, dynamic> json) =>
      _$RestorePreviewFromJson(json);
}