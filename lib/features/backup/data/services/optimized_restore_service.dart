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
import '../../domain/common/backup_common.dart';
import '../repository/data_import_repository.dart';
import '../repository/data_export_repository.dart';
import 'compression_service.dart';

/// 优化的数据恢复服务实现类
/// 支持压缩文件处理和性能优化
class OptimizedRestoreService implements IRestoreService {
  final IEncryptionService _encryptionService;
  final IValidationService _validationService;
  final DataImportRepository _dataImportRepository;
  final DataExportRepository _dataExportRepository;
  final CompressionService _compressionService;

  OptimizedRestoreService(
    AppDatabase database,
    this._encryptionService,
    this._validationService,
  ) : _dataImportRepository = DataImportRepository(database),
      _dataExportRepository = DataExportRepository(database),
      _compressionService = CompressionService();

  @override
  Future<BackupMetadata> validateBackupFile(
    String filePath, {
    String? password,
  }) async {
    try {
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

      final backupData = await _readBackupData(filePath, password: password);
      
      final compatibilityResult = await _validationService.checkVersionCompatibility(
        backupData.metadata,
      );

      if (!compatibilityResult.isCompatible) {
        final criticalIssues = compatibilityResult.issues
            .where((i) => i.severity.toString() == 'critical')
            .map((i) => i.description)
            .join('; ');
        
        if (criticalIssues.isNotEmpty) {
          throw BackupException(
            type: BackupErrorType.validationError,
            message: '备份文件版本不兼容: $criticalIssues',
          );
        }
      }

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
      final preCheckResult = await _validationService.preRestoreValidation(
        filePath,
        password: password,
      );

      final backupData = await _readBackupData(filePath, password: password);

      final compatibilityResult = await _validationService.checkVersionCompatibility(
        backupData.metadata,
      );

      final compatibilityWarnings = <String>[];
      
      for (final warning in compatibilityResult.warnings) {
        compatibilityWarnings.add(warning.description);
      }

      for (final warning in preCheckResult.warnings) {
        compatibilityWarnings.add(warning.message);
      }

      final validationResult = await _dataImportRepository.validateImportData(
        backupData.tables,
      );

      if (validationResult['warnings'] != null) {
        compatibilityWarnings.addAll(
          (validationResult['warnings'] as List<String>),
        );
      }

      final estimatedConflicts = await _dataImportRepository.estimateConflicts(
        backupData.tables,
        RestoreMode.merge,
      );

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
      onProgress?.call('验证备份文件...', 0, 100);
      cancelToken?.throwIfCancelled();
      
      await validateBackupFile(filePath, password: password);

      onProgress?.call('读取备份数据...', 10, 100);
      cancelToken?.throwIfCancelled();
      
      final backupData = await _readBackupData(filePath, password: password);

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

      onProgress?.call('开始恢复数据...', 30, 100);
      cancelToken?.throwIfCancelled();

      final importCounts = await _dataImportRepository.importAllTables(
        backupData.tables,
        mode,
        selectedTables: selectedTables,
        onProgress: (message, current, total) {
          final progressPercent = 30 + ((current / total) * 60).round();
          onProgress?.call(message, progressPercent, 100);
        },
        cancelToken: cancelToken,
      );

      onProgress?.call('验证恢复结果...', 90, 100);
      cancelToken?.throwIfCancelled();

      final healthCheck = await _dataImportRepository.performHealthCheck(
        selectedTables ?? backupData.tables.keys.toList(),
      );

      final totalRecordsRestored = importCounts.values.fold<int>(
        0,
        (sum, count) => sum + count,
      );

      onProgress?.call('恢复完成', 100, 100);
      
      final endTime = DateTime.now();
      final warnings = validationResult['warnings'] as List<String>? ?? [];
      
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
      
      final currentSchemaVersion = await _dataExportRepository.getDatabaseSchemaVersion();
      
      if (metadata.schemaVersion != null) {
        if (metadata.schemaVersion! > currentSchemaVersion) {
          return false;
        }
        
        if (currentSchemaVersion - metadata.schemaVersion! > 5) {
          return false;
        }
      }

      const supportedVersions = ['1.0.0'];
      if (!supportedVersions.contains(metadata.version)) {
        return false;
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
      return 60;
    }
  }

  /// 读取备份数据（支持压缩文件）
  Future<BackupData> _readBackupData(
    String filePath, {
    String? password,
  }) async {
    try {
      final file = File(filePath);
      
      // 检查是否为压缩文件
      final isCompressed = await _compressionService.isCompressed(filePath);
      
      String content;
      if (isCompressed) {
        // 解压文件
        final tempPath = '${filePath}.tmp';
        await _compressionService.decompressFile(filePath, tempPath);
        content = await File(tempPath).readAsString();
        await File(tempPath).delete();
      } else {
        content = await file.readAsString();
      }
      
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