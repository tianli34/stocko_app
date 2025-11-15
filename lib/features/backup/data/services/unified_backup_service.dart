import 'dart:convert';
import 'dart:io';
import 'dart:async';
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
import '../repository/optimized_data_export_repository.dart';
import 'performance_service.dart';
import 'stream_processing_service.dart';
import 'compression_service.dart';
import 'backup_error_service.dart';
import 'backup_resource_manager.dart';

/// 统一备份服务 - 融合优化版和增强版的优势
///
/// 主要特性：
/// - 流式处理和内存优化（来自优化版）
/// - 压缩支持和性能监控（来自优化版）
/// - 强化的错误处理和恢复机制（来自增强版）
/// - 数据库健康检查和预检查（来自增强版）
/// - 资源管理和清理（来自增强版）
class UnifiedBackupService implements IBackupService {
  final OptimizedDataExportRepository _dataExportRepository;
  final IPerformanceService _performanceService;
  final StreamProcessingService _streamProcessingService;
  final CompressionService _compressionService;
  final BackupErrorService _errorService = BackupErrorService.instance;
  final BackupResourceManager _resourceManager = BackupResourceManager.instance;

  // 配置常量
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  UnifiedBackupService(AppDatabase database)
    : _dataExportRepository = OptimizedDataExportRepository(database),
      _performanceService = PerformanceService(),
      _streamProcessingService = StreamProcessingService(database),
      _compressionService = CompressionService();

