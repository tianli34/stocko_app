import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../domain/models/backup_exception.dart';
import '../../domain/models/backup_error_type.dart';
import 'backup_logger.dart';
import 'backup_error_handler.dart';
import 'backup_resource_manager.dart';

/// 错误处理服务
class BackupErrorService {
  static BackupErrorService? _instance;
  static BackupErrorService get instance => _instance ??= BackupErrorService._();
  
  BackupErrorService._();

  final BackupLogger _logger = BackupLogger.instance;
  final BackupResourceManager _resourceManager = BackupResourceManager.instance;
  bool _initialized = false;

  /// 错误事件流
  Stream<UserFriendlyError> get errorStream => _errorStreamController.stream;
  final StreamController<UserFriendlyError> _errorStreamController = 
      StreamController<UserFriendlyError>.broadcast();

  /// 初始化错误服务
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await _logger.initialize();
      await _resourceManager.initialize();
      
      // 设置全局错误处理
      if (kDebugMode) {
        FlutterError.onError = _handleFlutterError;
      }
      
      _initialized = true;
      await _logger.info('ErrorService', '错误处理服务初始化完成');
    } catch (e) {
      debugPrint('Failed to initialize BackupErrorService: $e');
      rethrow;
    }
  }

  /// 处理错误并返回用户友好的错误信息
  Future<UserFriendlyError> handleError(
    Object error, {
    String? operation,
    Map<String, dynamic>? context,
    bool shouldCleanupResources = true,
  }) async {
    try {
      // 记录错误
      await _logError(error, operation: operation, context: context);
      
      // 清理相关资源
      if (shouldCleanupResources && operation != null) {
        await _cleanupOperationResources(operation);
      }
      
      // 转换为用户友好的错误
      final userFriendlyError = BackupErrorHandler.handleError(
        error,
        operation: operation,
        context: context,
      );
      
      // 发送错误事件
      _errorStreamController.add(userFriendlyError);
      
      return userFriendlyError;
    } catch (e) {
      // 如果错误处理本身失败，返回一个基本的错误信息
      await _logger.critical('ErrorService', '错误处理失败', error: e);
      
      return const UserFriendlyError(
        title: '系统错误',
        message: '处理错误时发生了意外问题，请重启应用后重试。',
        canRetry: false,
      );
    }
  }

  /// 带重试机制执行操作
  Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    RetryConfig? config,
    String? operationName,
    Map<String, dynamic>? context,
    bool shouldCleanupOnFailure = true,
  }) async {
    final opName = operationName ?? 'UnknownOperation';
    
    try {
      return await BackupErrorHandler.executeWithRetry(
        operation,
        config: config ?? const RetryConfig(),
        operationName: opName,
        context: context,
      );
    } catch (error) {
      // 处理最终失败的错误
      final userFriendlyError = await handleError(
        error,
        operation: opName,
        context: context,
        shouldCleanupResources: shouldCleanupOnFailure,
      );
      
      // 重新抛出原始错误，但已经记录和处理过了
      throw BackupException(
        type: BackupErrorType.unknown,
        message: userFriendlyError.message,
        originalError: error,
      );
    }
  }

  /// 安全执行操作（捕获所有异常）
  Future<T?> executeSafely<T>(
    Future<T> Function() operation, {
    String? operationName,
    Map<String, dynamic>? context,
    T? defaultValue,
    bool logErrors = true,
  }) async {
    try {
      return await operation();
    } catch (error) {
      if (logErrors) {
        await handleError(
          error,
          operation: operationName,
          context: context,
        );
      }
      return defaultValue;
    }
  }

  /// 创建操作上下文
  Future<String> createOperationContext(String operation, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final operationId = 'op_${DateTime.now().millisecondsSinceEpoch}';
      
      await _logger.info(operation, '开始操作', details: {
        'operationId': operationId,
        if (metadata != null) ...metadata,
      });
      
      return operationId;
    } catch (e) {
      await _logger.error('ErrorService', '创建操作上下文失败', error: e);
      return 'unknown_operation';
    }
  }

  /// 完成操作上下文
  Future<void> completeOperationContext(
    String operationId,
    String operation, {
    bool success = true,
    String? message,
    Map<String, dynamic>? result,
  }) async {
    try {
      if (success) {
        await _logger.info(operation, message ?? '操作完成', details: {
          'operationId': operationId,
          if (result != null) ...result,
        });
      } else {
        await _logger.warning(operation, message ?? '操作失败', details: {
          'operationId': operationId,
          if (result != null) ...result,
        });
      }
      
      // 清理操作相关资源
      await _cleanupOperationResources(operation);
    } catch (e) {
      await _logger.error('ErrorService', '完成操作上下文失败', error: e);
    }
  }

  /// 获取错误统计信息
  Future<Map<String, dynamic>> getErrorStats({
    Duration? period,
  }) async {
    try {
      final since = period != null 
          ? DateTime.now().subtract(period)
          : DateTime.now().subtract(const Duration(days: 7));
      
      final logs = _logger.getMemoryLogs(
        minLevel: LogLevel.warning,
        since: since,
      );
      
      final errorCounts = <String, int>{};
      final operationCounts = <String, int>{};
      
      for (final log in logs) {
        // 统计错误类型
        if (log.details?['errorType'] != null) {
          final errorType = log.details!['errorType'] as String;
          errorCounts[errorType] = (errorCounts[errorType] ?? 0) + 1;
        }
        
        // 统计操作类型
        operationCounts[log.operation] = (operationCounts[log.operation] ?? 0) + 1;
      }
      
      return {
        'period': period?.inDays ?? 7,
        'totalErrors': logs.length,
        'errorsByType': errorCounts,
        'errorsByOperation': operationCounts,
        'resourceStats': _resourceManager.getResourceStats(),
      };
    } catch (e) {
      await _logger.error('ErrorService', '获取错误统计失败', error: e);
      return {'error': '无法获取统计信息'};
    }
  }

  /// 导出错误报告
  Future<String?> exportErrorReport({
    Duration? period,
    bool includeResourceInfo = true,
  }) async {
    try {
      final stats = await getErrorStats(period: period);
      
      // 导出日志
      final logFilePath = await _logger.exportLogs(
        startDate: period != null 
            ? DateTime.now().subtract(period)
            : null,
        minLevel: LogLevel.warning,
      );
      
      if (logFilePath != null) {
        await _logger.info('ErrorService', '错误报告导出完成', details: {
          'filePath': logFilePath,
          'stats': stats,
        });
      }
      
      return logFilePath;
    } catch (e) {
      await _logger.error('ErrorService', '导出错误报告失败', error: e);
      return null;
    }
  }

  /// 清理错误服务
  Future<void> cleanup() async {
    try {
      await _logger.info('ErrorService', '开始清理错误服务');
      
      // 清理资源
      await _resourceManager.dispose();
      
      // 清理旧日志
      await _logger.cleanupOldLogs();
      
      // 关闭流
      await _errorStreamController.close();
      
      _initialized = false;
      await _logger.info('ErrorService', '错误服务清理完成');
    } catch (e) {
      debugPrint('Failed to cleanup BackupErrorService: $e');
    }
  }

  /// 记录错误
  Future<void> _logError(
    Object error, {
    String? operation,
    Map<String, dynamic>? context,
  }) async {
    final severity = BackupErrorHandler.getErrorSeverity(error);
    final operationName = operation ?? 'UnknownOperation';
    
    switch (severity) {
      case LogLevel.debug:
        await _logger.debug(operationName, error.toString(), details: context);
        break;
      case LogLevel.info:
        await _logger.info(operationName, error.toString(), details: context);
        break;
      case LogLevel.warning:
        await _logger.warning(operationName, error.toString(), details: context);
        break;
      case LogLevel.error:
        await _logger.error(operationName, error.toString(), 
            error: error, details: context);
        break;
      case LogLevel.critical:
        await _logger.critical(operationName, error.toString(), 
            error: error, details: context);
        break;
    }
  }

  /// 清理操作相关资源
  Future<void> _cleanupOperationResources(String operation) async {
    try {
      await _resourceManager.releaseOperationResources(operation);
    } catch (e) {
      await _logger.warning('ErrorService', '清理操作资源失败', 
          details: {'operation': operation, 'error': e.toString()});
    }
  }

  /// 处理Flutter错误
  void _handleFlutterError(FlutterErrorDetails details) {
    // 记录Flutter框架错误
    _logger.error(
      'FlutterError',
      details.summary.toString(),
      error: details.exception,
      stackTrace: details.stack,
      details: {
        'library': details.library,
        'context': details.context?.toString(),
      },
    );
    
    // 调用默认的错误处理
    FlutterError.presentError(details);
  }
}