import 'dart:io';

import '../../domain/models/backup_exception.dart';
import '../../domain/models/backup_error_type.dart';
import 'backup_logger.dart';

/// 错误恢复建议
class ErrorRecoverySuggestion {
  final String title;
  final String description;
  final List<String> steps;
  final bool canRetry;
  final bool requiresUserAction;

  const ErrorRecoverySuggestion({
    required this.title,
    required this.description,
    required this.steps,
    this.canRetry = false,
    this.requiresUserAction = true,
  });
}

/// 用户友好的错误信息
class UserFriendlyError {
  final String title;
  final String message;
  final String? technicalDetails;
  final ErrorRecoverySuggestion? suggestion;
  final bool canRetry;

  const UserFriendlyError({
    required this.title,
    required this.message,
    this.technicalDetails,
    this.suggestion,
    this.canRetry = false,
  });
}

/// 重试配置
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final bool Function(Object error)? shouldRetry;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
    this.shouldRetry,
  });

  static const RetryConfig fileSystem = RetryConfig(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 2),
    backoffMultiplier: 1.5,
    maxDelay: Duration(seconds: 10),
  );

  static const RetryConfig database = RetryConfig(
    maxAttempts: 2,
    initialDelay: Duration(seconds: 1),
    backoffMultiplier: 2.0,
    maxDelay: Duration(seconds: 5),
  );

  static const RetryConfig network = RetryConfig(
    maxAttempts: 5,
    initialDelay: Duration(seconds: 3),
    backoffMultiplier: 2.0,
    maxDelay: Duration(seconds: 60),
  );
}

/// 备份错误处理器
class BackupErrorHandler {
  static final BackupLogger _logger = BackupLogger.instance;

  /// 将异常转换为用户友好的错误信息
  static UserFriendlyError handleError(Object error, {
    String? operation,
    Map<String, dynamic>? context,
  }) {
    // 记录错误日志
    _logError(error, operation: operation, context: context);

    if (error is BackupException) {
      return _handleBackupException(error);
    } else if (error is FileSystemException) {
      return _handleFileSystemException(error);
    } else if (error is FormatException) {
      return _handleFormatException(error);
    } else {
      return _handleGenericError(error);
    }
  }

