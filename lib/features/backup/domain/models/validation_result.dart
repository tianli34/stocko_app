import 'package:freezed_annotation/freezed_annotation.dart';

part 'validation_result.freezed.dart';
part 'validation_result.g.dart';

/// 验证结果
@freezed
abstract class ValidationResult with _$ValidationResult {
  const factory ValidationResult({
    /// 验证是否通过
    required bool isValid,
    /// 验证类型
    required ValidationType type,
    /// 验证的目标（文件路径、表名等）
    required String target,
    /// 错误信息列表
    @Default([]) List<ValidationError> errors,
    /// 警告信息列表
    @Default([]) List<ValidationWarning> warnings,
    /// 修复建议列表
    @Default([]) List<String> repairSuggestions,
    /// 验证详情
    Map<String, dynamic>? details,
  }) = _ValidationResult;

  factory ValidationResult.fromJson(Map<String, dynamic> json) =>
      _$ValidationResultFromJson(json);
}

/// 验证类型
enum ValidationType {
  /// 文件格式验证
  fileFormat,
  /// 版本兼容性验证
  versionCompatibility,
  /// 数据完整性验证
  dataIntegrity,
  /// 文件损坏检测
  fileCorruption,
  /// 恢复前预检查
  preRestoreCheck,
  /// 表结构验证
  tableStructure,
  /// 数据类型验证
  dataTypes,
  /// 外键关系验证
  foreignKeyRelationships,
  /// 数据约束验证
  dataConstraints,
}

/// 验证错误
@freezed
abstract class ValidationError with _$ValidationError {
  const factory ValidationError({
    /// 错误代码
    required String code,
    /// 错误消息
    required String message,
    /// 错误严重程度
    required ErrorSeverity severity,
    /// 错误位置（表名、字段名等）
    String? location,
    /// 错误详情
    Map<String, dynamic>? details,
  }) = _ValidationError;

  factory ValidationError.fromJson(Map<String, dynamic> json) =>
      _$ValidationErrorFromJson(json);
}

/// 验证警告
@freezed
abstract class ValidationWarning with _$ValidationWarning {
  const factory ValidationWarning({
    /// 警告代码
    required String code,
    /// 警告消息
    required String message,
    /// 警告位置（表名、字段名等）
    String? location,
    /// 警告详情
    Map<String, dynamic>? details,
  }) = _ValidationWarning;

  factory ValidationWarning.fromJson(Map<String, dynamic> json) =>
      _$ValidationWarningFromJson(json);
}

/// 错误严重程度
enum ErrorSeverity {
  /// 低级错误，不影响恢复
  low,
  /// 中级错误，可能影响部分数据
  medium,
  /// 高级错误，严重影响恢复
  high,
  /// 致命错误，无法恢复
  critical,
}