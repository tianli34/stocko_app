import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../../core/database/database.dart';
import '../../domain/models/backup_data.dart';
import '../../domain/models/backup_metadata.dart';
import '../../domain/models/backup_options.dart';
import '../../domain/models/backup_exception.dart';
import '../../domain/models/performance_metrics.dart';
import '../../domain/common/backup_common.dart';
import '../../domain/services/i_backup_service.dart';
import '../../domain/services/i_performance_service.dart';
import '../repository/data_export_repository.dart';
import 'performance_service.dart';
import 'stream_processing_service.dart';
import 'compression_service.dart';

/// 优化的备份服务实现类
/// 支持流式处理、内存监控和压缩功能
class OptimizedBackupService implements IBackupService {
  final DataExportRepository _dataExportRepository;
  final IPerformanceService _performanceService;
  final StreamProcessingService _streamProcessingService;
  final CompressionService _compressionService;

  OptimizedBackupService(AppDatabase database) 
      : _dataExportRepository = DataExportRepository(database),
        _performanceService = PerformanceService(),
        _streamProcessingService = StreamProcessingService(database),
        _compressionService = CompressionService();

  @override
  Future<BackupResult> createBackup({
    BackupOptions? options,
    BackupProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    final operationId = 'optimized_backup_${DateTime.now().millisecondsSinceEpoch}';
    File? tempFile;
    
    try {
      final backupOptions = options ?? const BackupOptions();
      
      // 检查取消状态
      cancelToken?.throwIfCancelled();
      
      // 步骤1: 准备备份
      onProgress?.call('准备优化备份...', 0, 100);
      
      final backupId = _generateBackupId(backupOptions.customName);
      final backupDir = await _getBackupDirectory();
      final backupFilePath = path.join(backupDir.path, '$backupId.json');
      
      // 创建临时文件
      tempFile = File('${backupFilePath}.tmp');
      
      // 获取表统计信息用于性能监控
      final tableCounts = await _dataExportRepository.getTableCounts();
      final totalRecords = tableCounts.values.fold<int>(0, (sum, count) => sum + count);
      
      // 开始性能监控
      await _performanceService.startMonitoring(operationId, totalRecords);
      
      // 步骤2: 使用流式处理导出数据
      onProgress?.call('流式导出数据...', 10, 100);
      cancelToken?.throwIfCancelled();
      
      final streamConfig = StreamProcessingConfig(
        batchSize: _getOptimalBatchSize(totalRecords),
        enableCompression: backupOptions.compress ?? false,
        enableMemoryMonitoring: true,
      );
      
      final tablesData = await _streamExportAllTables(
        streamConfig,
        onProgress: (current, total) {
          final progressPercent = 10 + ((current / total) * 60).round();
          onProgress?.call('导出数据 ($current/$total)', progressPercent, 100);
        },
        cancelToken: cancelToken,
      );
      
      // 步骤3: 创建元数据
      onProgress?.call('生成备份元数据...', 70, 100);
      cancelToken?.throwIfCancelled();
      
      final metadata = await _createBackupMetadata(
        backupId,
        tableCounts,
        backupOptions,
      );
      
      // 步骤4: 创建备份数据结构
      final backupData = BackupData(
        metadata: metadata,
        tables: tablesData,
        settings: await _getAppSettings(),
      );
      
      // 步骤5: 优化的序列化和保存
      onProgress?.call('优化保存备份文件...', 80, 100);
      cancelToken?.throwIfCancelled();
      
      await _optimizedSaveBackupFile(
        backupData, 
        tempFile.path, 
        backupOptions,
        streamConfig,
      );
      
      // 步骤6: 验证备份文件
      onProgress?.call('验证备份文件...', 95, 100);
      cancelToken?.throwIfCancelled();
      
      final isValid = await validateBackupFile(tempFile.path);
      if (!isValid) {
        throw BackupException.validation('备份文件验证失败');
      }
      
      // 步骤7: 移动到最终位置
      await tempFile.copy(backupFilePath);
      
      // 完成性能监控
      await _performanceService.endMonitoring(operationId);
      
      // 完成
      onProgress?.call('备份完成', 100, 100);
      
      // 更新文件大小
      final file = File(backupFilePath);
      final fileSize = await file.length();
      final updatedMetadata = metadata.copyWith(
        fileSize: fileSize,
      );
      
      return BackupResult.success(
        filePath: backupFilePath,
        metadata: updatedMetadata,
      );
      
    } on BackupCancelledException {
      return BackupResult.failure('备份操作已取消');
    } catch (e) {
      return BackupResult.failure('备份失败: ${e.toString()}');
    } finally {
      // 清理临时文件
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  /// 流式导出所有表数据
  Future<Map<String, List<Map<String, dynamic>>>> _streamExportAllTables(
    StreamProcessingConfig config, {
    void Function(int current, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final Map<String, List<Map<String, dynamic>>> allTablesData = {};
    final tableNames = await _dataExportRepository.getAllTableNames();
    
    int processedTables = 0;
    
    for (final tableName in tableNames) {
      cancelToken?.throwIfCancelled();
      
      final tableData = <Map<String, dynamic>>[];
      
      // 使用流式处理导出表数据
      await for (final batch in _streamProcessingService.streamExportTable(
        tableName,
        config,
        onProgress: (processed, total) {
          onProgress?.call(processedTables * 1000 + processed, tableNames.length * 1000);
        },
      )) {
        tableData.addAll(batch);
      }
      
      allTablesData[tableName] = tableData;
      processedTables++;
      
      onProgress?.call(processedTables * 1000, tableNames.length * 1000);
    }
    
    return allTablesData;
  }

  /// 优化的保存备份文件
  Future<void> _optimizedSaveBackupFile(
    BackupData backupData,
    String filePath,
    BackupOptions options,
    StreamProcessingConfig streamConfig,
  ) async {
    try {
      // 使用流式JSON序列化
      final jsonStream = _streamProcessingService.streamJsonSerialize(
        backupData.toJson(),
        streamConfig,
      );
      
      final file = File(filePath);
      final sink = file.openWrite();
      
      try {
        await for (final chunk in jsonStream) {
          sink.write(chunk);
        }
      } finally {
        await sink.close();
      }
      
      // 如果启用压缩，压缩文件
      if (options.compress ?? false) {
        final compressedPath = '${filePath}.gz';
        final stats = await _compressionService.compressFile(
          filePath,
          compressedPath,
          level: _compressionService.getRecommendedCompressionLevel(
            dataSize: await file.length(),
            prioritizeSpeed: true,
          ),
        );
        
        // 如果压缩效果好，使用压缩文件
        if (stats.compressionRatio > 0.2) { // 压缩率超过20%
          await file.delete();
          await File(compressedPath).rename(filePath);
        } else {
          // 压缩效果不好，删除压缩文件
          await File(compressedPath).delete();
        }
      }
      
    } catch (e) {
      throw BackupException.fileSystem('优化保存备份文件失败: ${e.toString()}');
    }
  }

  /// 获取最优批处理大小
  int _getOptimalBatchSize(int totalRecords) {
    // 根据总记录数动态调整批处理大小
    if (totalRecords < 1000) {
      return 100;
    } else if (totalRecords < 10000) {
      return 500;
    } else if (totalRecords < 100000) {
      return 1000;
    } else {
      return 2000;
    }
  }

  // 实现其他必需的接口方法
  @override
  Future<List<BackupMetadata>> getLocalBackups() async {
    try {
      final backupDir = await _getBackupDirectory();
      if (!await backupDir.exists()) {
        return [];
      }

      final backupFiles = await backupDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();

      final List<BackupMetadata> backups = [];
      
      for (final file in backupFiles) {
        try {
          final metadata = await getBackupInfo(file.path);
          if (metadata != null) {
            backups.add(metadata);
          }
        } catch (e) {
          continue;
        }
      }

      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return backups;
    } catch (e) {
      throw BackupException.fileSystem('获取本地备份列表失败: ${e.toString()}');
    }
  }

  @override
  Future<bool> deleteBackup(String backupId) async {
    try {
      final backupDir = await _getBackupDirectory();
      final backupFile = File(path.join(backupDir.path, '$backupId.json'));
      
      if (await backupFile.exists()) {
        await backupFile.delete();
        return true;
      }
      
      return false;
    } catch (e) {
      throw BackupException.fileSystem('删除备份文件失败: ${e.toString()}');
    }
  }

  @override
  Future<BackupMetadata?> getBackupInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      // 检查是否为压缩文件
      final isCompressed = await _compressionService.isCompressed(filePath);
      
      String content;
      if (isCompressed) {
        // 解压并读取
        final tempPath = '${filePath}.tmp';
        await _compressionService.decompressFile(filePath, tempPath);
        content = await File(tempPath).readAsString();
        await File(tempPath).delete();
      } else {
        content = await file.readAsString();
      }

      final jsonData = jsonDecode(content) as Map<String, dynamic>;
      
      if (!jsonData.containsKey('metadata')) {
        return null;
      }

      final metadata = BackupMetadata.fromJson(
        jsonData['metadata'] as Map<String, dynamic>,
      );
      
      final fileSize = await file.length();
      return metadata.copyWith(fileSize: fileSize);
      
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> validateBackupFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      // 检查是否为压缩文件
      final isCompressed = await _compressionService.isCompressed(filePath);
      
      String content;
      if (isCompressed) {
        final tempPath = '${filePath}.tmp';
        await _compressionService.decompressFile(filePath, tempPath);
        content = await File(tempPath).readAsString();
        await File(tempPath).delete();
      } else {
        content = await file.readAsString();
      }

      final jsonData = jsonDecode(content) as Map<String, dynamic>;
      
      if (!jsonData.containsKey('metadata') || !jsonData.containsKey('tables')) {
        return false;
      }

      final metadata = BackupMetadata.fromJson(
        jsonData['metadata'] as Map<String, dynamic>,
      );
      
      final tablesJson = jsonEncode(jsonData['tables']);
      final actualChecksum = _dataExportRepository.generateChecksum(tablesJson);
      
      return actualChecksum == metadata.checksum;
      
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int> estimateBackupSize() async {
    try {
      return await _dataExportRepository.estimateExportSize();
    } catch (e) {
      throw BackupException.database('估算备份大小失败: ${e.toString()}');
    }
  }

  /// 生成备份ID
  String _generateBackupId(String? customName) {
    final timestamp = DateTime.now();
    final dateStr = timestamp.toIso8601String().split('T')[0].replaceAll('-', '');
    final timeStr = timestamp.toIso8601String().split('T')[1].split('.')[0].replaceAll(':', '');
    
    if (customName != null && customName.isNotEmpty) {
      final safeName = customName.replaceAll(RegExp(r'[^\w\-_]'), '_');
      return '${safeName}_${dateStr}_$timeStr';
    }
    
    return 'backup_${dateStr}_$timeStr';
  }

  /// 获取备份目录
  Future<Directory> _getBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(path.join(appDir.path, 'backups'));
    
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    
    return backupDir;
  }

  /// 创建备份元数据
  Future<BackupMetadata> _createBackupMetadata(
    String backupId,
    Map<String, int> tableCounts,
    BackupOptions options,
  ) async {
    final now = DateTime.now();
    final schemaVersion = await _dataExportRepository.getDatabaseSchemaVersion();
    
    return BackupMetadata(
      id: backupId,
      fileName: '$backupId.json',
      createdAt: now,
      fileSize: 0,
      version: '1.0.0',
      tableCounts: tableCounts,
      checksum: '',
      isEncrypted: options.encrypt,
      description: options.description,
      appVersion: '1.0.0+1',
      schemaVersion: schemaVersion,
    );
  }

  /// 获取应用设置
  Future<Map<String, dynamic>?> _getAppSettings() async {
    return {
      'backupVersion': '1.0.0',
      'createdBy': 'Stocko App (Optimized)',
      'optimizations': {
        'streamProcessing': true,
        'memoryMonitoring': true,
        'compressionSupport': true,
      },
    };
  }
}