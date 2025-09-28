import 'package:freezed_annotation/freezed_annotation.dart';

part 'compatibility_check_result.freezed.dart';
part 'compatibility_check_result.g.dart';

/// 兼容性检查结果
@freezed
abstract class CompatibilityCheckResult with _$CompatibilityCheckResult {
  const factory CompatibilityCheckResult({
    /// 整体兼容性
    required bool isCompatible,
    /// 应用版本兼容性
    required bool appVersionCompatible,
    /// 数据库架构版本兼容性
    required bool schemaVersionCompatible,
    /// 备份格式版本兼容性
    required bool backupFormatCompatible,
    /// 表结构兼容性
    required Map<String, bool> tableCompatibility,
    /// 兼容性问题列表
    @Default([]) List<CompatibilityIssue> issues,
    /// 兼容性警告列表
    @Default([]) List<CompatibilityWarning> warnings,
    /// 升级建议
    @Default([]) List<String> upgradeRecommendations,
    /// 兼容性详情
    required CompatibilityDetails details,
  }) = _CompatibilityCheckResult;

  factory CompatibilityCheckResult.fromJson(Map<String, dynamic> json) =>
      _$CompatibilityCheckResultFromJson(json);
}

/// 兼容性问题
@freezed
abstract class CompatibilityIssue with _$CompatibilityIssue {
  const factory CompatibilityIssue({
    /// 问题类型
    required CompatibilityIssueType type,
    /// 问题描述
    required String description,
    /// 问题严重程度
    required CompatibilityIssueSeverity severity,
    /// 受影响的组件（表名、字段名等）
    String? affectedComponent,
    /// 建议的解决方案
    String? suggestedSolution,
    /// 问题详情
    Map<String, dynamic>? details,
  }) = _CompatibilityIssue;

  factory CompatibilityIssue.fromJson(Map<String, dynamic> json) =>
      _$CompatibilityIssueFromJson(json);
}

/// 兼容性警告
@freezed
abstract class CompatibilityWarning with _$CompatibilityWarning {
  const factory CompatibilityWarning({
    /// 警告类型
    required CompatibilityWarningType type,
    /// 警告描述
    required String description,
    /// 受影响的组件
    String? affectedComponent,
    /// 警告详情
    Map<String, dynamic>? details,
  }) = _CompatibilityWarning;

  factory CompatibilityWarning.fromJson(Map<String, dynamic> json) =>
      _$CompatibilityWarningFromJson(json);
}

/// 兼容性详情
@freezed
abstract class CompatibilityDetails with _$CompatibilityDetails {
  const factory CompatibilityDetails({
    /// 当前应用版本
    required String currentAppVersion,
    /// 备份应用版本
    required String backupAppVersion,
    /// 当前数据库架构版本
    required int currentSchemaVersion,
    /// 备份数据库架构版本
    required int backupSchemaVersion,
    /// 当前备份格式版本
    required String currentBackupFormatVersion,
    /// 备份文件格式版本
    required String backupFormatVersion,
    /// 支持的最小架构版本
    required int minSupportedSchemaVersion,
    /// 支持的最大架构版本
    required int maxSupportedSchemaVersion,
    /// 支持的备份格式版本列表
    required List<String> supportedBackupFormatVersions,
  }) = _CompatibilityDetails;

  factory CompatibilityDetails.fromJson(Map<String, dynamic> json) =>
      _$CompatibilityDetailsFromJson(json);
}

/// 兼容性问题类型
enum CompatibilityIssueType {
  /// 应用版本不兼容
  appVersionIncompatible,
  /// 数据库架构版本不兼容
  schemaVersionIncompatible,
  /// 备份格式版本不兼容
  backupFormatIncompatible,
  /// 表结构不兼容
  tableStructureIncompatible,
  /// 字段类型不兼容
  fieldTypeIncompatible,
  /// 缺失必需字段
  missingRequiredField,
  /// 未知表
  unknownTable,
  /// 未知字段
  unknownField,
}

/// 兼容性问题严重程度
enum CompatibilityIssueSeverity {
  /// 信息性问题，不影响恢复
  info,
  /// 警告级问题，可能影响部分功能
  warning,
  /// 错误级问题，影响恢复质量
  error,
  /// 致命问题，无法恢复
  critical,
}

/// 兼容性警告类型
enum CompatibilityWarningType {
  /// 版本差异较大
  versionGapLarge,
  /// 表结构有变化
  tableStructureChanged,
  /// 字段已废弃
  fieldDeprecated,
  /// 新增字段
  newFieldAdded,
  /// 数据类型变化
  dataTypeChanged,
  /// 约束变化
  constraintChanged,
}