  /// 处理备份异常
  static UserFriendlyError _handleBackupException(BackupException error) {
    switch (error.type) {
      case BackupErrorType.fileSystemError:
        return UserFriendlyError(
          title: '文件操作失败',
          message: '无法访问或操作备份文件，请检查存储权限和可用空间。',
          technicalDetails: error.message,
          suggestion: const ErrorRecoverySuggestion(
            title: '解决建议',
            description: '请尝试以下解决方案：',
            steps: [
              '检查应用是否有存储权限',
              '确保设备有足够的可用存储空间',
              '尝试选择其他存储位置',
              '重启应用后重试',
            ],
            canRetry: true,
          ),
          canRetry: true,
        );

      case BackupErrorType.databaseError:
        return UserFriendlyError(
          title: '数据库操作失败',
          message: '读取或写入数据库时发生错误，可能是数据库文件损坏或被占用。',
          technicalDetails: error.message,
          suggestion: const ErrorRecoverySuggestion(
            title: '解决建议',
            description: '请尝试以下解决方案：',
            steps: [
              '关闭其他可能使用数据库的功能',
              '重启应用后重试',
              '如果问题持续，可能需要修复数据库',
            ],
            canRetry: true,
          ),
          canRetry: true,
        );

      case BackupErrorType.serializationError:
        return UserFriendlyError(
          title: '数据格式错误',
          message: '备份文件格式不正确或已损坏，无法正确解析数据。',
          technicalDetails: error.message,
          suggestion: const ErrorRecoverySuggestion(
            title: '解决建议',
            description: '请尝试以下解决方案：',
            steps: [
              '检查备份文件是否完整',
              '尝试使用其他备份文件',
              '重新创建备份文件',
            ],
            canRetry: false,
          ),
          canRetry: false,
        );

      case BackupErrorType.encryptionError:
        return UserFriendlyError(
          title: '加密操作失败',
          message: '加密或解密备份文件时发生错误，请检查密码是否正确。',
          technicalDetails: error.message,
          suggestion: const ErrorRecoverySuggestion(
            title: '解决建议',
            description: '请尝试以下解决方案：',
            steps: [
              '确认输入的密码正确',
              '检查备份文件是否确实加密',
              '尝试使用原始密码重新操作',
            ],
            canRetry: true,
          ),
          canRetry: true,
        );

      case BackupErrorType.validationError:
        return UserFriendlyError(
          title: '数据验证失败',
          message: '备份文件数据完整性验证失败，文件可能已损坏或被篡改。',
          technicalDetails: error.message,
          suggestion: const ErrorRecoverySuggestion(
            title: '解决建议',
            description: '请尝试以下解决方案：',
            steps: [
              '检查备份文件是否完整下载',
              '尝试使用其他备份文件',
              '重新创建备份文件',
              '检查存储设备是否有问题',
            ],
            canRetry: false,
          ),
          canRetry: false,
        );

      case BackupErrorType.insufficientSpace:
        return UserFriendlyError(
          title: '存储空间不足',
          message: '设备存储空间不足，无法完成备份操作。',
          technicalDetails: error.message,
          suggestion: const ErrorRecoverySuggestion(
            title: '解决建议',
            description: '请尝试以下解决方案：',
            steps: [
              '清理设备存储空间',
              '删除不需要的文件或应用',
              '选择其他存储位置',
              '使用外部存储设备',
            ],
            canRetry: true,
          ),
          canRetry: true,
        );

      case BackupErrorType.permissionDenied:
        return UserFriendlyError(
          title: '权限被拒绝',
          message: '应用没有足够的权限访问所需的文件或目录。',
          technicalDetails: error.message,
          suggestion: const ErrorRecoverySuggestion(
            title: '解决建议',
            description: '请尝试以下解决方案：',
            steps: [
              '在系统设置中授予应用存储权限',
              '选择应用有权限访问的目录',
              '重启应用后重试',
            ],
            canRetry: true,
          ),
          canRetry: true,
        );

      case BackupErrorType.fileNotFound:
        return UserFriendlyError(
          title: '文件未找到',
          message: '指定的备份文件不存在或已被删除。',
          technicalDetails: error.message,
          suggestion: const ErrorRecoverySuggestion(
            title: '解决建议',
            description: '请尝试以下解决方案：',
            steps: [
              '检查文件路径是否正确',
              '确认文件未被移动或删除',
              '选择其他备份文件',
            ],
            canRetry: false,
          ),
          canRetry: false,
        );

      case BackupErrorType.unsupportedFormat:
        return UserFriendlyError(
          title: '不支持的文件格式',
          message: '备份文件格式不受支持，可能是旧版本或损坏的文件。',
          technicalDetails: error.message,
          suggestion: const ErrorRecoverySuggestion(
            title: '解决建议',
            description: '请尝试以下解决方案：',
            steps: [
              '使用较新版本的备份文件',
              '检查文件是否完整',
              '联系技术支持获取帮助',
            ],
            canRetry: false,
          ),
          canRetry: false,
        );

      case BackupErrorType.incorrectPassword:
        return UserFriendlyError(
          title: '密码错误',
          message: '输入的密码不正确，无法解密备份文件。',
          technicalDetails: error.message,
          suggestion: const ErrorRecoverySuggestion(
            title: '解决建议',
            description: '请尝试以下解决方案：',
            steps: [
              '确认输入的密码正确',
              '检查大小写和特殊字符',
              '尝试使用创建备份时的原始密码',
            ],
            canRetry: true,
          ),
          canRetry: true,
        );

      case BackupErrorType.operationCancelled:
        return UserFriendlyError(
          title: '操作已取消',
          message: '备份或恢复操作已被用户取消。',
          technicalDetails: error.message,
          canRetry: true,
        );

      case BackupErrorType.networkError:
        return UserFriendlyError(
          title: '网络连接错误',
          message: '网络连接不稳定或已断开，无法完成操作。',
          technicalDetails: error.message,
          suggestion: const ErrorRecoverySuggestion(
            title: '解决建议',
            description: '请尝试以下解决方案：',
            steps: [
              '检查网络连接是否正常',
              '尝试切换到其他网络',
              '稍后重试操作',
            ],
            canRetry: true,
          ),
          canRetry: true,
        );

      case BackupErrorType.compressionError:
        return UserFriendlyError(
          title: '压缩操作失败',
          message: '备份文件压缩或解压过程中发生错误，请重试或选择不压缩的备份方式。',
          technicalDetails: error.message,
          suggestion: const ErrorRecoverySuggestion(
            title: '解决建议',
            description: '请尝试以下解决方案：',
            steps: [
              '重试备份操作',
              '选择不压缩的备份选项',
              '检查设备存储空间是否充足',
              '确保备份文件未损坏',
            ],
            canRetry: true,
          ),
          canRetry: true,
        );

      case BackupErrorType.unknown:
        return UserFriendlyError(
          title: '未知错误',
          message: '发生了未知错误，请稍后重试或联系技术支持。',
          technicalDetails: error.message,
          suggestion: const ErrorRecoverySuggestion(
            title: '解决建议',
            description: '请尝试以下解决方案：',
            steps: [
              '重启应用后重试',
              '检查设备是否正常工作',
              '联系技术支持并提供错误详情',
            ],
            canRetry: true,
          ),
          canRetry: true,
        );
    }
  }

  /// 处理文件系统异常
  static UserFriendlyError _handleFileSystemException(FileSystemException error) {
    return UserFriendlyError(
      title: '文件操作失败',
      message: '无法访问或操作文件，请检查文件路径和权限。',
      technicalDetails: error.toString(),
      suggestion: const ErrorRecoverySuggestion(
        title: '解决建议',
        description: '请尝试以下解决方案：',
        steps: [
          '检查文件路径是否正确',
          '确认应用有足够的权限',
          '检查存储设备是否正常',
        ],
        canRetry: true,
      ),
      canRetry: true,
    );
  }

