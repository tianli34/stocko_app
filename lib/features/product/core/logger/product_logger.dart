// lib/features/product/core/logger/product_logger.dart

import 'package:flutter/foundation.dart';

/// 日志级别
enum LogLevel { debug, info, warning, error }

/// 产品模块统一日志服务
/// 
/// 在 debug 模式下输出日志，release 模式下静默
class ProductLogger {
  static const String _tag = '📦 [Product]';
  
  /// 当前日志级别（可配置）
  static LogLevel currentLevel = LogLevel.debug;
  
  /// 是否启用日志（仅在 debug 模式下启用）
  static bool get _isEnabled => kDebugMode;

  /// Debug 级别日志
  static void debug(String message, {String? tag}) {
    if (_isEnabled && currentLevel.index <= LogLevel.debug.index) {
      debugPrint('$_tag${tag != null ? ' [$tag]' : ''} 🔍 $message');
    }
  }

  /// Info 级别日志
  static void info(String message, {String? tag}) {
    if (_isEnabled && currentLevel.index <= LogLevel.info.index) {
      debugPrint('$_tag${tag != null ? ' [$tag]' : ''} ℹ️ $message');
    }
  }

  /// Warning 级别日志
  static void warning(String message, {String? tag}) {
    if (_isEnabled && currentLevel.index <= LogLevel.warning.index) {
      debugPrint('$_tag${tag != null ? ' [$tag]' : ''} ⚠️ $message');
    }
  }

  /// Error 级别日志
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (_isEnabled && currentLevel.index <= LogLevel.error.index) {
      debugPrint('$_tag${tag != null ? ' [$tag]' : ''} ❌ $message');
      if (error != null) {
        debugPrint('$_tag Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('$_tag StackTrace: $stackTrace');
      }
    }
  }

  /// 分隔线日志（用于标记流程开始/结束）
  static void separator(String title, {bool isStart = true}) {
    if (_isEnabled) {
      final marker = isStart ? '▶▶▶' : '◀◀◀';
      debugPrint('$_tag $marker $title $marker');
    }
  }
}
