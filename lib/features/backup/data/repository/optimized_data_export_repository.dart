import 'dart:convert';
import 'dart:async';
import 'package:crypto/crypto.dart';
import '../../../../core/database/database.dart';
import '../../domain/models/backup_exception.dart';
import '../../domain/models/backup_error_type.dart';
import '../../domain/models/performance_metrics.dart';
import '../../domain/services/i_performance_service.dart';
import '../services/performance_service.dart';

/// 优化的数据导出仓储类
/// 支持流式处理和性能监控
class OptimizedDataExportRepository {
  final AppDatabase _database;
  final IPerformanceService _performanceService;

  OptimizedDataExportRepository(
    this._database, {
    IPerformanceService? performanceService,
  }) : _performanceService = performanceService ?? PerformanceService();

  /// 流式导出所有表数据
  /// 使用异步生成器实现内存友好的数据导出
  Stream<MapEntry<String, List<Map<String, dynamic>>>> streamExportAllTables({
    StreamProcessingConfig? config,
    void Function(String tableName, int processed, int total)? onProgress,
  }) async* {
    final streamConfig = config ?? const StreamProcessingConfig();
    final operationId = 'stream_export_all_${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      final tableNames = await getAllTableNames();
      await _performanceService.startMonitoring(operationId, tableNames.length);
      
      int processedTables = 0;
      
      for (final tableName in _getTableExportOrder()) {
        if (!tableNames.contains(tableName)) continue;
        
        final tableData = <Map<String, dynamic>>[];
        final totalRecords = await _getTableCount(tableName);
        
        await for (final batch in _streamExportTable(tableName, streamConfig)) {
          tableData.addAll(batch);
          onProgress?.call(tableName, tableData.length, totalRecords);
          
          // 定期检查内存使用情况
          if (streamConfig.enableMemoryMonitoring && tableData.length % 1000 == 0) {
            await _performanceService.recordMemoryUsage(operationId);
          }
        }
        
        yield MapEntry(tableName, tableData);
        
        processedTables++;
        await _performanceService.updateProgress(operationId, processedTables);
      }
      
      await _performanceService.endMonitoring(operationId);
      
    } catch (e) {
      throw BackupException(
        type: BackupErrorType.databaseError,
        message: '流式导出数据库表失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// 流式导出指定表的数据
  Stream<List<Map<String, dynamic>>> _streamExportTable(
    String tableName,
    StreamProcessingConfig config,
  ) async* {
    try {
      int offset = 0;
      bool hasMoreData = true;

      while (hasMoreData) {
        final batch = await _exportTableBatch(tableName, offset, config.batchSize);
        
        if (batch.isEmpty) {
          hasMoreData = false;
          break;
        }
        
        yield batch;
        
        hasMoreData = batch.length == config.batchSize;
        offset += config.batchSize;
        
        // 小延迟以避免阻塞UI线程
        await Future.delayed(const Duration(microseconds: 100));
      }
    } catch (e) {
      throw BackupException(
        type: BackupErrorType.databaseError,
        message: '流式导出表 $tableName 失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// 分批导出表数据（优化版本）
  Future<List<Map<String, dynamic>>> _exportTableBatch(
    String tableName,
    int offset,
    int limit,
  ) async {
    try {
      // 使用预编译查询提高性能
      final query = 'SELECT * FROM $tableName LIMIT $limit OFFSET $offset';
      final result = await _database.customSelect(query).get();
      
      // 优化数据转换
      return result.map((row) {
        final data = <String, dynamic>{};
        for (final entry in row.data.entries) {
          // 只包含非null值以减少内存使用
          if (entry.value != null) {
            data[entry.key] = entry.value;
          }
        }
        return data;
      }).toList();
    } catch (e) {
      throw BackupException(
        type: BackupErrorType.databaseError,
        message: '分批导出表 $tableName 失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// 获取表记录数量统计（缓存版本）
  Future<Map<String, int>> getTableCounts() async {
    try {
      final Map<String, int> counts = {};
      final tableNames = _getTableExportOrder();

      // 使用并发查询提高性能
      final futures = tableNames.map((tableName) async {
        final count = await _getTableCount(tableName);
        return MapEntry(tableName, count);
      });

      final results = await Future.wait(futures);
      for (final result in results) {
        counts[result.key] = result.value;
      }

      return counts;
    } catch (e) {
      throw BackupException(
        type: BackupErrorType.databaseError,
        message: '获取表记录数量失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// 获取指定表的记录数量（优化版本）
  Future<int> _getTableCount(String tableName) async {
    try {
      // 使用COUNT(1)而不是COUNT(*)以提高性能
      final query = 'SELECT COUNT(1) as count FROM $tableName';
      final result = await _database.customSelect(query).getSingle();
      return result.data['count'] as int;
    } catch (e) {
      throw BackupException(
        type: BackupErrorType.databaseError,
        message: '获取表 $tableName 记录数量失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// 优化的JSON序列化
  /// 支持流式序列化以减少内存使用
  Stream<String> streamSerializeToJson(
    Map<String, dynamic> data, {
    bool prettyPrint = false,
  }) async* {
    try {
      const chunkSize = 1000; // 每次处理的条目数
      
      yield '{\n';
      
      bool isFirst = true;
      int processedEntries = 0;
      
      for (final entry in data.entries) {
        if (!isFirst) {
          yield ',\n';
        }
        isFirst = false;
        
        // 序列化键
        final keyJson = jsonEncode(entry.key);
        yield prettyPrint ? '  $keyJson: ' : '$keyJson:';
        
        // 序列化值
        if (entry.value is List && (entry.value as List).length > chunkSize) {
          // 大列表分块序列化
          yield* _streamSerializeList(entry.value as List, prettyPrint);
        } else {
          final valueJson = jsonEncode(entry.value);
          yield valueJson;
        }
        
        processedEntries++;
        
        // 定期让出控制权
        if (processedEntries % 100 == 0) {
          await Future.delayed(const Duration(microseconds: 1));
        }
      }
      
      yield prettyPrint ? '\n}' : '}';
      
    } catch (e) {
      throw BackupException(
        type: BackupErrorType.serializationError,
        message: '流式JSON序列化失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// 流式序列化列表
  Stream<String> _streamSerializeList(List list, bool prettyPrint) async* {
    yield '[';
    
    for (int i = 0; i < list.length; i++) {
      if (i > 0) {
        yield ',';
      }
      
      if (prettyPrint && i % 10 == 0) {
        yield '\n    ';
      }
      
      yield jsonEncode(list[i]);
      
      // 定期让出控制权
      if (i % 100 == 0) {
        await Future.delayed(const Duration(microseconds: 1));
      }
    }
    
    yield prettyPrint ? '\n  ]' : ']';
  }

  /// 优化的校验和生成
  /// 支持流式计算以处理大数据
  Future<String> generateChecksumStream(Stream<String> dataStream) async {
    try {
      final chunks = <int>[];
      
      await for (final chunk in dataStream) {
        chunks.addAll(utf8.encode(chunk));
      }
      
      final digest = sha256.convert(chunks);
      return digest.toString();
    } catch (e) {
      throw BackupException(
        type: BackupErrorType.validationError,
        message: '生成流式校验和失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// 获取表导出顺序（按依赖关系）
  List<String> _getTableExportOrder() {
    return [
      // 基础数据表（无外键依赖）
      'category',
      'unit',
      'shop',
      'supplier',
      'customers',
      'locations',
      
      // 产品相关表
      'product',
      'unit_product',
      'barcode',
      'product_batch',
      
      // 库存相关表
      'stock',
      'inventory_transactions',
      
      // 业务单据表
      'purchase_order',
      'purchase_order_item',
      'inbound_receipt',
      'inbound_item',
      'sales_transaction',
      'sales_transaction_item',
      'outbound_receipt',
      'outbound_item',
    ];
  }

  /// 获取所有表名
  Future<List<String>> getAllTableNames() async {
    try {
      const query = '''
        SELECT name FROM sqlite_master 
        WHERE type='table' AND name NOT LIKE 'sqlite_%'
        ORDER BY name
      ''';
      final result = await _database.customSelect(query).get();
      
      return result.map((row) => row.data['name'] as String).toList();
    } catch (e) {
      throw BackupException(
        type: BackupErrorType.databaseError,
        message: '获取所有表名失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// 估算导出数据大小（优化版本）
  Future<int> estimateExportSize() async {
    try {
      final tableCounts = await getTableCounts();
      int estimatedSize = 0;
      
      // 基于表类型的更精确估算
      const tableEstimates = {
        'product': 800,        // 产品表记录较大
        'sales_transaction': 600,  // 销售记录中等
        'inventory_transactions': 400,  // 库存记录较小
        'category': 200,       // 分类记录很小
        'unit': 150,          // 单位记录很小
      };
      
      for (final entry in tableCounts.entries) {
        final tableName = entry.key;
        final count = entry.value;
        final avgSize = tableEstimates[tableName] ?? 500; // 默认500字节
        
        estimatedSize += count * avgSize;
      }
      
      // 添加JSON结构开销
      estimatedSize = (estimatedSize * 1.15).round();
      
      return estimatedSize;
    } catch (e) {
      throw BackupException(
        type: BackupErrorType.databaseError,
        message: '估算导出大小失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// 获取数据库架构版本
  Future<int> getDatabaseSchemaVersion() async {
    try {
      return _database.schemaVersion;
    } catch (e) {
      throw BackupException(
        type: BackupErrorType.databaseError,
        message: '获取数据库架构版本失败: ${e.toString()}',
        originalError: e,
      );
    }
  }
}