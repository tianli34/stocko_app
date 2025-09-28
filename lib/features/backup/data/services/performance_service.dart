import 'dart:io';
import 'dart:developer' as developer;

import '../../domain/models/performance_metrics.dart';
import '../../domain/services/i_performance_service.dart';

/// 性能监控服务实现
class PerformanceService implements IPerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final Map<String, _OperationMetrics> _activeOperations = {};
  final Map<String, List<MemoryUsage>> _memoryHistory = {};

  @override
  Future<void> startMonitoring(String operationId, int totalRecords) async {
    final now = DateTime.now();
    final initialMemory = await getCurrentMemoryUsage();
    
    _activeOperations[operationId] = _OperationMetrics(
      operationId: operationId,
      startTime: now,
      totalRecords: totalRecords,
      processedRecords: 0,
      initialMemory: initialMemory,
      peakMemory: initialMemory,
    );
    
    _memoryHistory[operationId] = [initialMemory];
    
    developer.log(
      'Started performance monitoring for operation: $operationId',
      name: 'PerformanceService',
    );
  }

  @override
  Future<void> updateProgress(String operationId, int processedRecords) async {
    final operation = _activeOperations[operationId];
    if (operation == null) return;

    operation.processedRecords = processedRecords;
    operation.lastUpdateTime = DateTime.now();

    // 记录内存使用情况
    await recordMemoryUsage(operationId);

    // 计算处理速率
    final elapsed = operation.lastUpdateTime.difference(operation.startTime);
    if (elapsed.inMilliseconds > 0) {
      operation.processingRate = processedRecords / (elapsed.inMilliseconds / 1000.0);
    }
  }

  @override
  Future<void> recordMemoryUsage(String operationId) async {
    final operation = _activeOperations[operationId];
    if (operation == null) return;

    final currentMemory = await getCurrentMemoryUsage();
    
    // 更新峰值内存
    if (currentMemory.currentBytes > operation.peakMemory.currentBytes) {
      operation.peakMemory = currentMemory;
    }

    // 添加到历史记录
    final history = _memoryHistory[operationId] ?? [];
    history.add(currentMemory);
    
    // 保持最近100个记录
    if (history.length > 100) {
      history.removeAt(0);
    }
    
    _memoryHistory[operationId] = history;
  }

  @override
  Future<PerformanceMetrics> endMonitoring(String operationId) async {
    final operation = _activeOperations[operationId];
    if (operation == null) {
      throw ArgumentError('Operation $operationId not found');
    }

    final endTime = DateTime.now();
    final finalMemory = await getCurrentMemoryUsage();

    final metrics = PerformanceMetrics(
      startTime: operation.startTime,
      endTime: endTime,
      totalRecords: operation.totalRecords,
      processedRecords: operation.processedRecords,
      memoryUsageBytes: finalMemory.currentBytes,
      peakMemoryUsageBytes: operation.peakMemory.currentBytes,
      processingRatePerSecond: operation.processingRate,
      additionalMetrics: {
        'initialMemoryMB': operation.initialMemory.currentMB,
        'finalMemoryMB': finalMemory.currentMB,
        'memoryGrowthMB': finalMemory.currentMB - operation.initialMemory.currentMB,
        'gcCount': finalMemory.gcCount - operation.initialMemory.gcCount,
      },
    );

    // 清理资源
    _activeOperations.remove(operationId);
    _memoryHistory.remove(operationId);

    developer.log(
      'Completed performance monitoring for operation: $operationId\n'
      'Duration: ${metrics.durationSeconds}s, '
      'Rate: ${metrics.processingRatePerSecond.toStringAsFixed(1)} records/s, '
      'Peak Memory: ${metrics.peakMemoryUsageMB.toStringAsFixed(1)}MB',
      name: 'PerformanceService',
    );

    return metrics;
  }

  @override
  Future<MemoryUsage> getCurrentMemoryUsage() async {
    try {
      // 获取当前进程的内存信息
      final info = ProcessInfo.currentRss;
      final timestamp = DateTime.now();
      
      // 尝试获取更详细的内存信息
      int availableMemory = 0;
      int gcCount = 0;
      
      try {
        // 获取垃圾回收统计信息（简化版本）
        // 在实际应用中可以使用更复杂的内存监控
        gcCount = 0; // 暂时设为0，避免API兼容性问题
      } catch (e) {
        // 忽略获取GC统计信息的错误
      }

      return MemoryUsage(
        currentBytes: info,
        peakBytes: info, // ProcessInfo.currentRss 已经是峰值
        timestamp: timestamp,
        availableBytes: availableMemory,
        gcCount: gcCount,
      );
    } catch (e) {
      // 如果无法获取内存信息，返回默认值
      return MemoryUsage(
        currentBytes: 0,
        peakBytes: 0,
        timestamp: DateTime.now(),
        availableBytes: 0,
        gcCount: 0,
      );
    }
  }

  @override
  Future<bool> shouldTriggerGC() async {
    try {
      final currentMemory = await getCurrentMemoryUsage();
      
      // 如果内存使用超过100MB，建议进行垃圾回收
      const memoryThreshold = 100 * 1024 * 1024; // 100MB
      
      return currentMemory.currentBytes > memoryThreshold;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> triggerGC() async {
    try {
      // 强制垃圾回收
      developer.log('Triggering garbage collection', name: 'PerformanceService');
      
      // 在Dart中，我们不能直接强制GC，但可以尝试一些方法
      // 创建一些临时对象然后释放，可能会触发GC
      final temp = List.generate(1000, (i) => List.filled(100, i));
      temp.clear();
      
      // 等待一小段时间让GC有机会运行
      await Future.delayed(const Duration(milliseconds: 10));
      
    } catch (e) {
      developer.log('Failed to trigger GC: $e', name: 'PerformanceService');
    }
  }

  @override
  List<String> getPerformanceRecommendations(PerformanceMetrics metrics) {
    final recommendations = <String>[];

    // 处理速度建议
    if (metrics.processingRatePerSecond < 100) {
      recommendations.add('处理速度较慢，建议增加批处理大小或优化数据库查询');
    }

    // 内存使用建议
    if (metrics.peakMemoryUsageMB > 200) {
      recommendations.add('内存使用量较高，建议启用流式处理或减少批处理大小');
    }

    // 耗时建议
    if (metrics.durationSeconds > 300) { // 5分钟
      recommendations.add('操作耗时较长，建议考虑分批处理或后台执行');
    }

    // 内存增长建议
    final memoryGrowth = metrics.additionalMetrics?['memoryGrowthMB'] as double? ?? 0;
    if (memoryGrowth > 50) {
      recommendations.add('内存增长较多，可能存在内存泄漏，建议检查资源释放');
    }

    // 垃圾回收建议
    final gcCount = metrics.additionalMetrics?['gcCount'] as int? ?? 0;
    if (gcCount > 10) {
      recommendations.add('垃圾回收频繁，建议优化对象创建和内存使用模式');
    }

    if (recommendations.isEmpty) {
      recommendations.add('性能表现良好，无需特别优化');
    }

    return recommendations;
  }

  /// 获取操作的内存使用历史
  List<MemoryUsage> getMemoryHistory(String operationId) {
    return _memoryHistory[operationId] ?? [];
  }

  /// 获取所有活跃操作
  List<String> getActiveOperations() {
    return _activeOperations.keys.toList();
  }

  /// 清理所有监控数据
  void clearAll() {
    _activeOperations.clear();
    _memoryHistory.clear();
  }
}

/// 内部操作指标类
class _OperationMetrics {
  final String operationId;
  final DateTime startTime;
  final int totalRecords;
  final MemoryUsage initialMemory;
  
  int processedRecords;
  DateTime lastUpdateTime;
  MemoryUsage peakMemory;
  double processingRate;

  _OperationMetrics({
    required this.operationId,
    required this.startTime,
    required this.totalRecords,
    required this.initialMemory,
    this.processedRecords = 0,
    DateTime? lastUpdateTime,
    MemoryUsage? peakMemory,
    this.processingRate = 0.0,
  }) : lastUpdateTime = lastUpdateTime ?? startTime,
       peakMemory = peakMemory ?? initialMemory;
}