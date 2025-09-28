import 'package:freezed_annotation/freezed_annotation.dart';
import 'validation_result.dart';

part 'integrity_check_result.freezed.dart';
part 'integrity_check_result.g.dart';

/// 完整性检查结果
@freezed
abstract class IntegrityCheckResult with _$IntegrityCheckResult {
  const factory IntegrityCheckResult({
    /// 整体完整性是否通过
    required bool isIntegrityValid,
    /// 校验和验证结果
    required bool checksumValid,
    /// 数据关系完整性结果
    required bool relationshipIntegrityValid,
    /// 表数据完整性结果
    required Map<String, bool> tableIntegrityResults,
    /// 缺失的关联记录
    @Default([]) List<MissingRelationship> missingRelationships,
    /// 孤立记录（没有关联的记录）
    @Default([]) List<OrphanedRecord> orphanedRecords,
    /// 重复记录
    @Default([]) List<DuplicateRecord> duplicateRecords,
    /// 数据统计信息
    required IntegrityStatistics statistics,
    /// 详细的验证结果
    @Default([]) List<ValidationResult> detailedResults,
  }) = _IntegrityCheckResult;

  factory IntegrityCheckResult.fromJson(Map<String, dynamic> json) =>
      _$IntegrityCheckResultFromJson(json);
}

/// 缺失的关联记录
@freezed
abstract class MissingRelationship with _$MissingRelationship {
  const factory MissingRelationship({
    /// 源表名
    required String sourceTable,
    /// 目标表名
    required String targetTable,
    /// 外键字段名
    required String foreignKeyField,
    /// 缺失的外键值
    required dynamic missingValue,
    /// 受影响的记录数量
    required int affectedRecordCount,
  }) = _MissingRelationship;

  factory MissingRelationship.fromJson(Map<String, dynamic> json) =>
      _$MissingRelationshipFromJson(json);
}

/// 孤立记录
@freezed
abstract class OrphanedRecord with _$OrphanedRecord {
  const factory OrphanedRecord({
    /// 表名
    required String tableName,
    /// 主键字段名
    required String primaryKeyField,
    /// 主键值
    required dynamic primaryKeyValue,
    /// 孤立的原因
    required String reason,
    /// 记录数据
    Map<String, dynamic>? recordData,
  }) = _OrphanedRecord;

  factory OrphanedRecord.fromJson(Map<String, dynamic> json) =>
      _$OrphanedRecordFromJson(json);
}

/// 重复记录
@freezed
abstract class DuplicateRecord with _$DuplicateRecord {
  const factory DuplicateRecord({
    /// 表名
    required String tableName,
    /// 重复的字段组合
    required List<String> duplicateFields,
    /// 重复的值
    required Map<String, dynamic> duplicateValues,
    /// 重复记录的数量
    required int duplicateCount,
    /// 重复记录的主键列表
    @Default([]) List<dynamic> duplicatePrimaryKeys,
  }) = _DuplicateRecord;

  factory DuplicateRecord.fromJson(Map<String, dynamic> json) =>
      _$DuplicateRecordFromJson(json);
}

/// 完整性统计信息
@freezed
abstract class IntegrityStatistics with _$IntegrityStatistics {
  const factory IntegrityStatistics({
    /// 总记录数
    required int totalRecords,
    /// 有效记录数
    required int validRecords,
    /// 无效记录数
    required int invalidRecords,
    /// 缺失关联记录数
    required int missingRelationshipCount,
    /// 孤立记录数
    required int orphanedRecordCount,
    /// 重复记录数
    required int duplicateRecordCount,
    /// 各表记录统计
    required Map<String, int> tableRecordCounts,
    /// 各表有效记录统计
    required Map<String, int> tableValidRecordCounts,
  }) = _IntegrityStatistics;

  factory IntegrityStatistics.fromJson(Map<String, dynamic> json) =>
      _$IntegrityStatisticsFromJson(json);
}