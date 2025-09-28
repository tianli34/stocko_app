/// 性能指标数据模型
class PerformanceMetrics {
  final DateTime startTime;
  final DateTime endTime;
  final int totalRecords;
  final int processedRecords;
  final int memoryUsageBytes;
  final int peakMemoryUsageBytes;
  final double processingRatePerSecond;
  final int compressionRatio;
  final int streamBufferSize;
  final Map<String, dynamic>? additionalMetrics;

  const PerformanceMetrics({
    required this.startTime,
    required this.endTime,
    required this.totalRecords,
    required this.processedRecords,
    required this.memoryUsageBytes,
    required this.peakMemoryUsageBytes,
    required this.processingRatePerSecond,
    this.compressionRatio = 0,
    this.streamBufferSize = 0,
    this.additionalMetrics,
  });

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      totalRecords: json['totalRecords'] as int,
      processedRecords: json['processedRecords'] as int,
      memoryUsageBytes: json['memoryUsageBytes'] as int,
      peakMemoryUsageBytes: json['peakMemoryUsageBytes'] as int,
      processingRatePerSecond: (json['processingRatePerSecond'] as num).toDouble(),
      compressionRatio: json['compressionRatio'] as int? ?? 0,
      streamBufferSize: json['streamBufferSize'] as int? ?? 0,
      additionalMetrics: json['additionalMetrics'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'totalRecords': totalRecords,
      'processedRecords': processedRecords,
      'memoryUsageBytes': memoryUsageBytes,
      'peakMemoryUsageBytes': peakMemoryUsageBytes,
      'processingRatePerSecond': processingRatePerSecond,
      'compressionRatio': compressionRatio,
      'streamBufferSize': streamBufferSize,
      'additionalMetrics': additionalMetrics,
    };
  }

  /// 计算总耗时（毫秒）
  int get durationMs => endTime.difference(startTime).inMilliseconds;

  /// 计算总耗时（秒）
  double get durationSeconds => durationMs / 1000.0;

  /// 计算内存使用量（MB）
  double get memoryUsageMB => memoryUsageBytes / (1024 * 1024);

  /// 计算峰值内存使用量（MB）
  double get peakMemoryUsageMB => peakMemoryUsageBytes / (1024 * 1024);

  /// 计算完成百分比
  double get completionPercentage => 
      totalRecords > 0 ? (processedRecords / totalRecords) * 100 : 0;
}

/// 流式处理配置
class StreamProcessingConfig {
  final int batchSize;
  final int bufferSize;
  final int maxMemoryUsage; // 50MB
  final bool enableCompression;
  final int compressionLevel;
  final bool enableMemoryMonitoring;
  final int memoryCheckIntervalMs;

  const StreamProcessingConfig({
    this.batchSize = 1000,
    this.bufferSize = 8192,
    this.maxMemoryUsage = 50 * 1024 * 1024, // 50MB
    this.enableCompression = true,
    this.compressionLevel = 6,
    this.enableMemoryMonitoring = true,
    this.memoryCheckIntervalMs = 5000,
  });

  factory StreamProcessingConfig.fromJson(Map<String, dynamic> json) {
    return StreamProcessingConfig(
      batchSize: json['batchSize'] as int? ?? 1000,
      bufferSize: json['bufferSize'] as int? ?? 8192,
      maxMemoryUsage: json['maxMemoryUsage'] as int? ?? 50 * 1024 * 1024,
      enableCompression: json['enableCompression'] as bool? ?? true,
      compressionLevel: json['compressionLevel'] as int? ?? 6,
      enableMemoryMonitoring: json['enableMemoryMonitoring'] as bool? ?? true,
      memoryCheckIntervalMs: json['memoryCheckIntervalMs'] as int? ?? 5000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batchSize': batchSize,
      'bufferSize': bufferSize,
      'maxMemoryUsage': maxMemoryUsage,
      'enableCompression': enableCompression,
      'compressionLevel': compressionLevel,
      'enableMemoryMonitoring': enableMemoryMonitoring,
      'memoryCheckIntervalMs': memoryCheckIntervalMs,
    };
  }
}

/// 内存使用情况
class MemoryUsage {
  final int currentBytes;
  final int peakBytes;
  final DateTime timestamp;
  final int availableBytes;
  final int gcCount;

  const MemoryUsage({
    required this.currentBytes,
    required this.peakBytes,
    required this.timestamp,
    this.availableBytes = 0,
    this.gcCount = 0,
  });

  factory MemoryUsage.fromJson(Map<String, dynamic> json) {
    return MemoryUsage(
      currentBytes: json['currentBytes'] as int,
      peakBytes: json['peakBytes'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      availableBytes: json['availableBytes'] as int? ?? 0,
      gcCount: json['gcCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentBytes': currentBytes,
      'peakBytes': peakBytes,
      'timestamp': timestamp.toIso8601String(),
      'availableBytes': availableBytes,
      'gcCount': gcCount,
    };
  }

  /// 当前内存使用量（MB）
  double get currentMB => currentBytes / (1024 * 1024);

  /// 峰值内存使用量（MB）
  double get peakMB => peakBytes / (1024 * 1024);

  /// 可用内存（MB）
  double get availableMB => availableBytes / (1024 * 1024);
}

/// 压缩统计信息
class CompressionStats {
  final int originalSize;
  final int compressedSize;
  final double compressionRatio;
  final Duration compressionTime;
  final String algorithm;

  const CompressionStats({
    required this.originalSize,
    required this.compressedSize,
    required this.compressionRatio,
    required this.compressionTime,
    required this.algorithm,
  });

  factory CompressionStats.fromJson(Map<String, dynamic> json) {
    return CompressionStats(
      originalSize: json['originalSize'] as int,
      compressedSize: json['compressedSize'] as int,
      compressionRatio: (json['compressionRatio'] as num).toDouble(),
      compressionTime: Duration(milliseconds: json['compressionTimeMs'] as int),
      algorithm: json['algorithm'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalSize': originalSize,
      'compressedSize': compressedSize,
      'compressionRatio': compressionRatio,
      'compressionTimeMs': compressionTime.inMilliseconds,
      'algorithm': algorithm,
    };
  }

  /// 压缩节省的空间（字节）
  int get spaceSaved => originalSize - compressedSize;

  /// 压缩节省的空间（MB）
  double get spaceSavedMB => spaceSaved / (1024 * 1024);

  /// 压缩效率（每秒处理的字节数）
  double get compressionSpeed => 
      compressionTime.inMilliseconds > 0 
          ? originalSize / (compressionTime.inMilliseconds / 1000.0)
          : 0;
}