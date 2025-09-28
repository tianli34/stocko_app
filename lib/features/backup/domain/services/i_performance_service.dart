import '../models/performance_metrics.dart';

/// 性能监控服务接口
abstract class IPerformanceService {
  /// 开始性能监控
  /// [operationId] 操作标识符
  /// [totalRecords] 预期处理的总记录数
  Future<void> startMonitoring(String operationId, int totalRecords);

  /// 更新处理进度
  /// [operationId] 操作标识符
  /// [processedRecords] 已处理的记录数
  Future<void> updateProgress(String operationId, int processedRecords);

  /// 记录内存使用情况
  /// [operationId] 操作标识符
  Future<void> recordMemoryUsage(String operationId);

  /// 结束性能监控
  /// [operationId] 操作标识符
  Future<PerformanceMetrics> endMonitoring(String operationId);

  /// 获取当前内存使用情况
  Future<MemoryUsage> getCurrentMemoryUsage();

  /// 检查是否需要进行垃圾回收
  Future<bool> shouldTriggerGC();

  /// 触发垃圾回收
  Future<void> triggerGC();

  /// 获取性能建议
  /// [metrics] 性能指标
  List<String> getPerformanceRecommendations(PerformanceMetrics metrics);
}

/// 流式处理服务接口
abstract class IStreamProcessingService {
  /// 流式导出数据
  /// [tableName] 表名
  /// [config] 流式处理配置
  /// [onBatch] 批处理回调
  /// [onProgress] 进度回调
  Stream<List<Map<String, dynamic>>> streamExportTable(
    String tableName,
    StreamProcessingConfig config, {
    void Function(List<Map<String, dynamic>> batch)? onBatch,
    void Function(int processed, int total)? onProgress,
  });

  /// 流式导入数据
  /// [tableName] 表名
  /// [dataStream] 数据流
  /// [config] 流式处理配置
  /// [onProgress] 进度回调
  Future<int> streamImportTable(
    String tableName,
    Stream<List<Map<String, dynamic>>> dataStream,
    StreamProcessingConfig config, {
    void Function(int processed, int total)? onProgress,
  });

  /// 流式JSON序列化
  /// [data] 要序列化的数据
  /// [config] 流式处理配置
  Stream<String> streamJsonSerialize(
    Map<String, dynamic> data,
    StreamProcessingConfig config,
  );

  /// 流式JSON反序列化
  /// [jsonStream] JSON数据流
  /// [config] 流式处理配置
  Future<Map<String, dynamic>> streamJsonDeserialize(
    Stream<String> jsonStream,
    StreamProcessingConfig config,
  );
}

/// 压缩服务接口
abstract class ICompressionService {
  /// 压缩数据
  /// [data] 要压缩的数据
  /// [level] 压缩级别 (1-9)
  Future<CompressionResult> compressData(List<int> data, {int level = 6});

  /// 解压数据
  /// [compressedData] 压缩的数据
  Future<List<int>> decompressData(List<int> compressedData);

  /// 压缩文件
  /// [inputPath] 输入文件路径
  /// [outputPath] 输出文件路径
  /// [level] 压缩级别
  Future<CompressionStats> compressFile(
    String inputPath,
    String outputPath, {
    int level = 6,
  });

  /// 解压文件
  /// [inputPath] 压缩文件路径
  /// [outputPath] 输出文件路径
  Future<void> decompressFile(String inputPath, String outputPath);

  /// 检查文件是否已压缩
  /// [filePath] 文件路径
  Future<bool> isCompressed(String filePath);
}

/// 压缩结果
class CompressionResult {
  final List<int> compressedData;
  final CompressionStats stats;

  const CompressionResult({
    required this.compressedData,
    required this.stats,
  });
}