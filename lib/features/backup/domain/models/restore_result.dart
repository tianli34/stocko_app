import 'package:freezed_annotation/freezed_annotation.dart';

part 'restore_result.freezed.dart';
part 'restore_result.g.dart';

/// 数据恢复操作的结果
@freezed
abstract class RestoreResult with _$RestoreResult {
  const factory RestoreResult({
    /// 操作是否成功
    required bool success,
    /// 恢复的总记录数
    required int totalRecordsRestored,
    /// 各表恢复的记录数统计
    required Map<String, int> tableRecordCounts,
    /// 操作开始时间
    required DateTime startTime,
    /// 操作结束时间
    required DateTime endTime,
    /// 错误信息（如果失败）
    String? errorMessage,
    /// 警告信息列表
    @Default([]) List<String> warnings,
    /// 跳过的记录数（由于冲突或验证失败）
    @Default(0) int skippedRecords,
  }) = _RestoreResult;

  factory RestoreResult.fromJson(Map<String, dynamic> json) =>
      _$RestoreResultFromJson(json);
}