import 'package:freezed_annotation/freezed_annotation.dart';
import 'backup_metadata.dart';

part 'backup_result.freezed.dart';
part 'backup_result.g.dart';

/// 备份操作的结果
@freezed
abstract class BackupResult with _$BackupResult {
  const factory BackupResult({
    /// 操作是否成功
    required bool success,
    /// 备份文件路径
    String? filePath,
    /// 备份元数据
    BackupMetadata? metadata,
    /// 错误信息（如果失败）
    String? errorMessage,
    /// 操作开始时间
    required DateTime startTime,
    /// 操作结束时间
    required DateTime endTime,
    /// 备份的总记录数
    @Default(0) int totalRecordsBackedUp,
  }) = _BackupResult;

  factory BackupResult.fromJson(Map<String, dynamic> json) =>
      _$BackupResultFromJson(json);
}