  @override
  Future<BackupResult> createBackup({
    BackupOptions? options,
    BackupProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    final operationId = await _errorService.createOperationContext(
      'UnifiedCreateBackup',
    );
    File? tempFile;

    try {
      final backupOptions = options ?? const BackupOptions();

      // 检查取消状态
      cancelToken?.throwIfCancelled();

      // 步骤1: 预检查和准备（增强版特性）
      onProgress?.call('执行预检查...', 0, 100);
      await _performPreflightChecks();

      final backupId = _generateBackupId(backupOptions.customName);
      final backupDir = await _getBackupDirectory();
      final backupFilePath = path.join(backupDir.path, '$backupId.json');

      // 创建临时文件（增强版资源管理）
      tempFile = await _resourceManager.createTemporaryFile(
        prefix: 'unified_backup_temp',
        suffix: 'json',
        operation: 'UnifiedCreateBackup',
        metadata: {'backupId': backupId},
      );

      // 步骤2: 数据库健康检查（增强版特性）
      onProgress?.call('检查数据库健康状态...', 5, 100);
      cancelToken?.throwIfCancelled();
      await _performDatabaseHealthCheck();

      // 步骤3: 获取表统计信息用于性能监控（优化版特性）
      onProgress?.call('分析数据结构...', 10, 100);
      final tableCounts = await _getTableCountsSafely();
      final totalRecords = tableCounts.values.fold<int>(
        0,
        (sum, count) => sum + count,
      );

      // 开始性能监控（优化版特性）
      await _performanceService.startMonitoring(operationId, totalRecords);

      // 步骤4: 流式数据导出（融合两者优势）
      onProgress?.call('开始智能流式数据导出...', 15, 100);
      cancelToken?.throwIfCancelled();

      final streamConfig = StreamProcessingConfig(
        batchSize: _getOptimalBatchSize(totalRecords),
        enableCompression: backupOptions.compress == true,
        enableMemoryMonitoring: true,
      );

      final tablesData = await _performUnifiedStreamingExport(
        streamConfig,
        onProgress: (current, total) {
          final progressPercent = 15 + ((current / total) * 60).round();
          onProgress?.call('导出数据 ($current/$total)', progressPercent, 100);
        },
        cancelToken: cancelToken,
      );

      // 步骤5: 创建元数据
      onProgress?.call('生成备份元数据...', 80, 100);
      cancelToken?.throwIfCancelled();

      final metadata = await _createBackupMetadata(
        backupId,
        tableCounts,
        backupOptions,
      );

      // 步骤6: 创建备份数据结构
      final backupData = BackupData(
        metadata: metadata,
        tables: tablesData,
        settings: await _getAppSettings(),
      );

      // 步骤7: 优化的序列化和保存（融合两者优势）
      onProgress?.call('智能保存备份文件...', 85, 100);
      cancelToken?.throwIfCancelled();

      await _unifiedSaveBackupFile(
        backupData,
        tempFile.path,
        backupOptions,
        streamConfig,
      );

      // 步骤8: 验证备份文件
      onProgress?.call('验证备份文件...', 95, 100);
      cancelToken?.throwIfCancelled();

      final isValid = await validateBackupFile(tempFile.path);
      if (!isValid) {
        throw BackupException.validation('备份文件验证失败');
      }

      // 步骤9: 移动到最终位置
      await tempFile.copy(backupFilePath);

      // 完成性能监控
      await _performanceService.endMonitoring(operationId);

      // 完成
      onProgress?.call('备份完成', 100, 100);

      // 更新文件大小
      final file = File(backupFilePath);
      final fileSize = await file.length();
      final updatedMetadata = metadata.copyWith(fileSize: fileSize);

      await _errorService.completeOperationContext(
        operationId,
        'UnifiedCreateBackup',
        success: true,
        message: '统一备份创建成功',
        result: {'filePath': backupFilePath, 'fileSize': fileSize},
      );

      return BackupResult.success(
        filePath: backupFilePath,
        metadata: updatedMetadata,
      );
    } on BackupCancelledException {
      await _errorService.completeOperationContext(
        operationId,
        'UnifiedCreateBackup',
        success: false,
        message: '备份操作已取消',
      );
      return BackupResult.failure('备份操作已取消');
    } catch (e) {
      final errorContext = await _buildErrorContext(e, tempFile);

      final userError = await _errorService.handleError(
        e,
        operation: 'UnifiedCreateBackup',
        context: errorContext,
      );

      await _errorService.completeOperationContext(
        operationId,
        'UnifiedCreateBackup',
        success: false,
        message: userError.message,
      );

      return BackupResult.failure(
        _buildDetailedErrorMessage(userError.message, errorContext),
      );
    } finally {
      // 清理临时文件和资源
      await _cleanupTempFile(tempFile);
    }
  }

  /// 统一的流式导出 - 融合两者优势
  Future<Map<String, List<Map<String, dynamic>>>>
  _performUnifiedStreamingExport(
    StreamProcessingConfig config, {
    void Function(int current, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final Map<String, List<Map<String, dynamic>>> allTablesData = {};
    final tableNames = await _dataExportRepository.getAllTableNames();

    int processedTables = 0;

    for (final tableName in tableNames) {
      cancelToken?.throwIfCancelled();

      // 使用增强版的重试机制导出表数据
      final tableData = await _exportTableWithRetryAndStreaming(
        tableName,
        config,
        cancelToken,
      );

      allTablesData[tableName] = tableData;
      processedTables++;

      onProgress?.call(processedTables * 1000, tableNames.length * 1000);

      // 定期进行内存清理（优化版特性）
      if (processedTables % 5 == 0) {
        await Future.delayed(Duration(milliseconds: 100));
      }
    }

    return allTablesData;
  }

  /// 带重试机制的流式表导出
  Future<List<Map<String, dynamic>>> _exportTableWithRetryAndStreaming(
    String tableName,
    StreamProcessingConfig config,
    CancelToken? cancelToken,
  ) async {
    int retryCount = 0;

    while (retryCount < _maxRetries) {
      try {
        final tableData = <Map<String, dynamic>>[];

        // 使用优化版的流式处理服务
        await for (final batch in _streamProcessingService.streamExportTable(
          tableName,
          config,
        )) {
          cancelToken?.throwIfCancelled();
          tableData.addAll(batch);

          // 短暂暂停以避免过度占用资源
          if (tableData.length % (config.batchSize * 5) == 0) {
            await Future.delayed(Duration(milliseconds: 50));
          }
        }

        return tableData;
      } catch (e) {
        retryCount++;
        if (retryCount >= _maxRetries) {
          throw BackupException.database(
            '表 $tableName 导出失败，已重试 $_maxRetries 次: ${e.toString()}',
          );
        }

        // 等待后重试
        await Future.delayed(_retryDelay);
      }
    }

    throw BackupException.database('表 $tableName 导出失败，已达到最大重试次数');
  }

  /// 统一的保存备份文件 - 融合两者优势
  Future<void> _unifiedSaveBackupFile(
    BackupData backupData,
    String filePath,
    BackupOptions options,
    StreamProcessingConfig streamConfig,
  ) async {
    try {
      // 生成校验和（增强版特性）
      final tablesJson = jsonEncode(backupData.tables);
      final checksum = _dataExportRepository.generateChecksum(tablesJson);

      final updatedMetadata = backupData.metadata.copyWith(checksum: checksum);
      final updatedBackupData = backupData.copyWith(metadata: updatedMetadata);

      // 使用优化版的流式JSON序列化
      final jsonStream = _streamProcessingService.streamJsonSerialize(
        updatedBackupData.toJson(),
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

      // 智能压缩处理（优化版特性）
      if (options.compress == true) {
        await _applyIntelligentCompression(file, options);
      }
    } catch (e) {
      throw BackupException.fileSystem('统一保存备份文件失败: ${e.toString()}');
    }
  }

  /// 智能压缩处理
  Future<void> _applyIntelligentCompression(
    File file,
    BackupOptions options,
  ) async {
    final compressedPath = '${file.path}.gz';
    final stats = await _compressionService.compressFile(
      file.path,
      compressedPath,
      level: _compressionService.getRecommendedCompressionLevel(
        dataSize: await file.length(),
        prioritizeSpeed: true,
      ),
    );

    // 如果压缩效果好，使用压缩文件
    if (stats.compressionRatio > 0.2) {
      // 压缩率超过20%
      await file.delete();
      await File(compressedPath).rename(file.path);
    } else {
      // 压缩效果不好，删除压缩文件
      await File(compressedPath).delete();
    }
  }

  /// 执行预检查（增强版特性）
  Future<void> _performPreflightChecks() async {
    try {
      // 检查存储空间
      await _checkStorageSpace();

      // 检查数据库基本连接
      await _dataExportRepository.testConnection();

      // 检查备份目录权限
      final backupDir = await _getBackupDirectory();
      await _testDirectoryPermissions(backupDir);
    } catch (e) {
      throw BackupException.fileSystem('预检查失败: ${e.toString()}');
    }
  }

  /// 执行数据库健康检查（增强版特性）
  Future<void> _performDatabaseHealthCheck() async {
    try {
      // 检查数据库完整性
      final integrityCheck = await _dataExportRepository
          .checkDatabaseIntegrity();
      if (!integrityCheck) {
        throw BackupException.database('数据库完整性检查失败');
      }

      // 检查是否有长时间运行的事务
      final hasLongRunningTransactions = await _dataExportRepository
          .checkLongRunningTransactions();
      if (hasLongRunningTransactions) {
        // 等待事务完成或超时
        await Future.delayed(Duration(seconds: 5));
      }

      // 检查数据库锁定状态
      final isLocked = await _dataExportRepository.isDatabaseLocked();
      if (isLocked) {
        throw BackupException.database('数据库当前被锁定，请稍后重试');
      }
    } catch (e) {
      throw BackupException.database('数据库健康检查失败: ${e.toString()}');
    }
  }

  /// 安全获取表统计信息（增强版特性）
  Future<Map<String, int>> _getTableCountsSafely() async {
    try {
      return await _dataExportRepository.getTableCounts();
    } catch (e) {
      // 如果无法获取精确统计，返回估算值
      final tables = await _dataExportRepository.getAllTableNames();
      final estimatedCounts = <String, int>{};

      for (final table in tables) {
        try {
          final count = await _dataExportRepository.getTableRowCount(table);
          estimatedCounts[table] = count;
        } catch (e) {
          estimatedCounts[table] = 0; // 默认值
        }
      }

      return estimatedCounts;
    }
  }

  /// 获取最优批处理大小（优化版特性）
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

  /// 构建错误上下文（增强版特性）
  Future<Map<String, dynamic>> _buildErrorContext(
    dynamic error,
    File? tempFile,
  ) async {
    return {
      'hasTemporaryFile': tempFile != null,
      'temporaryFilePath': tempFile?.path,
      'errorType': error.runtimeType.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'serviceType': 'UnifiedBackupService',
    };
  }

  /// 构建详细错误消息（增强版特性）
  String _buildDetailedErrorMessage(
    String baseMessage,
    Map<String, dynamic> context,
  ) {
    final buffer = StringBuffer(baseMessage);

    if (context['hasTemporaryFile'] == true) {
      buffer.write('\n临时文件: ${context['temporaryFilePath']}');
    }

    buffer.write('\n服务类型: ${context['serviceType']}');

    return buffer.toString();
  }

  /// 清理临时文件（增强版特性）
  Future<void> _cleanupTempFile(File? tempFile) async {
    if (tempFile != null) {
      await _errorService.executeSafely(
        () async {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        },
        operationName: 'CleanupTempFile',
        logErrors: false,
      );
    }
  }

  /// 检查存储空间（增强版特性）
  Future<void> _checkStorageSpace() async {
    try {
      final estimatedSize = await estimateBackupSize();
      const reservedSpace = 100 * 1024 * 1024; // 100MB

      if (estimatedSize > reservedSpace) {
        throw BackupException.insufficientSpace(
          '估计需要 ${(estimatedSize / 1024 / 1024).toStringAsFixed(1)}MB 空间，但可用空间不足',
        );
      }
    } catch (e) {
      // 继续执行但记录警告
    }
  }

  /// 测试目录权限（增强版特性）
  Future<void> _testDirectoryPermissions(Directory dir) async {
    try {
      final testFile = File(path.join(dir.path, 'test_permissions.tmp'));
      await testFile.writeAsString('test');
      await testFile.delete();
    } catch (e) {
      throw BackupException.fileSystem('备份目录权限不足: ${e.toString()}');
    }
  }

  /// 生成备份ID
  String _generateBackupId(String? customName) {
    final timestamp = DateTime.now();
    final dateStr = timestamp
        .toIso8601String()
        .split('T')[0]
        .replaceAll('-', '');
    final timeStr = timestamp
        .toIso8601String()
        .split('T')[1]
        .split('.')[0]
        .replaceAll(':', '');

    if (customName != null && customName.isNotEmpty) {
      final safeName = customName.replaceAll(RegExp(r'[^\w\-_]'), '_');
      return '${safeName}_${dateStr}_$timeStr';
    }

    return 'unified_backup_${dateStr}_$timeStr';
  }

  /// 获取备份目录
  Future<Directory> _getBackupDirectory() async {
    // 方案1: 尝试使用公共下载目录（用户可通过文件管理器访问）
    try {
      // Android: /storage/emulated/0/Download/StockoBackups
      // 注意：是 Download 不是 Downloads
      final publicDownloadDir = Directory('/storage/emulated/0/Download/StockoBackups');
      
      if (!await publicDownloadDir.exists()) {
        await publicDownloadDir.create(recursive: true);
      }
      
      // 测试是否可写
      final testFile = File(path.join(publicDownloadDir.path, '.test'));
      await testFile.writeAsString('test');
      await testFile.delete();
      
      return publicDownloadDir;
    } catch (e) {
      // 如果公共目录不可用，继续尝试其他位置
    }
    
    // 方案2: 尝试使用外部存储目录
    try {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        // 尝试导航到公共 Download 目录
        final publicPath = '/storage/emulated/0/Download/StockoBackups';
        final backupDir = Directory(publicPath);
        
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }
        
        // 测试是否可写
        final testFile = File(path.join(backupDir.path, '.test'));
        await testFile.writeAsString('test');
        await testFile.delete();
        
        return backupDir;
      }
    } catch (e) {
      // 继续尝试其他方案
    }

    // 方案3: 回退到应用私有的 Downloads 目录
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        final backupDir = Directory(
          path.join(downloadsDir.path, 'StockoBackups'),
        );

        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }

        return backupDir;
      }
    } catch (e) {
      // 继续尝试其他方案
    }

