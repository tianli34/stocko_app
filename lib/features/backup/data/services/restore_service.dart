import 'dart:convert';
import 'dart:io';

import '../../../../core/database/database.dart';
import '../../domain/models/backup_data.dart';
import '../../domain/models/backup_metadata.dart';
import '../../domain/models/backup_exception.dart';
import '../../domain/models/backup_error_type.dart';
import '../../domain/models/restore_result.dart';
import '../../domain/models/restore_preview.dart';
import '../../domain/models/restore_mode.dart';
import '../../domain/services/i_restore_service.dart';
import '../../domain/services/i_encryption_service.dart';
import '../../domain/services/i_validation_service.dart';
import '../../domain/models/compatibility_check_result.dart';
import '../../domain/common/backup_common.dart';
import '../repository/data_import_repository.dart';
import '../repository/data_export_repository.dart';

/// 数据恢复服务实现类
class RestoreService implements IRestoreService {
  final IEncryptionService _encryptionService;
  final IValidationService _validationService;
  final DataImportRepository _dataImportRepository;
  final DataExportRepository _dataExportRepository;

  RestoreService(
    AppDatabase database,
    this._encryptionService,
    this._validationService,
  ) : _dataImportRepository = DataImportRepository(database),
      _dataExportRepository = DataExportRepository(database);

