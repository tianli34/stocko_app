import 'package:flutter/foundation.dart';

/// 图片缓存性能监控
/// 用于跟踪和分析图片缓存的性能指标
class ImageCachePerformanceMonitor {
  static final ImageCachePerformanceMonitor _instance =
      ImageCachePerformanceMonitor._internal();
  factory ImageCachePerformanceMonitor() => _instance;
  ImageCachePerformanceMonitor._internal();

  // 性能统计
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _totalRequests = 0;

  final List<Duration> _loadTimes = [];
  final Map<String, int> _imageRequests = {};

  DateTime? _sessionStartTime;

  /// 初始化监控
  void initialize() {
    _sessionStartTime = DateTime.now();
    _cacheHits = 0;
    _cacheMisses = 0;
    _totalRequests = 0;
    _loadTimes.clear();
    _imageRequests.clear();

    debugPrint('图片缓存性能监控已启动');
  }

  /// 记录缓存命中
  void recordCacheHit(String imagePath) {
    _cacheHits++;
    _totalRequests++;
    _recordImageRequest(imagePath);

    if (kDebugMode) {
      debugPrint('缓存命中: $imagePath');
    }
  }

  /// 记录缓存未命中
  void recordCacheMiss(String imagePath) {
    _cacheMisses++;
    _totalRequests++;
    _recordImageRequest(imagePath);

    if (kDebugMode) {
      debugPrint('缓存未命中: $imagePath');
    }
  }

  /// 记录图片加载时间
  void recordLoadTime(Duration duration) {
    _loadTimes.add(duration);

    if (kDebugMode) {
      debugPrint('图片加载时间: ${duration.inMilliseconds}ms');
    }
  }

  /// 记录图片请求
  void _recordImageRequest(String imagePath) {
    final fileName = imagePath.split('/').last;
    _imageRequests[fileName] = (_imageRequests[fileName] ?? 0) + 1;
  }

  /// 获取缓存命中率
  double getCacheHitRate() {
    if (_totalRequests == 0) return 0.0;
    return _cacheHits / _totalRequests;
  }

  /// 获取平均加载时间
  Duration getAverageLoadTime() {
    if (_loadTimes.isEmpty) return Duration.zero;

    final totalMs = _loadTimes.fold<int>(
      0,
      (sum, duration) => sum + duration.inMilliseconds,
    );
    return Duration(milliseconds: (totalMs / _loadTimes.length).round());
  }

  /// 获取最快加载时间
  Duration getFastestLoadTime() {
    if (_loadTimes.isEmpty) return Duration.zero;

    return _loadTimes.reduce(
      (a, b) => a.inMilliseconds < b.inMilliseconds ? a : b,
    );
  }

  /// 获取最慢加载时间
  Duration getSlowestLoadTime() {
    if (_loadTimes.isEmpty) return Duration.zero;

    return _loadTimes.reduce(
      (a, b) => a.inMilliseconds > b.inMilliseconds ? a : b,
    );
  }

  /// 获取最常请求的图片
  List<MapEntry<String, int>> getMostRequestedImages({int limit = 10}) {
    final sortedEntries = _imageRequests.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.take(limit).toList();
  }

  /// 获取会话时长
  Duration getSessionDuration() {
    if (_sessionStartTime == null) return Duration.zero;
    return DateTime.now().difference(_sessionStartTime!);
  }

  /// 获取性能报告
  Map<String, dynamic> getPerformanceReport() {
    return {
      'sessionDuration': getSessionDuration(),
      'totalRequests': _totalRequests,
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'hitRate': getCacheHitRate(),
      'averageLoadTime': getAverageLoadTime(),
      'fastestLoadTime': getFastestLoadTime(),
      'slowestLoadTime': getSlowestLoadTime(),
      'totalLoadTimes': _loadTimes.length,
      'mostRequestedImages': getMostRequestedImages(limit: 5),
      'sessionStartTime': _sessionStartTime,
    };
  }

  /// 打印性能报告
  void printPerformanceReport() {
    if (!kDebugMode) return;

    final report = getPerformanceReport();

    debugPrint('=== 图片缓存性能报告 ===');
    debugPrint('会话时长: ${_formatDuration(report['sessionDuration'])}');
    debugPrint('总请求数: ${report['totalRequests']}');
    debugPrint('缓存命中: ${report['cacheHits']}');
    debugPrint('缓存未命中: ${report['cacheMisses']}');
    debugPrint('命中率: ${(report['hitRate'] * 100).toStringAsFixed(1)}%');
    debugPrint('平均加载时间: ${report['averageLoadTime'].inMilliseconds}ms');
    debugPrint('最快加载时间: ${report['fastestLoadTime'].inMilliseconds}ms');
    debugPrint('最慢加载时间: ${report['slowestLoadTime'].inMilliseconds}ms');

    final mostRequested =
        report['mostRequestedImages'] as List<MapEntry<String, int>>;
    if (mostRequested.isNotEmpty) {
      debugPrint('最常请求的图片:');
      for (final entry in mostRequested) {
        debugPrint('  ${entry.key}: ${entry.value}次');
      }
    }

    debugPrint('========================');
  }

  /// 重置统计数据
  void reset() {
    _cacheHits = 0;
    _cacheMisses = 0;
    _totalRequests = 0;
    _loadTimes.clear();
    _imageRequests.clear();
    _sessionStartTime = DateTime.now();

    debugPrint('性能监控数据已重置');
  }

  /// 格式化持续时间
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// 获取性能等级
  String getPerformanceGrade() {
    final hitRate = getCacheHitRate();
    final avgLoadTime = getAverageLoadTime().inMilliseconds;

    if (hitRate >= 0.9 && avgLoadTime <= 100) {
      return 'A+'; // 优秀
    } else if (hitRate >= 0.8 && avgLoadTime <= 200) {
      return 'A'; // 良好
    } else if (hitRate >= 0.7 && avgLoadTime <= 300) {
      return 'B'; // 中等
    } else if (hitRate >= 0.6 && avgLoadTime <= 500) {
      return 'C'; // 一般
    } else {
      return 'D'; // 需要优化
    }
  }

  /// 获取优化建议
  List<String> getOptimizationSuggestions() {
    final suggestions = <String>[];
    final hitRate = getCacheHitRate();
    final avgLoadTime = getAverageLoadTime().inMilliseconds;

    if (hitRate < 0.7) {
      suggestions.add('缓存命中率较低，考虑增加缓存大小或预加载常用图片');
    }

    if (avgLoadTime > 300) {
      suggestions.add('平均加载时间较长，考虑降低图片质量或优化压缩算法');
    }

    if (_totalRequests > 1000 && _loadTimes.length < _totalRequests * 0.8) {
      suggestions.add('部分图片加载时间未记录，检查监控覆盖率');
    }

    final mostRequested = getMostRequestedImages(limit: 3);
    if (mostRequested.isNotEmpty && mostRequested.first.value > 10) {
      suggestions.add('考虑为高频访问图片 "${mostRequested.first.key}" 设置更高的缓存优先级');
    }

    if (suggestions.isEmpty) {
      suggestions.add('缓存性能良好，继续保持当前配置');
    }

    return suggestions;
  }
}
