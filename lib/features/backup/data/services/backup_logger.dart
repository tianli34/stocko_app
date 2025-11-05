import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// 备份操作日志级别
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// 日志条目
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String operation;
  final String message;
  final Map<String, dynamic>? details;
  final String? errorCode;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.operation,
    required this.message,
    this.details,
    this.errorCode,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'level': level.name,
        'operation': operation,
        'message': message,
        'details': details,
        'errorCode': errorCode,
        'stackTrace': stackTrace?.toString(),
      };

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
        timestamp: DateTime.parse(json['timestamp']),
        level: LogLevel.values.firstWhere((e) => e.name == json['level']),
        operation: json['operation'],
        message: json['message'],
        details: json['details'],
        errorCode: json['errorCode'],
        stackTrace: json['stackTrace'] != null 
            ? StackTrace.fromString(json['stackTrace'])
            : null,
      );
}

/// 备份操作日志记录器
class BackupLogger {
  static BackupLogger? _instance;
  static BackupLogger get instance => _instance ??= BackupLogger._();
  
  BackupLogger._();

  final List<LogEntry> _memoryLogs = [];
  final int _maxMemoryLogs = 1000;
  File? _logFile;
  bool _initialized = false;

  /// 初始化日志记录器
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logsDir = Directory(path.join(appDir.path, 'logs'));
      
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }
      
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      _logFile = File(path.join(logsDir.path, 'backup_$dateStr.log'));
      
      _initialized = true;
      
      // 记录初始化日志
      await info('BackupLogger', '日志记录器初始化完成');
    } catch (e) {
      // 如果无法初始化文件日志，至少保持内存日志可用
      _initialized = true;
    }
  }

  /// 记录调试信息
  Future<void> debug(String operation, String message, {
    Map<String, dynamic>? details,
  }) async {
    await _log(LogLevel.debug, operation, message, details: details);
  }

  /// 记录一般信息
  Future<void> info(String operation, String message, {
    Map<String, dynamic>? details,
  }) async {
    await _log(LogLevel.info, operation, message, details: details);
  }

  /// 记录警告信息
  Future<void> warning(String operation, String message, {
    Map<String, dynamic>? details,
  }) async {
    await _log(LogLevel.warning, operation, message, details: details);
  }

  /// 记录错误信息
  Future<void> error(String operation, String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? details,
    String? errorCode,
  }) async {
    final errorDetails = <String, dynamic>{
      if (details != null) ...details,
      if (error != null) 'originalError': error.toString(),
    };
    
    await _log(
      LogLevel.error, 
      operation, 
      message,
      details: errorDetails.isNotEmpty ? errorDetails : null,
      errorCode: errorCode,
      stackTrace: stackTrace,
    );
  }

  /// 记录严重错误
  Future<void> critical(String operation, String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? details,
    String? errorCode,
  }) async {
    final errorDetails = <String, dynamic>{
      if (details != null) ...details,
      if (error != null) 'originalError': error.toString(),
    };
    
    await _log(
      LogLevel.critical, 
      operation, 
      message,
      details: errorDetails.isNotEmpty ? errorDetails : null,
      errorCode: errorCode,
      stackTrace: stackTrace,
    );
  }

  /// 内部日志记录方法
  Future<void> _log(
    LogLevel level,
    String operation,
    String message, {
    Map<String, dynamic>? details,
    String? errorCode,
    StackTrace? stackTrace,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      operation: operation,
      message: message,
      details: details,
      errorCode: errorCode,
      stackTrace: stackTrace,
    );

    // 添加到内存日志
    _memoryLogs.add(entry);
    
    // 保持内存日志数量限制
    if (_memoryLogs.length > _maxMemoryLogs) {
      _memoryLogs.removeAt(0);
    }

    // 写入文件日志
    await _writeToFile(entry);
  }

  /// 写入文件日志
  Future<void> _writeToFile(LogEntry entry) async {
    if (_logFile == null) return;
    
    try {
      final logLine = '${entry.timestamp.toIso8601String()} '
          '[${entry.level.name.toUpperCase()}] '
          '${entry.operation}: ${entry.message}';
      
      final detailsLine = entry.details != null 
          ? '\n  Details: ${jsonEncode(entry.details)}'
          : '';
      
      final errorLine = entry.errorCode != null 
          ? '\n  ErrorCode: ${entry.errorCode}'
          : '';
      
      final stackLine = entry.stackTrace != null 
          ? '\n  StackTrace: ${entry.stackTrace.toString()}'
          : '';
      
      await _logFile!.writeAsString(
        '$logLine$detailsLine$errorLine$stackLine\n',
        mode: FileMode.append,
      );
    } catch (e) {
      // 如果无法写入文件，忽略错误以避免无限循环
    }
  }

  /// 获取内存中的日志条目
  List<LogEntry> getMemoryLogs({
    LogLevel? minLevel,
    String? operation,
    DateTime? since,
  }) {
    var logs = _memoryLogs.toList();
    
    if (minLevel != null) {
      final minIndex = LogLevel.values.indexOf(minLevel);
      logs = logs.where((log) => 
          LogLevel.values.indexOf(log.level) >= minIndex).toList();
    }
    
    if (operation != null) {
      logs = logs.where((log) => log.operation == operation).toList();
    }
    
    if (since != null) {
      logs = logs.where((log) => log.timestamp.isAfter(since)).toList();
    }
    
    return logs;
  }

  /// 清理旧日志文件
  Future<void> cleanupOldLogs({int keepDays = 30}) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logsDir = Directory(path.join(appDir.path, 'logs'));
      
      if (!await logsDir.exists()) return;
      
      final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));
      final logFiles = await logsDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .cast<File>()
          .toList();
      
      for (final file in logFiles) {
        final stat = await file.stat();
        if (stat.modified.isBefore(cutoffDate)) {
          await file.delete();
          await info('BackupLogger', '删除过期日志文件: ${path.basename(file.path)}');
        }
      }
    } catch (e) {
      await error('BackupLogger', '清理旧日志文件失败', error: e);
    }
  }

  /// 导出日志文件
  Future<String?> exportLogs({
    DateTime? startDate,
    DateTime? endDate,
    LogLevel? minLevel,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logsDir = Directory(path.join(appDir.path, 'logs'));
      
      if (!await logsDir.exists()) return null;
      
      final exportFile = File(path.join(
        appDir.path, 
        'backup_logs_export_${DateTime.now().millisecondsSinceEpoch}.json'
      ));
      
      // 收集文件日志
      final logFiles = await logsDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .cast<File>()
          .toList();
      
      for (final file in logFiles) {
        try {
          // 这里可以解析日志文件内容，但为了简化，我们主要使用内存日志
          await file.readAsString();
        } catch (e) {
          // 忽略无法读取的日志文件
        }
      }
      
      // 使用内存日志
      var logs = getMemoryLogs(minLevel: minLevel);
      
      if (startDate != null) {
        logs = logs.where((log) => log.timestamp.isAfter(startDate)).toList();
      }
      
      if (endDate != null) {
        logs = logs.where((log) => log.timestamp.isBefore(endDate)).toList();
      }
      
      final exportData = {
        'exportedAt': DateTime.now().toIso8601String(),
        'totalLogs': logs.length,
        'filters': {
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
          'minLevel': minLevel?.name,
        },
        'logs': logs.map((log) => log.toJson()).toList(),
      };
      
      await exportFile.writeAsString(jsonEncode(exportData));
      return exportFile.path;
    } catch (e) {
      await error('BackupLogger', '导出日志失败', error: e);
      return null;
    }
  }
}