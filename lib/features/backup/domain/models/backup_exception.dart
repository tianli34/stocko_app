import 'package:freezed_annotation/freezed_annotation.dart';
import 'backup_error_type.dart';

part 'backup_exception.freezed.dart';

/// 备份和恢复操作中的异常类
@freezed
abstract class BackupException with _$BackupException implements Exception {
  const factory BackupException({
    /// 错误类型
    required BackupErrorType type,
    /// 错误消息
    required String message,
    /// 原始错误对象
    Object? originalError,
    /// 堆栈跟踪
    StackTrace? stackTrace,
    /// 错误代码（可选）
    String? errorCode,
    /// 额外的错误详情
    Map<String, dynamic>? details,
  }) = _BackupException;

  /// 创建文件系统错误
  factory BackupException.fileSystem(
    String message, {
    Object? originalError,
    StackTrace? stackTrace,
  }) =>
      BackupException(
        type: BackupErrorType.fileSystemError,
        message: message,
        originalError: originalError,
        stackTrace: stackTrace,
      );

  /// 创建数据库错误
  factory BackupException.database(
    String message, {
    Object? originalError,
    StackTrace? stackTrace,
  }) =>
      BackupException(
        type: BackupErrorType.databaseError,
        message: message,
        originalError: originalError,
        stackTrace: stackTrace,
      );

  /// 创建序列化错误
  factory BackupException.serialization(
    String message, {
    Object? originalError,
    StackTrace? stackTrace,
  }) =>
      BackupException(
        type: BackupErrorType.serializationError,
        message: message,
        originalError: originalError,
        stackTrace: stackTrace,
      );

  /// 创建加密错误
  factory BackupException.encryption(
    String message, {
    Object? originalError,
    StackTrace? stackTrace,
  }) =>
      BackupException(
        type: BackupErrorType.encryptionError,
        message: message,
        originalError: originalError,
        stackTrace: stackTrace,
      );

  /// 创建验证错误
  factory BackupException.validation(
    String message, {
    Object? originalError,
    StackTrace? stackTrace,
  }) =>
      BackupException(
        type: BackupErrorType.validationError,
        message: message,
        originalError: originalError,
        stackTrace: stackTrace,
      );

  /// 创建权限错误
  factory BackupException.permissionDenied(
    String message, {
    Object? originalError,
    StackTrace? stackTrace,
  }) =>
      BackupException(
        type: BackupErrorType.permissionDenied,
        message: message,
        originalError: originalError,
        stackTrace: stackTrace,
      );

  /// 创建磁盘空间不足错误
  factory BackupException.insufficientSpace(
    String message, {
    Object? originalError,
    StackTrace? stackTrace,
  }) =>
      BackupException(
        type: BackupErrorType.insufficientSpace,
        message: message,
        originalError: originalError,
        stackTrace: stackTrace,
      );
}