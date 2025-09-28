import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../../core/database/database.dart';
import '../../domain/models/backup_data.dart';
import '../../domain/models/backup_metadata.dart';
import '../../domain/models/backup_options.dart';
import '../../domain/models/backup_exception.dart';
import '../../domain/common/backup_common.dart';
import '../../domain/services/i_backup_service.dart';
import '../repository/data_export_repository.dart';
import 'backup_error_service.dart';
import 'backup_resource_manager.dart';
import 'backup_error_handler.dart';
import 'performance_service.dart';
import 'stream_processing_service.dart';
import 'compression_service.dart';

/// 备份服务实现类
class BackupService implements IBackupService {
  final DataExportRepository _dataExportRepository;
  final BackupErrorService _errorService = BackupErrorService.instance;
  final BackupResourceManager _resourceManager = BackupResourceManager.instance;
  final PerformanceService _performanceService = PerformanceService();
  final StreamProcessingService _streamProcessingService;
  final CompressionService _compressionService = CompressionService();

  BackupService(AppDatabase database) 
      : _dataExportRepository = DataExportRepository(database),
        _streamProcessingService = StreamProcessingService(database);

  @override
  Future<BackupResult> createBackup({
    BackupOptions? options,
    BackupProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    final operationId = await _errorService.createOperationContext('CreateBackup');
    File? tempFile;
    
    try {
      final backupOptions = options ?? const BackupOptions();
      
      // 检查取消状态
      cancelToken?.throwIfCancelled();
      
      // 步骤1: 准备备份
      onProgress?.call('准备备份...', 0, 100);
      
      final backupId = _generateBackupId(backupOptions.customName);
      final backupDir = await _getBackupDirectory();
      final backupFilePath = path.join(backupDir.path, '$backupId.json');
      
      // 创建临时文件用于备份过程
      tempFile = await _resourceManager.createTemporaryFile(
        prefix: 'backup_temp',
        suffix: 'json',
        operation: 'CreateBackup',
        metadata: {'backupId': backupId},
      );
      
      // 检查存储空间
      await _checkStorageSpace();
      
      // 步骤2: 导出数据
      onProgress?.call('导出数据库数据...', 20, 100);
      cancelToken?.throwIfCancelled();
      
      final tablesData = await _errorService.executeWithRetry(
        () => _dataExportRepository.exportAllTables(),
        config: RetryConfig.database,
        operationName: 'ExportTables',
        context: {'backupId': backupId},
      );
      
      // 步骤3: 获取表统计信息
      onProgress?.call('收集统计信息...', 40, 100);
      cancelToken?.throwIfCancelled();
      
      final tableCounts = await _errorService.executeWithRetry(
        () => _dataExportRepository.getTableCounts(),
        config: RetryConfig.database,
        operationName: 'GetTableCounts',
      );
      
      // 步骤4: 创建元数据
      onProgress?.call('生成备份元数据...', 60, 100);
      cancelToken?.throwIfCancelled();
      
      final metadata = await _createBackupMetadata(
        backupId,
        tableCounts,
        backupOptions,
      );
      
      // 步骤5: 创建备份数据结构
      final backupData = BackupData(
        metadata: metadata,
        tables: tablesData,
        settings: await _getAppSettings(),
      );
      
      // 步骤6: 序列化和保存到临时文件
      onProgress?.call('保存备份文件...', 80, 100);
      cancelToken?.throwIfCancelled();
      
      await _saveBackupFile(backupData, tempFile.path, backupOptions);
      
      // 步骤7: 验证备份文件
      onProgress?.call('验证备份文件...', 95, 100);
      cancelToken?.throwIfCancelled();
      
      final isValid = await validateBackupFile(tempFile.path);
      if (!isValid) {
        throw BackupException.validation('备份文件验证失败');
      }
      
      // 步骤8: 移动临时文件到最终位置
      await tempFile.copy(backupFilePath);
      
      // 完成
      onProgress?.call('备份完成', 100, 100);
      
      // 更新文件大小
      final file = File(backupFilePath);
      final fileSize = await file.length();
      final updatedMetadata = metadata.copyWith(fileSize: fileSize);
      
      await _errorService.completeOperationContext(
        operationId,
        'CreateBackup',
        success: true,
        message: '备份创建成功',
        result: {'filePath': backupFilePath, 'fileSize': fileSize},
      );
      
      return BackupResult.success(
        filePath: backupFilePath,
        metadata: updatedMetadata,
      );
      
    } on BackupCancelledException {
      await _errorService.completeOperationContext(
        operationId,
        'CreateBackup',
        success: false,
        message: '备份操作已取消',
      );
      return BackupResult.failure('备份操作已取消');
    } catch (e) {
      final userError = await _errorService.handleError(
        e,
        operation: 'CreateBackup',
        context: {'operationId': operationId},
      );
      
      await _errorService.completeOperationContext(
        operationId,
        'CreateBackup',
        success: false,
        message: userError.message,
      );
      
      return BackupResult.failure(userError.message);
    } finally {
      // 清理临时文件
      if (tempFile != null) {
        await _errorService.executeSafely(
          () async {
            if (await tempFile!.exists()) {
              await tempFile.delete();
            }
          },
          operationName: 'CleanupTempFile',
          logErrors: false,
        );
      }
    }
  }

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
          // 忽略无法读取的备份文件
          continue;
        }
      }

      // 按创建时间倒序排列
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

      final content = await file.readAsString();
      final jsonData = jsonDecode(content) as Map<String, dynamic>;
      
      if (!jsonData.containsKey('metadata')) {
        return null;
      }

      final metadata = BackupMetadata.fromJson(
        jsonData['metadata'] as Map<String, dynamic>,
      );
      
      // 更新文件大小信息
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

      final content = await file.readAsString();
      final jsonData = jsonDecode(content) as Map<String, dynamic>;
      
      // 验证基本结构
      if (!jsonData.containsKey('metadata') || !jsonData.containsKey('tables')) {
        return false;
      }

      // 验证元数据
      final metadata = BackupMetadata.fromJson(
        jsonData['metadata'] as Map<String, dynamic>,
      );
      
      // 验证校验和
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
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(path.join(appDir.path, 'backups'));
      
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      return backupDir;
    } catch (e) {
      // 在测试环境中使用临时目录
      final tempDir = Directory.systemTemp;
      final backupDir = Directory(path.join(tempDir.path, 'test_backups'));
      
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      return backupDir;
    }
  }

  /// 检查存储空间
  Future<void> _checkStorageSpace() async {
    try {
      final estimatedSize = await estimateBackupSize();
      final backupDir = await _getBackupDirectory();
      
      // 预留至少100MB的额外空间
      const reservedSpace = 100 * 1024 * 1024; // 100MB
      
      if (estimatedSize > reservedSpace) {
        // 这里可以添加更精确的磁盘空间检查逻辑
        // 目前只是一个基本的估算
        throw BackupException.insufficientSpace(
          '估计需要 ${(estimatedSize / 1024 / 1024).toStringAsFixed(1)}MB 空间，但可用空间不足'
        );
      }
    } catch (e) {
      // 如果无法检查存储空间，继续执行但记录警告
      // 在实际应用中可能需要更严格的处理
    }
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
      fileSize: 0, // 将在保存后更新
      version: '1.0.0',
      tableCounts: tableCounts,
      checksum: '', // 将在序列化后生成
      isEncrypted: options.encrypt,
      description: options.description,
      appVersion: '1.0.0+1', // 可以从package info获取
      schemaVersion: schemaVersion,
    );
  }

  /// 获取应用设置
  Future<Map<String, dynamic>?> _getAppSettings() async {
    // 这里可以添加获取应用设置的逻辑
    // 例如从SharedPreferences或其他存储中读取
    return {
      'backupVersion': '1.0.0',
      'createdBy': 'Stocko App',
    };
  }

  /// 保存备份文件
  Future<void> _saveBackupFile(
    BackupData backupData,
    String filePath,
    BackupOptions options,
  ) async {
    try {
      // 序列化表数据并生成校验和
      final tablesJson = jsonEncode(backupData.tables);
      final checksum = _dataExportRepository.generateChecksum(tablesJson);
      
      // 更新元数据中的校验和
      final updatedMetadata = backupData.metadata.copyWith(checksum: checksum);
      final updatedBackupData = backupData.copyWith(metadata: updatedMetadata);
      
      // 序列化完整的备份数据
      String jsonContent;
      if (options.encrypt && options.password != null) {
        // 加密功能暂未实现，返回明确的错误信息
        throw BackupException.encryption('加密功能将在后续版本中提供，当前版本请使用非加密备份');
      } else {
        jsonContent = _dataExportRepository.serializeToJson(
          updatedBackupData.toJson(),
          prettyPrint: true,
        );
      }
      
      // 写入文件
      final file = File(filePath);
      await file.writeAsString(jsonContent);
      
    } catch (e) {
      throw BackupException.fileSystem('保存备份文件失败: ${e.toString()}');
    }
  }
}