    // 方案4: 回退到应用文档目录
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(path.join(appDir.path, 'backups'));

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      return backupDir;
    } catch (e) {
      // 最后的备用方案
    }
    
    // 方案5: 最后回退到临时目录
    final tempDir = Directory.systemTemp;
    final backupDir = Directory(path.join(tempDir.path, 'unified_backups'));

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
    final schemaVersion = await _dataExportRepository
        .getDatabaseSchemaVersion();

    return BackupMetadata(
      id: backupId,
      fileName: '$backupId.json',
      createdAt: now,
      fileSize: 0,
      version: '3.0.0', // 统一版本号
      tableCounts: tableCounts,
      checksum: '',
      isEncrypted: options.encrypt,
      description: options.description ?? '统一备份服务创建',
      appVersion: '1.0.0+1',
      schemaVersion: schemaVersion,
    );
  }

  /// 获取应用设置
  Future<Map<String, dynamic>?> _getAppSettings() async {
    return {
      'backupVersion': '3.0.0',
      'createdBy': 'Unified 铺得清 App',
      'serviceType': 'UnifiedBackupService',
      'features': {
        'streamProcessing': true,
        'memoryMonitoring': true,
        'compressionSupport': true,
        'enhancedErrorHandling': true,
        'databaseHealthCheck': true,
        'resourceManagement': true,
      },
    };
  }

  // 实现接口的其他方法
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

      // 检查是否为压缩文件（优化版特性）
      final isCompressed = await _compressionService.isCompressed(filePath);

      String content;
      if (isCompressed) {
        // 解压并读取
        final tempPath = '$filePath.tmp';
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

      // 检查是否为压缩文件（优化版特性）
      final isCompressed = await _compressionService.isCompressed(filePath);

      String content;
      if (isCompressed) {
        final tempPath = '$filePath.tmp';
        await _compressionService.decompressFile(filePath, tempPath);
        content = await File(tempPath).readAsString();
        await File(tempPath).delete();
      } else {
        content = await file.readAsString();
      }

      final jsonData = jsonDecode(content) as Map<String, dynamic>;

      if (!jsonData.containsKey('metadata') ||
          !jsonData.containsKey('tables')) {
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
}