  /// 处理格式异常
  static UserFriendlyError _handleFormatException(FormatException error) {
    return UserFriendlyError(
      title: '数据格式错误',
      message: '文件格式不正确或数据已损坏。',
      technicalDetails: error.toString(),
      suggestion: const ErrorRecoverySuggestion(
        title: '解决建议',
        description: '请尝试以下解决方案：',
        steps: [
          '检查文件是否完整',
          '尝试使用其他备份文件',
          '重新创建备份文件',
        ],
        canRetry: false,
      ),
      canRetry: false,
    );
  }

  /// 处理通用错误
  static UserFriendlyError _handleGenericError(Object error) {
    return UserFriendlyError(
      title: '操作失败',
      message: '操作过程中发生了意外错误，请稍后重试。',
      technicalDetails: error.toString(),
      suggestion: const ErrorRecoverySuggestion(
        title: '解决建议',
        description: '请尝试以下解决方案：',
        steps: [
          '稍后重试操作',
          '重启应用',
          '检查设备状态',
          '联系技术支持',
        ],
        canRetry: true,
      ),
      canRetry: true,
    );
  }

  /// 记录错误日志
  static void _logError(Object error, {
    String? operation,
    Map<String, dynamic>? context,
  }) {
    final operationName = operation ?? 'UnknownOperation';
    
    if (error is BackupException) {
      _logger.error(
        operationName,
        error.message,
        error: error.originalError,
        stackTrace: error.stackTrace,
        details: {
          'errorType': error.type.name,
          'errorCode': error.errorCode,
          if (error.details != null) ...error.details!,
          if (context != null) ...context,
        },
        errorCode: error.errorCode,
      );
    } else {
      _logger.error(
        operationName,
        error.toString(),
        error: error,
        stackTrace: StackTrace.current,
        details: context,
      );
    }
  }

  /// 带重试机制的操作执行
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    RetryConfig config = const RetryConfig(),
    String? operationName,
    Map<String, dynamic>? context,
  }) async {
    final opName = operationName ?? 'RetryableOperation';
    var attempt = 0;
    var delay = config.initialDelay;

    while (attempt < config.maxAttempts) {
      attempt++;
      
      try {
        await _logger.debug(opName, '开始执行操作 (尝试 $attempt/${config.maxAttempts})', 
            details: context);
        
        final result = await operation();
        
        if (attempt > 1) {
          await _logger.info(opName, '操作在第 $attempt 次尝试后成功完成');
        }
        
        return result;
      } catch (error) {
        await _logger.warning(opName, '第 $attempt 次尝试失败: ${error.toString()}',
            details: {'attempt': attempt, 'maxAttempts': config.maxAttempts});

        // 检查是否应该重试
        final shouldRetry = config.shouldRetry?.call(error) ?? _shouldRetryByDefault(error);
        
        if (attempt >= config.maxAttempts || !shouldRetry) {
          await _logger.error(opName, '操作最终失败，已达到最大重试次数或不可重试', 
              error: error, details: {'totalAttempts': attempt});
          rethrow;
        }

        // 等待后重试
        if (attempt < config.maxAttempts) {
          await _logger.debug(opName, '等待 ${delay.inMilliseconds}ms 后重试');
          await Future.delayed(delay);
          
          // 计算下次延迟时间
          delay = Duration(
            milliseconds: (delay.inMilliseconds * config.backoffMultiplier).round(),
          );
          
          if (delay > config.maxDelay) {
            delay = config.maxDelay;
          }
        }
      }
    }

    throw StateError('Unreachable code');
  }

  /// 默认的重试判断逻辑
  static bool _shouldRetryByDefault(Object error) {
    if (error is BackupException) {
      switch (error.type) {
        case BackupErrorType.fileSystemError:
        case BackupErrorType.databaseError:
        case BackupErrorType.networkError:
        case BackupErrorType.insufficientSpace:
          return true;
        case BackupErrorType.serializationError:
        case BackupErrorType.validationError:
        case BackupErrorType.unsupportedFormat:
        case BackupErrorType.incorrectPassword:
        case BackupErrorType.compressionError:
          return false;
        default:
          return true;
      }
    }
    
    if (error is FileSystemException) {
      return true;
    }
    
    if (error is FormatException) {
      return false;
    }
    
    return true; // 默认可重试
  }

  /// 获取错误的严重程度
  static LogLevel getErrorSeverity(Object error) {
    if (error is BackupException) {
      switch (error.type) {
        case BackupErrorType.operationCancelled:
          return LogLevel.info;
        case BackupErrorType.insufficientSpace:
        case BackupErrorType.permissionDenied:
        case BackupErrorType.fileNotFound:
          return LogLevel.warning;
        case BackupErrorType.databaseError:
        case BackupErrorType.validationError:
        case BackupErrorType.compressionError:
          return LogLevel.critical;
        default:
          return LogLevel.error;
      }
    }
    
    return LogLevel.error;
  }
}