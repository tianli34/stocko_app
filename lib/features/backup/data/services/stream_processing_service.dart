import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:drift/drift.dart';

import '../../../../core/database/database.dart';
import '../../domain/models/performance_metrics.dart';
import '../../domain/models/backup_exception.dart';
import '../../domain/models/backup_error_type.dart';
import '../../domain/services/i_performance_service.dart';
import 'performance_service.dart';

/// 流式处理服务实现
class StreamProcessingService implements IStreamProcessingService {
  final AppDatabase _database;
  final IPerformanceService _performanceService;

  StreamProcessingService(
    this._database, {
    IPerformanceService? performanceService,
  }) : _performanceService = performanceService ?? PerformanceService();

  @override
  Stream<List<Map<String, dynamic>>> streamExportTable(
    String tableName,
    StreamProcessingConfig config, {
    void Function(List<Map<String, dynamic>> batch)? onBatch,
    void Function(int processed, int total)? onProgress,
  }) async* {
    final operationId = 'stream_export_${tableName}_${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      // 获取表的总记录数
      final totalCount = await _getTableCount(tableName);
      
      // 开始性能监控
      await _performanceService.startMonitoring(operationId, totalCount);
      
      int offset = 0;
      int processedRecords = 0;
      bool hasMoreData = true;

      developer.log(
        'Starting stream export for table: $tableName, total records: $totalCount',
        name: 'StreamProcessingService',
      );

      while (hasMoreData) {
        // 检查内存使用情况
        if (config.enableMemoryMonitoring) {
          await _checkMemoryUsage(operationId, config);
        }

        // 获取批次数据
        final batch = await _exportTableBatch(tableName, offset, config.batchSize);
        
        if (batch.isEmpty) {
          hasMoreData = false;
          break;
        }

        // 更新进度
        processedRecords += batch.length;
        await _performanceService.updateProgress(operationId, processedRecords);
        onProgress?.call(processedRecords, totalCount);

        // 调用批处理回调
        onBatch?.call(batch);

        // 返回批次数据
        yield batch;

        // 检查是否还有更多数据
        hasMoreData = batch.length == config.batchSize;
        offset += config.batchSize;

        // 如果启用了内存监控，在处理大批次后可能需要暂停
        if (config.enableMemoryMonitoring && processedRecords % (config.batchSize * 10) == 0) {
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }

      // 结束性能监控
      final metrics = await _performanceService.endMonitoring(operationId);
      developer.log(
        'Completed stream export for table: $tableName\n'
        'Processed: $processedRecords records in ${metrics.durationSeconds}s',
        name: 'StreamProcessingService',
      );

    } catch (e) {
      developer.log(
        'Error in stream export for table: $tableName - $e',
        name: 'StreamProcessingService',
      );
      
      throw BackupException(
        type: BackupErrorType.databaseError,
        message: '流式导出表 $tableName 失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<int> streamImportTable(
    String tableName,
    Stream<List<Map<String, dynamic>>> dataStream,
    StreamProcessingConfig config, {
    void Function(int processed, int total)? onProgress,
  }) async {
    final operationId = 'stream_import_${tableName}_${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      int totalProcessed = 0;
      int batchCount = 0;

      developer.log(
        'Starting stream import for table: $tableName',
        name: 'StreamProcessingService',
      );

      // 开始性能监控（总数未知，使用0）
      await _performanceService.startMonitoring(operationId, 0);

      await for (final batch in dataStream) {
        if (batch.isEmpty) continue;

        // 检查内存使用情况
        if (config.enableMemoryMonitoring) {
          await _checkMemoryUsage(operationId, config);
        }

        // 导入批次数据
        await _importTableBatch(tableName, batch);
        
        totalProcessed += batch.length;
        batchCount++;

        // 更新进度
        await _performanceService.updateProgress(operationId, totalProcessed);
        onProgress?.call(totalProcessed, totalProcessed); // 总数未知，使用已处理数

        // 定期暂停以避免阻塞UI
        if (batchCount % 10 == 0) {
          await Future.delayed(const Duration(milliseconds: 5));
        }
      }

      // 结束性能监控
      final metrics = await _performanceService.endMonitoring(operationId);
      developer.log(
        'Completed stream import for table: $tableName\n'
        'Processed: $totalProcessed records in ${metrics.durationSeconds}s',
        name: 'StreamProcessingService',
      );

      return totalProcessed;

    } catch (e) {
      developer.log(
        'Error in stream import for table: $tableName - $e',
        name: 'StreamProcessingService',
      );
      
      throw BackupException(
        type: BackupErrorType.databaseError,
        message: '流式导入表 $tableName 失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Stream<String> streamJsonSerialize(
    Map<String, dynamic> data,
    StreamProcessingConfig config,
  ) async* {
    final operationId = 'stream_serialize_${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      // 开始性能监控
      await _performanceService.startMonitoring(operationId, data.length);

      // 开始JSON对象
      yield '{\n';

      bool isFirst = true;
      int processedEntries = 0;

      for (final entry in data.entries) {
        // 检查内存使用情况
        if (config.enableMemoryMonitoring && processedEntries % 100 == 0) {
          await _checkMemoryUsage(operationId, config);
        }

        if (!isFirst) {
          yield ',\n';
        }
        isFirst = false;

        // 序列化键
        final keyJson = jsonEncode(entry.key);
        yield '  $keyJson: ';

        // 序列化值
        if (entry.value is List) {
          yield* _streamSerializeList(entry.value as List, config);
        } else if (entry.value is Map) {
          yield* _streamSerializeMap(entry.value as Map<String, dynamic>, config);
        } else {
          yield jsonEncode(entry.value);
        }

        processedEntries++;
        await _performanceService.updateProgress(operationId, processedEntries);

        // 定期暂停
        if (processedEntries % 50 == 0) {
          await Future.delayed(const Duration(milliseconds: 1));
        }
      }

      // 结束JSON对象
      yield '\n}';

      // 结束性能监控
      await _performanceService.endMonitoring(operationId);

    } catch (e) {
      throw BackupException(
        type: BackupErrorType.serializationError,
        message: '流式JSON序列化失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> streamJsonDeserialize(
    Stream<String> jsonStream,
    StreamProcessingConfig config,
  ) async {
    final operationId = 'stream_deserialize_${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      // 开始性能监控
      await _performanceService.startMonitoring(operationId, 0);

      final buffer = StringBuffer();
      int chunkCount = 0;

      // 收集所有JSON数据
      await for (final chunk in jsonStream) {
        buffer.write(chunk);
        chunkCount++;

        // 检查内存使用情况
        if (config.enableMemoryMonitoring && chunkCount % 100 == 0) {
          await _checkMemoryUsage(operationId, config);
        }

        // 定期暂停
        if (chunkCount % 50 == 0) {
          await Future.delayed(const Duration(milliseconds: 1));
        }
      }

      // 解析JSON
      final jsonString = buffer.toString();
      final result = jsonDecode(jsonString) as Map<String, dynamic>;

      // 结束性能监控
      await _performanceService.endMonitoring(operationId);

      return result;

    } catch (e) {
      throw BackupException(
        type: BackupErrorType.serializationError,
        message: '流式JSON反序列化失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// 流式序列化列表
  Stream<String> _streamSerializeList(
    List list,
    StreamProcessingConfig config,
  ) async* {
    yield '[\n';

    for (int i = 0; i < list.length; i++) {
      if (i > 0) {
        yield ',\n';
      }

      yield '    ';
      
      if (list[i] is Map) {
        yield* _streamSerializeMap(list[i] as Map<String, dynamic>, config, indent: '    ');
      } else {
        yield jsonEncode(list[i]);
      }

      // 定期暂停
      if (i % 100 == 0) {
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }

    yield '\n  ]';
  }

  /// 流式序列化映射
  Stream<String> _streamSerializeMap(
    Map<String, dynamic> map,
    StreamProcessingConfig config, {
    String indent = '  ',
  }) async* {
    yield '{\n';

    bool isFirst = true;
    for (final entry in map.entries) {
      if (!isFirst) {
        yield ',\n';
      }
      isFirst = false;

      final keyJson = jsonEncode(entry.key);
      yield '$indent  $keyJson: ${jsonEncode(entry.value)}';
    }

    yield '\n$indent}';
  }

  /// 获取表记录数
  Future<int> _getTableCount(String tableName) async {
    try {
      final query = 'SELECT COUNT(*) as count FROM $tableName';
      final result = await _database.customSelect(query).getSingle();
      return result.data['count'] as int;
    } catch (e) {
      throw BackupException(
        type: BackupErrorType.databaseError,
        message: '获取表 $tableName 记录数失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// 分批导出表数据
  Future<List<Map<String, dynamic>>> _exportTableBatch(
    String tableName,
    int offset,
    int limit,
  ) async {
    try {
      final query = 'SELECT * FROM $tableName LIMIT $limit OFFSET $offset';
      final result = await _database.customSelect(query).get();
      return result.map((row) => row.data).toList();
    } catch (e) {
      throw BackupException(
        type: BackupErrorType.databaseError,
        message: '分批导出表 $tableName 失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// 分批导入表数据
  Future<void> _importTableBatch(
    String tableName,
    List<Map<String, dynamic>> records,
  ) async {
    try {
      await _database.transaction(() async {
        for (final record in records) {
          final columns = record.keys.join(', ');
          final placeholders = record.keys.map((_) => '?').join(', ');
          final values = record.values.map((v) => Variable(v)).toList();
          
          final query = 'INSERT OR REPLACE INTO $tableName ($columns) VALUES ($placeholders)';
          await _database.customStatement(query, values);
        }
      });
    } catch (e) {
      throw BackupException(
        type: BackupErrorType.databaseError,
        message: '分批导入表 $tableName 失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// 检查内存使用情况
  Future<void> _checkMemoryUsage(
    String operationId,
    StreamProcessingConfig config,
  ) async {
    try {
      await _performanceService.recordMemoryUsage(operationId);
      
      final shouldGC = await _performanceService.shouldTriggerGC();
      if (shouldGC) {
        developer.log(
          'Memory usage high, triggering GC for operation: $operationId',
          name: 'StreamProcessingService',
        );
        await _performanceService.triggerGC();
      }

      // 检查是否超过最大内存限制
      final currentMemory = await _performanceService.getCurrentMemoryUsage();
      if (currentMemory.currentBytes > config.maxMemoryUsage) {
        developer.log(
          'Memory usage exceeded limit: ${currentMemory.currentMB}MB > ${config.maxMemoryUsage / (1024 * 1024)}MB',
          name: 'StreamProcessingService',
        );
        
        // 强制垃圾回收并等待
        await _performanceService.triggerGC();
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      developer.log(
        'Error checking memory usage: $e',
        name: 'StreamProcessingService',
      );
    }
  }
}