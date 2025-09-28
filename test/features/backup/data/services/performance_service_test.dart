import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/backup/data/services/performance_service.dart';
import 'package:stocko_app/features/backup/domain/models/performance_metrics.dart';

void main() {
  group('PerformanceService', () {
    late PerformanceService performanceService;

    setUp(() {
      performanceService = PerformanceService();
    });

    tearDown(() {
      performanceService.clearAll();
    });

    test('should start and end monitoring correctly', () async {
      const operationId = 'test_operation';
      const totalRecords = 1000;

      // 开始监控
      await performanceService.startMonitoring(operationId, totalRecords);

      // 验证操作已开始
      expect(performanceService.getActiveOperations(), contains(operationId));

      // 更新进度
      await performanceService.updateProgress(operationId, 500);

      // 结束监控
      final metrics = await performanceService.endMonitoring(operationId);

      // 验证指标
      expect(metrics.totalRecords, equals(totalRecords));
      expect(metrics.processedRecords, equals(500));
      expect(metrics.durationMs, greaterThan(0));
      expect(performanceService.getActiveOperations(), isEmpty);
    });

    test('should record memory usage', () async {
      const operationId = 'memory_test';
      
      await performanceService.startMonitoring(operationId, 100);
      
      // 记录内存使用情况
      await performanceService.recordMemoryUsage(operationId);
      
      final memoryHistory = performanceService.getMemoryHistory(operationId);
      expect(memoryHistory, isNotEmpty);
      
      await performanceService.endMonitoring(operationId);
    });

    test('should get current memory usage', () async {
      final memoryUsage = await performanceService.getCurrentMemoryUsage();
      
      expect(memoryUsage.currentBytes, greaterThanOrEqualTo(0));
      expect(memoryUsage.timestamp, isNotNull);
    });

    test('should provide performance recommendations', () async {
      const operationId = 'recommendation_test';
      
      await performanceService.startMonitoring(operationId, 1000);
      await performanceService.updateProgress(operationId, 1000);
      
      final metrics = await performanceService.endMonitoring(operationId);
      final recommendations = performanceService.getPerformanceRecommendations(metrics);
      
      expect(recommendations, isNotEmpty);
      expect(recommendations, isA<List<String>>());
    });

    test('should handle multiple concurrent operations', () async {
      const operation1 = 'op1';
      const operation2 = 'op2';
      
      await performanceService.startMonitoring(operation1, 500);
      await performanceService.startMonitoring(operation2, 300);
      
      expect(performanceService.getActiveOperations(), hasLength(2));
      expect(performanceService.getActiveOperations(), containsAll([operation1, operation2]));
      
      await performanceService.endMonitoring(operation1);
      await performanceService.endMonitoring(operation2);
      
      expect(performanceService.getActiveOperations(), isEmpty);
    });

    test('should trigger GC when memory usage is high', () async {
      final shouldTrigger = await performanceService.shouldTriggerGC();
      expect(shouldTrigger, isA<bool>());
      
      // 测试触发GC（不会抛出异常）
      await performanceService.triggerGC();
    });
  });
}