  @override
  Future<BackupMetadata> validateBackupFile(
    String filePath, {
    String? password,
  }) async {
    try {
      // 使用新的验证服务进行文件格式验证
      final formatResult = await _validationService.validateBackupFormat(
        filePath,
        password: password,
      );

      if (!formatResult.isValid) {
        final errorMessages = formatResult.errors.map((e) => e.message).join('; ');
        throw BackupException(
          type: BackupErrorType.validationError,
          message: '备份文件验证失败: $errorMessages',
        );
      }

      // 读取备份数据以获取元数据
      final backupData = await _readBackupData(filePath, password: password);
      
      // 进行版本兼容性检查
      final compatibilityResult = await _validationService.checkVersionCompatibility(
        backupData.metadata,
      );

      if (!compatibilityResult.isCompatible) {
        final criticalIssues = compatibilityResult.issues
            .where((i) => i.severity == CompatibilityIssueSeverity.critical)
            .map((i) => i.description)
            .join('; ');
        
        if (criticalIssues.isNotEmpty) {
          throw BackupException(
            type: BackupErrorType.validationError,
            message: '备份文件版本不兼容: $criticalIssues',
          );
        }
      }

      // 进行数据完整性验证
      final integrityResult = await _validationService.validateDataIntegrity(
        backupData.tables,
        backupData.metadata,
      );

      if (!integrityResult.checksumValid) {
        throw BackupException(
          type: BackupErrorType.validationError,
          message: '备份文件数据完整性验证失败，文件可能已损坏',
        );
      }

      return backupData.metadata;

    } catch (e) {
      if (e is BackupException) rethrow;
      throw BackupException(
        type: BackupErrorType.fileSystemError,
        message: '验证备份文件失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<RestorePreview> previewRestore(
    String filePath, {
    String? password,
  }) async {
    try {
      // 使用验证服务进行恢复前预检查
      final preCheckResult = await _validationService.preRestoreValidation(
        filePath,
        password: password,
      );

      // 读取备份数据
      final backupData = await _readBackupData(filePath, password: password);

      // 检查兼容性
      final compatibilityResult = await _validationService.checkVersionCompatibility(
        backupData.metadata,
      );

      final compatibilityWarnings = <String>[];
      
      // 收集兼容性警告
      for (final warning in compatibilityResult.warnings) {
        compatibilityWarnings.add(warning.description);
      }

      // 收集预检查警告
      for (final warning in preCheckResult.warnings) {
        compatibilityWarnings.add(warning.message);
      }

      // 验证导入数据
      final validationResult = await _dataImportRepository.validateImportData(
        backupData.tables,
      );

      if (validationResult['warnings'] != null) {
        compatibilityWarnings.addAll(
          (validationResult['warnings'] as List<String>),
        );
      }

      // 估算冲突数量
      final estimatedConflicts = await _dataImportRepository.estimateConflicts(
        backupData.tables,
        RestoreMode.merge, // 使用合并模式估算冲突
      );

      // 估算恢复时间
      final totalRecords = validationResult['totalRecords'] as int;
      final estimatedDuration = await _dataImportRepository.estimateImportTime(
        totalRecords,
        RestoreMode.merge,
      );

      return RestorePreview(
        metadata: backupData.metadata,
        recordCounts: backupData.metadata.tableCounts,
        estimatedConflicts: estimatedConflicts,
        isCompatible: compatibilityResult.isCompatible && preCheckResult.isValid,
        compatibilityWarnings: compatibilityWarnings,
        estimatedDurationSeconds: estimatedDuration,
      );

    } catch (e) {
      if (e is BackupException) rethrow;
      throw BackupException(
        type: BackupErrorType.validationError,
        message: '生成恢复预览失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<RestoreResult> restoreFromBackup({
    required String filePath,
    required RestoreMode mode,
    String? password,
    List<String>? selectedTables,
    RestoreProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    final startTime = DateTime.now();
    
    try {
      // 步骤1: 验证备份文件
      onProgress?.call('验证备份文件...', 0, 100);
      cancelToken?.throwIfCancelled();
      
      final metadata = await validateBackupFile(filePath, password: password);

      // 步骤2: 读取备份数据
      onProgress?.call('读取备份数据...', 10, 100);
      cancelToken?.throwIfCancelled();
      
      final backupData = await _readBackupData(filePath, password: password);

      // 步骤3: 验证导入数据
      onProgress?.call('验证数据完整性...', 20, 100);
      cancelToken?.throwIfCancelled();
      
      final validationResult = await _dataImportRepository.validateImportData(
        backupData.tables,
      );

      if (!validationResult['valid']) {
        final errors = validationResult['errors'] as List<String>;
        throw BackupException(
          type: BackupErrorType.validationError,
          message: '备份数据验证失败: ${errors.join(', ')}',
        );
      }

      // 步骤4: 开始数据导入
      onProgress?.call('开始恢复数据...', 30, 100);
      cancelToken?.throwIfCancelled();

      final importCounts = await _dataImportRepository.importAllTables(
        backupData.tables,
        mode,
        selectedTables: selectedTables,
        onProgress: (message, current, total) {
          // 将导入进度映射到总进度的30-90%区间
          final progressPercent = 30 + ((current / total) * 60).round();
          onProgress?.call(message, progressPercent, 100);
        },
        cancelToken: cancelToken,
      );

      // 步骤5: 验证导入结果
      onProgress?.call('验证恢复结果...', 90, 100);
      cancelToken?.throwIfCancelled();

      // 执行健康检查
      final healthCheck = await _dataImportRepository.performHealthCheck(
        selectedTables ?? backupData.tables.keys.toList(),
      );

      final totalRecordsRestored = importCounts.values.fold<int>(
        0,
        (sum, count) => sum + count,
      );

      // 完成
      onProgress?.call('恢复完成', 100, 100);
      
      final endTime = DateTime.now();
      final warnings = validationResult['warnings'] as List<String>? ?? [];
      
      // 添加健康检查的问题到警告中
      if (healthCheck['issues'] != null) {
        warnings.addAll(healthCheck['issues'] as List<String>);
      }

      return RestoreResult(
        success: true,
        totalRecordsRestored: totalRecordsRestored,
        tableRecordCounts: importCounts,
        startTime: startTime,
        endTime: endTime,
        warnings: warnings,
      );

    } on RestoreCancelledException {
      final endTime = DateTime.now();
      return RestoreResult(
        success: false,
        totalRecordsRestored: 0,
        tableRecordCounts: {},
        startTime: startTime,
        endTime: endTime,
        errorMessage: '恢复操作已取消',
      );
    } on BackupException catch (e) {
      final endTime = DateTime.now();
      return RestoreResult(
        success: false,
        totalRecordsRestored: 0,
        tableRecordCounts: {},
        startTime: startTime,
        endTime: endTime,
        errorMessage: e.message,
      );
    } catch (e) {
      final endTime = DateTime.now();
      return RestoreResult(
        success: false,
        totalRecordsRestored: 0,
        tableRecordCounts: {},
        startTime: startTime,
        endTime: endTime,
        errorMessage: '恢复失败: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> checkCompatibility(
    String filePath, {
    String? password,
  }) async {
    try {
      final metadata = await validateBackupFile(filePath, password: password);
      
      // 检查数据库架构版本兼容性
      final currentSchemaVersion = await _dataExportRepository.getDatabaseSchemaVersion();
      
      if (metadata.schemaVersion != null) {
        // 如果备份的架构版本比当前版本新，可能不兼容
        if (metadata.schemaVersion! > currentSchemaVersion) {
          return false;
        }
        
        // 如果架构版本差异太大（超过5个版本），可能不兼容
        if (currentSchemaVersion - metadata.schemaVersion! > 5) {
          return false;
        }
      }

      // 检查备份格式版本
      final backupVersion = metadata.version;
      const supportedVersions = ['1.0.0'];
      
      if (!supportedVersions.contains(backupVersion)) {
        return false;
      }

      // 检查表结构兼容性
      final backupData = await _readBackupData(filePath, password: password);
      final currentTables = await _dataExportRepository.getAllTableNames();
      
      for (final tableName in backupData.tables.keys) {
        if (!currentTables.contains(tableName)) {
          // 如果备份中的表在当前数据库中不存在，标记为不兼容
          // 但这不是致命错误，可以在恢复时跳过
          continue;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int> estimateRestoreTime(
    String filePath,
    RestoreMode mode, {
    List<String>? selectedTables,
  }) async {
    try {
      final backupMetadata = await validateBackupFile(filePath);
      
      int totalRecords = 0;
      if (selectedTables != null) {
        for (final tableName in selectedTables) {
          totalRecords += backupMetadata.tableCounts[tableName] ?? 0;
        }
      } else {
        totalRecords = backupMetadata.tableCounts.values.fold<int>(
          0,
          (sum, count) => sum + count,
        );
      }

      return await _dataImportRepository.estimateImportTime(totalRecords, mode);
    } catch (e) {
      return 60; // 默认估算1分钟
    }
  }

  /// 读取备份数据
  Future<BackupData> _readBackupData(
    String filePath, {
    String? password,
  }) async {
    try {
      final file = File(filePath);
      String content = await file.readAsString();
      
      // 如果提供了密码，尝试解密
      if (password != null) {
        content = await _encryptionService.decryptData(content, password);
      }

      final jsonData = jsonDecode(content) as Map<String, dynamic>;
      return BackupData.fromJson(jsonData);
    } catch (e) {
      throw BackupException(
        type: BackupErrorType.fileSystemError,
        message: '读取备份数据失败: ${e.toString()}',
        originalError: e,
      );
    }
  }
}