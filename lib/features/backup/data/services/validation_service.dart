import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';

import '../../../../core/database/database.dart';
import '../../domain/models/backup_metadata.dart';
import '../../domain/models/backup_data.dart';
import '../../domain/models/backup_exception.dart';
import '../../domain/models/backup_error_type.dart';
import '../../domain/models/validation_result.dart';
import '../../domain/models/integrity_check_result.dart';
import '../../domain/models/compatibility_check_result.dart';
import '../../domain/services/i_validation_service.dart';
import '../../domain/services/i_encryption_service.dart';
import '../repository/data_export_repository.dart';

/// 数据验证服务实现类
class ValidationService implements IValidationService {
  final AppDatabase _database;
  final IEncryptionService _encryptionService;
  final DataExportRepository _dataExportRepository;

  // 支持的备份格式版本
  static const List<String> _supportedBackupVersions = ['1.0.0'];
  
  // 支持的数据库架构版本范围
  static const int _minSupportedSchemaVersion = 1;
  static const int _maxSupportedSchemaVersion = 50;

  ValidationService(
    this._database,
    this._encryptionService,
  ) : _dataExportRepository = DataExportRepository(_database);

  @override
  Future<ValidationResult> validateBackupFormat(
    String filePath, {
    String? password,
  }) async {
    try {
      final file = File(filePath);
      
      // 检查文件是否存在
      if (!await file.exists()) {
        return ValidationResult(
          isValid: false,
          type: ValidationType.fileFormat,
          target: filePath,
          errors: [
            ValidationError(
              code: 'FILE_NOT_FOUND',
              message: '备份文件不存在',
              severity: ErrorSeverity.critical,
            ),
          ],
          repairSuggestions: ['请检查文件路径是否正确', '确认文件未被删除或移动'],
        );
      }

      // 检查文件大小
      final fileSize = await file.length();
      if (fileSize == 0) {
        return ValidationResult(
          isValid: false,
          type: ValidationType.fileFormat,
          target: filePath,
          errors: [
            ValidationError(
              code: 'EMPTY_FILE',
              message: '备份文件为空',
              severity: ErrorSeverity.critical,
            ),
          ],
          repairSuggestions: ['文件可能已损坏，请使用其他备份文件'],
        );
      }

      // 读取文件内容
      String content;
      try {
        content = await file.readAsString();
      } catch (e) {
        return ValidationResult(
          isValid: false,
          type: ValidationType.fileFormat,
          target: filePath,
          errors: [
            ValidationError(
              code: 'FILE_READ_ERROR',
              message: '无法读取备份文件: ${e.toString()}',
              severity: ErrorSeverity.critical,
            ),
          ],
          repairSuggestions: ['检查文件权限', '确认文件未被其他程序占用'],
        );
      }

      // 如果提供了密码，尝试解密
      if (password != null) {
        try {
          content = await _encryptionService.decryptData(content, password);
        } catch (e) {
          return ValidationResult(
            isValid: false,
            type: ValidationType.fileFormat,
            target: filePath,
            errors: [
              ValidationError(
                code: 'DECRYPTION_FAILED',
                message: '解密失败，请检查密码是否正确',
                severity: ErrorSeverity.critical,
              ),
            ],
            repairSuggestions: ['确认密码正确', '检查文件是否确实已加密'],
          );
        }
      }

      // 验证JSON格式
      Map<String, dynamic> jsonData;
      try {
        jsonData = jsonDecode(content) as Map<String, dynamic>;
      } catch (e) {
        return ValidationResult(
          isValid: false,
          type: ValidationType.fileFormat,
          target: filePath,
          errors: [
            ValidationError(
              code: 'INVALID_JSON',
              message: 'JSON格式无效: ${e.toString()}',
              severity: ErrorSeverity.critical,
            ),
          ],
          repairSuggestions: ['文件可能已损坏', '尝试使用文本编辑器检查JSON格式'],
        );
      }

      // 验证基本结构
      final structureErrors = <ValidationError>[];
      final structureWarnings = <ValidationWarning>[];

      if (!jsonData.containsKey('metadata')) {
        structureErrors.add(
          ValidationError(
            code: 'MISSING_METADATA',
            message: '缺少metadata字段',
            severity: ErrorSeverity.critical,
          ),
        );
      }

      if (!jsonData.containsKey('tables')) {
        structureErrors.add(
          ValidationError(
            code: 'MISSING_TABLES',
            message: '缺少tables字段',
            severity: ErrorSeverity.critical,
          ),
        );
      }

      if (structureErrors.isNotEmpty) {
        return ValidationResult(
          isValid: false,
          type: ValidationType.fileFormat,
          target: filePath,
          errors: structureErrors,
          warnings: structureWarnings,
          repairSuggestions: ['文件结构不完整，可能需要重新创建备份'],
        );
      }

      // 验证元数据格式
      try {
        BackupMetadata.fromJson(jsonData['metadata'] as Map<String, dynamic>);
      } catch (e) {
        structureErrors.add(
          ValidationError(
            code: 'INVALID_METADATA_FORMAT',
            message: '元数据格式无效: ${e.toString()}',
            severity: ErrorSeverity.high,
          ),
        );
      }

      // 验证表数据格式
      final tablesData = jsonData['tables'];
      if (tablesData is! Map<String, dynamic>) {
        structureErrors.add(
          ValidationError(
            code: 'INVALID_TABLES_FORMAT',
            message: 'tables字段格式无效，应为对象类型',
            severity: ErrorSeverity.high,
          ),
        );
      } else {
        // 检查每个表的数据格式
        for (final entry in tablesData.entries) {
          final tableName = entry.key;
          final tableData = entry.value;
          
          if (tableData is! List) {
            structureErrors.add(
              ValidationError(
                code: 'INVALID_TABLE_DATA_FORMAT',
                message: '表 $tableName 的数据格式无效，应为数组类型',
                severity: ErrorSeverity.medium,
                location: tableName,
              ),
            );
          }
        }
      }

      final repairSuggestions = <String>[];
      if (structureErrors.isNotEmpty) {
        repairSuggestions.addAll([
          '检查备份文件是否完整',
          '尝试使用其他备份文件',
          '如果是手动编辑的文件，请检查JSON格式',
        ]);
      }

      return ValidationResult(
        isValid: structureErrors.isEmpty,
        type: ValidationType.fileFormat,
        target: filePath,
        errors: structureErrors,
        warnings: structureWarnings,
        repairSuggestions: repairSuggestions,
        details: {
          'fileSize': fileSize,
          'isEncrypted': password != null,
          'tableCount': tablesData is Map ? tablesData.length : 0,
        },
      );

    } catch (e) {
      return ValidationResult(
        isValid: false,
        type: ValidationType.fileFormat,
        target: filePath,
        errors: [
          ValidationError(
            code: 'VALIDATION_ERROR',
            message: '验证过程中发生错误: ${e.toString()}',
            severity: ErrorSeverity.critical,
          ),
        ],
        repairSuggestions: ['请联系技术支持'],
      );
    }
  }

  @override
  Future<CompatibilityCheckResult> checkVersionCompatibility(
    BackupMetadata metadata,
  ) async {
    try {
      final issues = <CompatibilityIssue>[];
      final warnings = <CompatibilityWarning>[];
      final upgradeRecommendations = <String>[];

      // 获取当前版本信息
      final currentSchemaVersion = await _dataExportRepository.getDatabaseSchemaVersion().catchError((_) => 1);
      const currentAppVersion = '1.0.0+1'; // 可以从package info获取
      const currentBackupFormatVersion = '1.0.0';

      // 检查备份格式版本兼容性
      bool backupFormatCompatible = _supportedBackupVersions.contains(metadata.version);
      if (!backupFormatCompatible) {
        issues.add(
          CompatibilityIssue(
            type: CompatibilityIssueType.backupFormatIncompatible,
            description: '备份格式版本 ${metadata.version} 不受支持',
            severity: CompatibilityIssueSeverity.critical,
            suggestedSolution: '请使用支持的备份格式版本: ${_supportedBackupVersions.join(', ')}',
          ),
        );
      }

      // 检查数据库架构版本兼容性
      bool schemaVersionCompatible = true;
      if (metadata.schemaVersion != null) {
        final backupSchemaVersion = metadata.schemaVersion!;
        
        if (backupSchemaVersion < _minSupportedSchemaVersion) {
          schemaVersionCompatible = false;
          issues.add(
            CompatibilityIssue(
              type: CompatibilityIssueType.schemaVersionIncompatible,
              description: '备份的数据库架构版本 $backupSchemaVersion 过旧，不受支持',
              severity: CompatibilityIssueSeverity.critical,
              suggestedSolution: '请升级备份文件或使用更新的备份',
            ),
          );
        } else if (backupSchemaVersion > _maxSupportedSchemaVersion) {
          schemaVersionCompatible = false;
          issues.add(
            CompatibilityIssue(
              type: CompatibilityIssueType.schemaVersionIncompatible,
              description: '备份的数据库架构版本 $backupSchemaVersion 过新，当前应用不支持',
              severity: CompatibilityIssueSeverity.critical,
              suggestedSolution: '请升级应用到最新版本',
            ),
          );
          upgradeRecommendations.add('升级应用到最新版本以支持新的数据库架构');
        } else if (backupSchemaVersion > currentSchemaVersion) {
          warnings.add(
            CompatibilityWarning(
              type: CompatibilityWarningType.versionGapLarge,
              description: '备份的架构版本 $backupSchemaVersion 比当前版本 $currentSchemaVersion 新',
            ),
          );
          upgradeRecommendations.add('建议升级应用以获得最佳兼容性');
        } else if (currentSchemaVersion - backupSchemaVersion > 10) {
          warnings.add(
            CompatibilityWarning(
              type: CompatibilityWarningType.versionGapLarge,
              description: '备份的架构版本 $backupSchemaVersion 与当前版本 $currentSchemaVersion 差距较大',
            ),
          );
        }
      }

      // 检查应用版本兼容性
      bool appVersionCompatible = true;
      if (metadata.appVersion != null) {
        // 这里可以添加更复杂的版本比较逻辑
        // 目前简单地检查主版本号
        final backupAppVersion = metadata.appVersion!;
        final currentMajorVersion = currentAppVersion.split('.')[0];
        final backupMajorVersion = backupAppVersion.split('.')[0];
        
        if (backupMajorVersion != currentMajorVersion) {
          appVersionCompatible = false;
          issues.add(
            CompatibilityIssue(
              type: CompatibilityIssueType.appVersionIncompatible,
              description: '备份的应用版本 $backupAppVersion 与当前版本 $currentAppVersion 主版本不匹配',
              severity: CompatibilityIssueSeverity.warning,
              suggestedSolution: '可以尝试恢复，但可能存在兼容性问题',
            ),
          );
        }
      }

      // 检查表结构兼容性（基本检查）
      final tableCompatibility = <String, bool>{};
      final currentTables = await _dataExportRepository.getAllTableNames().catchError((_) => <String>[]);
      
      for (final tableName in metadata.tableCounts.keys) {
        final isCompatible = currentTables.contains(tableName);
        tableCompatibility[tableName] = isCompatible;
        
        if (!isCompatible) {
          issues.add(
            CompatibilityIssue(
              type: CompatibilityIssueType.unknownTable,
              description: '表 $tableName 在当前数据库中不存在',
              severity: CompatibilityIssueSeverity.warning,
              affectedComponent: tableName,
              suggestedSolution: '该表的数据将被跳过',
            ),
          );
        }
      }

      final details = CompatibilityDetails(
        currentAppVersion: currentAppVersion,
        backupAppVersion: metadata.appVersion ?? 'unknown',
        currentSchemaVersion: currentSchemaVersion,
        backupSchemaVersion: metadata.schemaVersion ?? 0,
        currentBackupFormatVersion: currentBackupFormatVersion,
        backupFormatVersion: metadata.version,
        minSupportedSchemaVersion: _minSupportedSchemaVersion,
        maxSupportedSchemaVersion: _maxSupportedSchemaVersion,
        supportedBackupFormatVersions: _supportedBackupVersions,
      );

      final isCompatible = backupFormatCompatible && 
                          schemaVersionCompatible && 
                          appVersionCompatible &&
                          issues.where((i) => i.severity == CompatibilityIssueSeverity.critical).isEmpty;

      return CompatibilityCheckResult(
        isCompatible: isCompatible,
        appVersionCompatible: appVersionCompatible,
        schemaVersionCompatible: schemaVersionCompatible,
        backupFormatCompatible: backupFormatCompatible,
        tableCompatibility: tableCompatibility,
        issues: issues,
        warnings: warnings,
        upgradeRecommendations: upgradeRecommendations,
        details: details,
      );

    } catch (e) {
      throw BackupException(
        type: BackupErrorType.validationError,
        message: '版本兼容性检查失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<IntegrityCheckResult> validateDataIntegrity(
    Map<String, List<Map<String, dynamic>>> tablesData,
    BackupMetadata metadata,
  ) async {
    try {
      final missingRelationships = <MissingRelationship>[];
      final orphanedRecords = <OrphanedRecord>[];
      final duplicateRecords = <DuplicateRecord>[];
      final tableIntegrityResults = <String, bool>{};
      final detailedResults = <ValidationResult>[];

      int totalRecords = 0;
      int validRecords = 0;
      final tableRecordCounts = <String, int>{};
      final tableValidRecordCounts = <String, int>{};

      // 验证校验和
      final tablesJson = jsonEncode(tablesData);
      final actualChecksum = _dataExportRepository.generateChecksum(tablesJson);
      final checksumValid = actualChecksum == metadata.checksum;

      if (!checksumValid) {
        detailedResults.add(
          ValidationResult(
            isValid: false,
            type: ValidationType.dataIntegrity,
            target: 'checksum',
            errors: [
              ValidationError(
                code: 'CHECKSUM_MISMATCH',
                message: '数据校验和不匹配，文件可能已损坏',
                severity: ErrorSeverity.critical,
              ),
            ],
            repairSuggestions: ['使用其他备份文件', '重新创建备份'],
          ),
        );
      }

      // 验证每个表的数据完整性
      for (final entry in tablesData.entries) {
        final tableName = entry.key;
        final records = entry.value;
        
        tableRecordCounts[tableName] = records.length;
        totalRecords += records.length;

        // 验证表数据完整性
        final tableResult = await _validateTableIntegrity(tableName, records);
        tableIntegrityResults[tableName] = tableResult.isValid;
        detailedResults.add(tableResult);

        if (tableResult.isValid) {
          tableValidRecordCounts[tableName] = records.length;
          validRecords += records.length;
        } else {
          tableValidRecordCounts[tableName] = 0;
        }

        // 检查重复记录
        final duplicates = await _findDuplicateRecords(tableName, records);
        duplicateRecords.addAll(duplicates);
      }

      // 验证外键关系
      final foreignKeyResult = await validateForeignKeyRelationships(tablesData);
      detailedResults.add(foreignKeyResult);

      if (!foreignKeyResult.isValid) {
        // 从验证结果中提取缺失关系信息
        for (final error in foreignKeyResult.errors) {
          if (error.code == 'MISSING_FOREIGN_KEY') {
            final details = error.details;
            if (details != null) {
              missingRelationships.add(
                MissingRelationship(
                  sourceTable: details['sourceTable'] as String,
                  targetTable: details['targetTable'] as String,
                  foreignKeyField: details['foreignKeyField'] as String,
                  missingValue: details['missingValue'],
                  affectedRecordCount: details['affectedRecordCount'] as int,
                ),
              );
            }
          }
        }
      }

      // 查找孤立记录
      final orphans = await _findOrphanedRecords(tablesData);
      orphanedRecords.addAll(orphans);

      final statistics = IntegrityStatistics(
        totalRecords: totalRecords,
        validRecords: validRecords,
        invalidRecords: totalRecords - validRecords,
        missingRelationshipCount: missingRelationships.length,
        orphanedRecordCount: orphanedRecords.length,
        duplicateRecordCount: duplicateRecords.length,
        tableRecordCounts: tableRecordCounts,
        tableValidRecordCounts: tableValidRecordCounts,
      );

      final relationshipIntegrityValid = missingRelationships.isEmpty && orphanedRecords.isEmpty;
      final isIntegrityValid = checksumValid && 
                              relationshipIntegrityValid && 
                              duplicateRecords.isEmpty &&
                              tableIntegrityResults.values.every((valid) => valid);

      return IntegrityCheckResult(
        isIntegrityValid: isIntegrityValid,
        checksumValid: checksumValid,
        relationshipIntegrityValid: relationshipIntegrityValid,
        tableIntegrityResults: tableIntegrityResults,
        missingRelationships: missingRelationships,
        orphanedRecords: orphanedRecords,
        duplicateRecords: duplicateRecords,
        statistics: statistics,
        detailedResults: detailedResults,
      );

    } catch (e) {
      throw BackupException(
        type: BackupErrorType.validationError,
        message: '数据完整性验证失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<ValidationResult> detectFileCorruption(
    String filePath, {
    String? password,
  }) async {
    try {
      final errors = <ValidationError>[];
      final warnings = <ValidationWarning>[];
      final repairSuggestions = <String>[];

      final file = File(filePath);
      
      // 基本文件检查
      if (!await file.exists()) {
        return ValidationResult(
          isValid: false,
          type: ValidationType.fileCorruption,
          target: filePath,
          errors: [
            ValidationError(
              code: 'FILE_NOT_FOUND',
              message: '文件不存在',
              severity: ErrorSeverity.critical,
            ),
          ],
          repairSuggestions: ['检查文件路径', '确认文件未被删除'],
        );
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        errors.add(
          ValidationError(
            code: 'EMPTY_FILE',
            message: '文件为空',
            severity: ErrorSeverity.critical,
          ),
        );
        repairSuggestions.add('文件已损坏，请使用其他备份');
      }

      // 读取文件并检查格式
      String content;
      try {
        content = await file.readAsString();
      } catch (e) {
        errors.add(
          ValidationError(
            code: 'FILE_READ_ERROR',
            message: '无法读取文件: ${e.toString()}',
            severity: ErrorSeverity.critical,
          ),
        );
        repairSuggestions.addAll(['检查文件权限', '确认文件未被占用']);
        
        return ValidationResult(
          isValid: false,
          type: ValidationType.fileCorruption,
          target: filePath,
          errors: errors,
          repairSuggestions: repairSuggestions,
        );
      }

      // 如果文件加密，尝试解密
      if (password != null) {
        try {
          content = await _encryptionService.decryptData(content, password);
        } catch (e) {
          errors.add(
            ValidationError(
              code: 'DECRYPTION_FAILED',
              message: '解密失败，可能是密码错误或文件损坏',
              severity: ErrorSeverity.high,
            ),
          );
          repairSuggestions.addAll(['确认密码正确', '检查文件完整性']);
        }
      }

      // JSON格式检查
      Map<String, dynamic> jsonData;
      try {
        jsonData = jsonDecode(content) as Map<String, dynamic>;
      } catch (e) {
        errors.add(
          ValidationError(
            code: 'JSON_CORRUPTION',
            message: 'JSON格式损坏: ${e.toString()}',
            severity: ErrorSeverity.critical,
          ),
        );
        repairSuggestions.addAll([
          '文件JSON结构已损坏',
          '尝试使用文本编辑器修复JSON格式',
          '使用其他备份文件',
        ]);
        
        return ValidationResult(
          isValid: false,
          type: ValidationType.fileCorruption,
          target: filePath,
          errors: errors,
          repairSuggestions: repairSuggestions,
        );
      }

      // 结构完整性检查
      final structureIssues = await _checkStructuralIntegrity(jsonData);
      errors.addAll(structureIssues);

      // 数据完整性检查（如果有元数据）
      if (jsonData.containsKey('metadata') && jsonData.containsKey('tables')) {
        try {
          final metadata = BackupMetadata.fromJson(
            jsonData['metadata'] as Map<String, dynamic>,
          );
          final tablesData = jsonData['tables'] as Map<String, dynamic>;
          
          // 校验和验证
          final tablesJson = jsonEncode(tablesData);
          final actualChecksum = _dataExportRepository.generateChecksum(tablesJson);
          
          if (actualChecksum != metadata.checksum) {
            errors.add(
              ValidationError(
                code: 'CHECKSUM_MISMATCH',
                message: '数据校验和不匹配，数据可能已损坏',
                severity: ErrorSeverity.high,
              ),
            );
            repairSuggestions.add('数据完整性受损，建议使用其他备份');
          }

          // 记录数量验证
          for (final entry in metadata.tableCounts.entries) {
            final tableName = entry.key;
            final expectedCount = entry.value;
            
            if (tablesData.containsKey(tableName)) {
              final actualData = tablesData[tableName];
              if (actualData is List) {
                final actualCount = actualData.length;
                if (actualCount != expectedCount) {
                  warnings.add(
                    ValidationWarning(
                      code: 'RECORD_COUNT_MISMATCH',
                      message: '表 $tableName 记录数不匹配：期望 $expectedCount，实际 $actualCount',
                      location: tableName,
                    ),
                  );
                }
              }
            }
          }
        } catch (e) {
          errors.add(
            ValidationError(
              code: 'METADATA_CORRUPTION',
              message: '元数据损坏: ${e.toString()}',
              severity: ErrorSeverity.high,
            ),
          );
        }
      }

      // 生成修复建议
      if (errors.isNotEmpty) {
        repairSuggestions.addAll(_generateCorruptionRepairSuggestions(errors));
      }

      return ValidationResult(
        isValid: errors.isEmpty,
        type: ValidationType.fileCorruption,
        target: filePath,
        errors: errors,
        warnings: warnings,
        repairSuggestions: repairSuggestions,
        details: {
          'fileSize': fileSize,
          'hasMetadata': jsonData.containsKey('metadata'),
          'hasTables': jsonData.containsKey('tables'),
          'tableCount': jsonData.containsKey('tables') 
              ? (jsonData['tables'] as Map).length 
              : 0,
        },
      );

    } catch (e) {
      return ValidationResult(
        isValid: false,
        type: ValidationType.fileCorruption,
        target: filePath,
        errors: [
          ValidationError(
            code: 'CORRUPTION_CHECK_FAILED',
            message: '损坏检测失败: ${e.toString()}',
            severity: ErrorSeverity.critical,
          ),
        ],
        repairSuggestions: ['请联系技术支持'],
      );
    }
  }

  @override
  Future<ValidationResult> preRestoreValidation(
    String filePath, {
    List<String>? selectedTables,
    String? password,
  }) async {
    try {
      final errors = <ValidationError>[];
      final warnings = <ValidationWarning>[];
      final repairSuggestions = <String>[];

      // 1. 文件格式验证
      final formatResult = await validateBackupFormat(filePath, password: password);
      if (!formatResult.isValid) {
        errors.addAll(formatResult.errors);
        repairSuggestions.addAll(formatResult.repairSuggestions);
        
        return ValidationResult(
          isValid: false,
          type: ValidationType.preRestoreCheck,
          target: filePath,
          errors: errors,
          warnings: warnings,
          repairSuggestions: repairSuggestions,
        );
      }

      // 2. 读取备份数据
      final backupData = await _readBackupData(filePath, password: password);

      // 3. 版本兼容性检查
      final compatibilityResult = await checkVersionCompatibility(backupData.metadata);
      if (!compatibilityResult.isCompatible) {
        for (final issue in compatibilityResult.issues) {
          if (issue.severity == CompatibilityIssueSeverity.critical) {
            errors.add(
              ValidationError(
                code: 'COMPATIBILITY_ERROR',
                message: issue.description,
                severity: ErrorSeverity.critical,
                details: {'issueType': issue.type.toString()},
              ),
            );
          } else {
            warnings.add(
              ValidationWarning(
                code: 'COMPATIBILITY_WARNING',
                message: issue.description,
                details: {'issueType': issue.type.toString()},
              ),
            );
          }
        }
        repairSuggestions.addAll(compatibilityResult.upgradeRecommendations);
      }

      // 4. 数据完整性验证
      final integrityResult = await validateDataIntegrity(
        backupData.tables,
        backupData.metadata,
      );
      
      if (!integrityResult.isIntegrityValid) {
        errors.add(
          ValidationError(
            code: 'DATA_INTEGRITY_ERROR',
            message: '数据完整性验证失败',
            severity: ErrorSeverity.high,
            details: {
              'checksumValid': integrityResult.checksumValid,
              'relationshipIntegrityValid': integrityResult.relationshipIntegrityValid,
              'missingRelationships': integrityResult.missingRelationships.length,
              'orphanedRecords': integrityResult.orphanedRecords.length,
            },
          ),
        );
        repairSuggestions.add('数据完整性受损，恢复可能不完整');
      }

      // 5. 选定表的验证
      if (selectedTables != null) {
        for (final tableName in selectedTables) {
          if (!backupData.tables.containsKey(tableName)) {
            errors.add(
              ValidationError(
                code: 'SELECTED_TABLE_NOT_FOUND',
                message: '选定的表 $tableName 在备份中不存在',
                severity: ErrorSeverity.medium,
                location: tableName,
              ),
            );
          } else {
            // 验证表结构
            final tableData = backupData.tables[tableName]!;
            if (tableData.isNotEmpty) {
              final structureResult = await validateTableStructure(
                tableName,
                tableData.first,
              );
              if (!structureResult.isValid) {
                errors.addAll(structureResult.errors);
                warnings.addAll(structureResult.warnings);
              }
            }
          }
        }
      }

      // 6. 存储空间检查
      final estimatedSize = backupData.metadata.fileSize;
      // 这里可以添加磁盘空间检查逻辑
      if (estimatedSize > 1024 * 1024 * 1024) { // 1GB
        warnings.add(
          ValidationWarning(
            code: 'LARGE_RESTORE_SIZE',
            message: '恢复数据量较大，可能需要较长时间',
            details: {'estimatedSize': estimatedSize},
          ),
        );
      }

      // 生成综合修复建议
      if (errors.isNotEmpty || warnings.isNotEmpty) {
        repairSuggestions.addAll(_generatePreRestoreRepairSuggestions(errors, warnings));
      }

      return ValidationResult(
        isValid: errors.isEmpty,
        type: ValidationType.preRestoreCheck,
        target: filePath,
        errors: errors,
        warnings: warnings,
        repairSuggestions: repairSuggestions,
        details: {
          'selectedTableCount': selectedTables?.length ?? backupData.tables.length,
          'totalRecords': integrityResult.statistics.totalRecords,
          'estimatedSize': estimatedSize,
          'compatibilityScore': _calculateCompatibilityScore(compatibilityResult),
        },
      );

    } catch (e) {
      return ValidationResult(
        isValid: false,
        type: ValidationType.preRestoreCheck,
        target: filePath,
        errors: [
          ValidationError(
            code: 'PRE_RESTORE_CHECK_FAILED',
            message: '恢复前检查失败: ${e.toString()}',
            severity: ErrorSeverity.critical,
          ),
        ],
        repairSuggestions: ['请检查备份文件完整性'],
      );
    }
  }

  @override
  Future<ValidationResult> validateTableStructure(
    String tableName,
    Map<String, dynamic> backupTableData,
  ) async {
    try {
      final errors = <ValidationError>[];
      final warnings = <ValidationWarning>[];

      // 检查表是否存在
      final tableExists = await _tableExists(tableName);
      if (!tableExists) {
        return ValidationResult(
          isValid: false,
          type: ValidationType.tableStructure,
          target: tableName,
          errors: [
            ValidationError(
              code: 'TABLE_NOT_EXISTS',
              message: '表 $tableName 在当前数据库中不存在',
              severity: ErrorSeverity.high,
              location: tableName,
            ),
          ],
          repairSuggestions: ['该表的数据将被跳过', '检查数据库架构是否匹配'],
        );
      }

      // 获取当前表结构
      final currentTableInfo = await _getTableInfo(tableName);
      final currentColumns = currentTableInfo.map((col) => col['name'] as String).toSet();

      // 检查备份数据中的字段
      final backupColumns = backupTableData.keys.toSet();

      // 检查缺失的必需字段
      final requiredColumns = currentTableInfo
          .where((col) => col['notnull'] == 1 && col['dflt_value'] == null)
          .map((col) => col['name'] as String)
          .toSet();

      final missingRequiredColumns = requiredColumns.difference(backupColumns);
      for (final column in missingRequiredColumns) {
        errors.add(
          ValidationError(
            code: 'MISSING_REQUIRED_COLUMN',
            message: '缺少必需字段: $column',
            severity: ErrorSeverity.high,
            location: '$tableName.$column',
          ),
        );
      }

      // 检查未知字段
      final unknownColumns = backupColumns.difference(currentColumns);
      for (final column in unknownColumns) {
        warnings.add(
          ValidationWarning(
            code: 'UNKNOWN_COLUMN',
            message: '未知字段: $column，将被忽略',
            location: '$tableName.$column',
          ),
        );
      }

      // 检查字段类型兼容性
      for (final column in backupColumns.intersection(currentColumns)) {
        final currentColumnInfo = currentTableInfo.firstWhere(
          (col) => col['name'] == column,
        );
        final currentType = currentColumnInfo['type'] as String;
        final backupValue = backupTableData[column];
        
        if (backupValue != null && !_isTypeCompatible(currentType, backupValue)) {
          errors.add(
            ValidationError(
              code: 'TYPE_INCOMPATIBLE',
              message: '字段 $column 类型不兼容：期望 $currentType，实际 ${backupValue.runtimeType}',
              severity: ErrorSeverity.medium,
              location: '$tableName.$column',
            ),
          );
        }
      }

      final repairSuggestions = <String>[];
      if (errors.isNotEmpty) {
        repairSuggestions.addAll([
          '检查数据库架构版本',
          '考虑升级数据库架构',
          '手动处理不兼容的字段',
        ]);
      }

      return ValidationResult(
        isValid: errors.isEmpty,
        type: ValidationType.tableStructure,
        target: tableName,
        errors: errors,
        warnings: warnings,
        repairSuggestions: repairSuggestions,
        details: {
          'currentColumns': currentColumns.toList(),
          'backupColumns': backupColumns.toList(),
          'missingColumns': missingRequiredColumns.toList(),
          'unknownColumns': unknownColumns.toList(),
        },
      );

    } catch (e) {
      return ValidationResult(
        isValid: false,
        type: ValidationType.tableStructure,
        target: tableName,
        errors: [
          ValidationError(
            code: 'TABLE_STRUCTURE_CHECK_FAILED',
            message: '表结构验证失败: ${e.toString()}',
            severity: ErrorSeverity.critical,
          ),
        ],
        repairSuggestions: ['请检查数据库连接和表结构'],
      );
    }
  }

  @override
  Future<ValidationResult> validateDataTypes(
    String tableName,
    List<Map<String, dynamic>> records,
  ) async {
    try {
      final errors = <ValidationError>[];
      final warnings = <ValidationWarning>[];

      if (records.isEmpty) {
        return ValidationResult(
          isValid: true,
          type: ValidationType.dataTypes,
          target: tableName,
        );
      }

      // 获取表结构信息
      final tableInfo = await _getTableInfo(tableName);
      final columnTypes = <String, String>{};
      
      for (final col in tableInfo) {
        columnTypes[col['name'] as String] = col['type'] as String;
      }

      // 验证每条记录的数据类型
      for (int i = 0; i < records.length; i++) {
        final record = records[i];
        
        for (final entry in record.entries) {
          final columnName = entry.key;
          final value = entry.value;
          
          if (value == null) continue;
          
          final expectedType = columnTypes[columnName];
          if (expectedType != null && !_isTypeCompatible(expectedType, value)) {
            errors.add(
              ValidationError(
                code: 'DATA_TYPE_MISMATCH',
                message: '记录 ${i + 1} 字段 $columnName 类型不匹配：期望 $expectedType，实际 ${value.runtimeType}',
                severity: ErrorSeverity.medium,
                location: '$tableName.$columnName[${i + 1}]',
                details: {
                  'recordIndex': i,
                  'expectedType': expectedType,
                  'actualType': value.runtimeType.toString(),
                  'value': value,
                },
              ),
            );
          }
        }
      }

      return ValidationResult(
        isValid: errors.isEmpty,
        type: ValidationType.dataTypes,
        target: tableName,
        errors: errors,
        warnings: warnings,
        repairSuggestions: errors.isNotEmpty 
            ? ['检查数据类型转换', '清理无效数据', '更新表结构定义']
            : [],
        details: {
          'recordCount': records.length,
          'columnTypes': columnTypes,
          'errorCount': errors.length,
        },
      );

    } catch (e) {
      return ValidationResult(
        isValid: false,
        type: ValidationType.dataTypes,
        target: tableName,
        errors: [
          ValidationError(
            code: 'DATA_TYPE_CHECK_FAILED',
            message: '数据类型验证失败: ${e.toString()}',
            severity: ErrorSeverity.critical,
          ),
        ],
        repairSuggestions: ['请检查表结构和数据格式'],
      );
    }
  } 
 @override
  Future<ValidationResult> validateForeignKeyRelationships(
    Map<String, List<Map<String, dynamic>>> tablesData,
  ) async {
    try {
      final errors = <ValidationError>[];
      final warnings = <ValidationWarning>[];

      // 定义外键关系映射
      final foreignKeyRelationships = await _getForeignKeyRelationships();

      for (final relationship in foreignKeyRelationships) {
        final sourceTable = relationship['sourceTable'] as String;
        final targetTable = relationship['targetTable'] as String;
        final foreignKeyField = relationship['foreignKeyField'] as String;
        final targetKeyField = relationship['targetKeyField'] as String;

        if (!tablesData.containsKey(sourceTable) || !tablesData.containsKey(targetTable)) {
          continue; // 跳过不存在的表
        }

        final sourceRecords = tablesData[sourceTable]!;
        final targetRecords = tablesData[targetTable]!;

        // 构建目标表的主键集合
        final targetKeys = <dynamic>{};
        for (final record in targetRecords) {
          final keyValue = record[targetKeyField];
          if (keyValue != null) {
            targetKeys.add(keyValue);
          }
        }

        // 检查源表中的外键引用
        int missingCount = 0;
        for (final record in sourceRecords) {
          final foreignKeyValue = record[foreignKeyField];
          if (foreignKeyValue != null && !targetKeys.contains(foreignKeyValue)) {
            missingCount++;
          }
        }

        if (missingCount > 0) {
          errors.add(
            ValidationError(
              code: 'MISSING_FOREIGN_KEY',
              message: '表 $sourceTable 中有 $missingCount 条记录的外键 $foreignKeyField 在目标表 $targetTable 中不存在',
              severity: ErrorSeverity.high,
              location: '$sourceTable.$foreignKeyField',
              details: {
                'sourceTable': sourceTable,
                'targetTable': targetTable,
                'foreignKeyField': foreignKeyField,
                'missingValue': null, // 这里可以记录具体的缺失值
                'affectedRecordCount': missingCount,
              },
            ),
          );
        }
      }

      return ValidationResult(
        isValid: errors.isEmpty,
        type: ValidationType.foreignKeyRelationships,
        target: 'all_tables',
        errors: errors,
        warnings: warnings,
        repairSuggestions: errors.isNotEmpty 
            ? ['检查数据导入顺序', '修复缺失的关联记录', '考虑禁用外键约束检查']
            : [],
        details: {
          'checkedRelationships': foreignKeyRelationships.length,
          'violationCount': errors.length,
        },
      );

    } catch (e) {
      return ValidationResult(
        isValid: false,
        type: ValidationType.foreignKeyRelationships,
        target: 'all_tables',
        errors: [
          ValidationError(
            code: 'FOREIGN_KEY_CHECK_FAILED',
            message: '外键关系验证失败: ${e.toString()}',
            severity: ErrorSeverity.critical,
          ),
        ],
        repairSuggestions: ['请检查数据库架构和外键定义'],
      );
    }
  }

  @override
  Future<ValidationResult> validateDataConstraints(
    String tableName,
    List<Map<String, dynamic>> records,
  ) async {
    try {
      final errors = <ValidationError>[];
      final warnings = <ValidationWarning>[];

      if (records.isEmpty) {
        return ValidationResult(
          isValid: true,
          type: ValidationType.dataConstraints,
          target: tableName,
        );
      }

      // 获取表约束信息
      final constraints = await _getTableConstraints(tableName);

      for (int i = 0; i < records.length; i++) {
        final record = records[i];

        // 检查NOT NULL约束
        for (final constraint in constraints) {
          if (constraint['type'] == 'NOT NULL') {
            final columnName = constraint['column'] as String;
            if (!record.containsKey(columnName) || record[columnName] == null) {
              errors.add(
                ValidationError(
                  code: 'NOT_NULL_VIOLATION',
                  message: '记录 ${i + 1} 违反NOT NULL约束：字段 $columnName 不能为空',
                  severity: ErrorSeverity.high,
                  location: '$tableName.$columnName[${i + 1}]',
                  details: {
                    'recordIndex': i,
                    'constraintType': 'NOT NULL',
                    'columnName': columnName,
                  },
                ),
              );
            }
          }

          // 检查UNIQUE约束
          if (constraint['type'] == 'UNIQUE') {
            final columnName = constraint['column'] as String;
            final value = record[columnName];
            
            if (value != null) {
              // 检查在当前记录集中是否有重复
              final duplicateCount = records
                  .where((r) => r[columnName] == value)
                  .length;
              
              if (duplicateCount > 1) {
                warnings.add(
                  ValidationWarning(
                    code: 'UNIQUE_VIOLATION',
                    message: '字段 $columnName 的值 $value 在多条记录中重复',
                    location: '$tableName.$columnName',
                    details: {
                      'constraintType': 'UNIQUE',
                      'columnName': columnName,
                      'duplicateValue': value,
                      'duplicateCount': duplicateCount,
                    },
                  ),
                );
              }
            }
          }

          // 检查CHECK约束（如果有定义）
          if (constraint['type'] == 'CHECK') {
            final checkExpression = constraint['expression'] as String?;
            if (checkExpression != null) {
              // 这里可以添加更复杂的CHECK约束验证逻辑
              // 目前只是记录警告
              warnings.add(
                ValidationWarning(
                  code: 'CHECK_CONSTRAINT_FOUND',
                  message: '表 $tableName 有CHECK约束，请手动验证: $checkExpression',
                  location: tableName,
                ),
              );
            }
          }
        }
      }

      return ValidationResult(
        isValid: errors.isEmpty,
        type: ValidationType.dataConstraints,
        target: tableName,
        errors: errors,
        warnings: warnings,
        repairSuggestions: errors.isNotEmpty 
            ? ['修复约束违反的数据', '检查数据完整性', '考虑临时禁用约束']
            : [],
        details: {
          'recordCount': records.length,
          'constraintCount': constraints.length,
          'violationCount': errors.length,
        },
      );

    } catch (e) {
      return ValidationResult(
        isValid: false,
        type: ValidationType.dataConstraints,
        target: tableName,
        errors: [
          ValidationError(
            code: 'CONSTRAINT_CHECK_FAILED',
            message: '数据约束验证失败: ${e.toString()}',
            severity: ErrorSeverity.critical,
          ),
        ],
        repairSuggestions: ['请检查表约束定义'],
      );
    }
  }

  @override
  List<String> generateRepairSuggestions(
    List<ValidationResult> validationResults,
  ) {
    final suggestions = <String>[];
    final errorCodes = <String>{};

    // 收集所有错误代码
    for (final result in validationResults) {
      for (final error in result.errors) {
        errorCodes.add(error.code);
      }
    }

    // 基于错误类型生成建议
    if (errorCodes.contains('FILE_NOT_FOUND')) {
      suggestions.add('检查备份文件路径是否正确');
    }

    if (errorCodes.contains('JSON_CORRUPTION') || errorCodes.contains('CHECKSUM_MISMATCH')) {
      suggestions.addAll([
        '备份文件可能已损坏，建议使用其他备份文件',
        '如果是唯一备份，可尝试使用数据恢复工具',
      ]);
    }

    if (errorCodes.contains('COMPATIBILITY_ERROR')) {
      suggestions.addAll([
        '升级应用到最新版本',
        '检查备份文件版本兼容性',
        '考虑使用版本转换工具',
      ]);
    }

    if (errorCodes.contains('TABLE_NOT_EXISTS')) {
      suggestions.addAll([
        '更新数据库架构',
        '跳过不存在的表',
        '手动创建缺失的表结构',
      ]);
    }

    if (errorCodes.contains('MISSING_FOREIGN_KEY')) {
      suggestions.addAll([
        '调整数据导入顺序',
        '临时禁用外键约束',
        '修复缺失的关联数据',
      ]);
    }

    if (errorCodes.contains('DATA_TYPE_MISMATCH')) {
      suggestions.addAll([
        '检查数据类型转换规则',
        '清理不兼容的数据',
        '更新表结构定义',
      ]);
    }

    // 通用建议
    if (suggestions.isEmpty && errorCodes.isNotEmpty) {
      suggestions.addAll([
        '检查备份文件完整性',
        '确认数据库架构版本匹配',
        '联系技术支持获取帮助',
      ]);
    }

    return suggestions.toList();
  }

  // 私有辅助方法

  /// 读取备份数据
  Future<BackupData> _readBackupData(
    String filePath, {
    String? password,
  }) async {
    try {
      final file = File(filePath);
      String content = await file.readAsString();
      
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

  /// 验证表完整性
  Future<ValidationResult> _validateTableIntegrity(
    String tableName,
    List<Map<String, dynamic>> records,
  ) async {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];

    try {
      // 检查记录格式一致性
      if (records.isNotEmpty) {
        final firstRecordKeys = records.first.keys.toSet();
        
        for (int i = 1; i < records.length; i++) {
          final currentKeys = records[i].keys.toSet();
          if (!currentKeys.containsAll(firstRecordKeys) || 
              !firstRecordKeys.containsAll(currentKeys)) {
            warnings.add(
              ValidationWarning(
                code: 'INCONSISTENT_RECORD_FORMAT',
                message: '记录 ${i + 1} 的字段结构与第一条记录不一致',
                location: '$tableName[${i + 1}]',
              ),
            );
          }
        }
      }

      // 检查空记录
      final emptyRecordCount = records.where((record) => 
          record.values.every((value) => value == null || value == '')).length;
      
      if (emptyRecordCount > 0) {
        warnings.add(
          ValidationWarning(
            code: 'EMPTY_RECORDS_FOUND',
            message: '发现 $emptyRecordCount 条空记录',
            location: tableName,
          ),
        );
      }

      return ValidationResult(
        isValid: errors.isEmpty,
        type: ValidationType.dataIntegrity,
        target: tableName,
        errors: errors,
        warnings: warnings,
        details: {
          'recordCount': records.length,
          'emptyRecordCount': emptyRecordCount,
        },
      );

    } catch (e) {
      return ValidationResult(
        isValid: false,
        type: ValidationType.dataIntegrity,
        target: tableName,
        errors: [
          ValidationError(
            code: 'TABLE_INTEGRITY_CHECK_FAILED',
            message: '表完整性检查失败: ${e.toString()}',
            severity: ErrorSeverity.critical,
          ),
        ],
      );
    }
  }

  /// 查找重复记录
  Future<List<DuplicateRecord>> _findDuplicateRecords(
    String tableName,
    List<Map<String, dynamic>> records,
  ) async {
    final duplicates = <DuplicateRecord>[];
    
    try {
      // 获取主键字段
      final primaryKey = await _getPrimaryKeyColumn(tableName);
      if (primaryKey == null) return duplicates;

      // 按主键分组查找重复
      final keyGroups = <dynamic, List<Map<String, dynamic>>>{};
      
      for (final record in records) {
        final keyValue = record[primaryKey];
        if (keyValue != null) {
          keyGroups.putIfAbsent(keyValue, () => []).add(record);
        }
      }

      // 找出重复的组
      for (final entry in keyGroups.entries) {
        if (entry.value.length > 1) {
          duplicates.add(
            DuplicateRecord(
              tableName: tableName,
              duplicateFields: [primaryKey],
              duplicateValues: {primaryKey: entry.key},
              duplicateCount: entry.value.length,
              duplicatePrimaryKeys: [entry.key],
            ),
          );
        }
      }

      return duplicates;
    } catch (e) {
      return duplicates;
    }
  }

  /// 查找孤立记录
  Future<List<OrphanedRecord>> _findOrphanedRecords(
    Map<String, List<Map<String, dynamic>>> tablesData,
  ) async {
    final orphans = <OrphanedRecord>[];
    
    try {
      final foreignKeyRelationships = await _getForeignKeyRelationships();

      for (final relationship in foreignKeyRelationships) {
        final sourceTable = relationship['sourceTable'] as String;
        final targetTable = relationship['targetTable'] as String;
        final foreignKeyField = relationship['foreignKeyField'] as String;
        final targetKeyField = relationship['targetKeyField'] as String;

        if (!tablesData.containsKey(sourceTable) || !tablesData.containsKey(targetTable)) {
          continue;
        }

        final sourceRecords = tablesData[sourceTable]!;
        final targetRecords = tablesData[targetTable]!;

        // 构建目标表的主键集合
        final targetKeys = <dynamic>{};
        for (final record in targetRecords) {
          final keyValue = record[targetKeyField];
          if (keyValue != null) {
            targetKeys.add(keyValue);
          }
        }

        // 查找孤立记录
        for (final record in sourceRecords) {
          final foreignKeyValue = record[foreignKeyField];
          if (foreignKeyValue != null && !targetKeys.contains(foreignKeyValue)) {
            final primaryKey = await _getPrimaryKeyColumn(sourceTable);
            orphans.add(
              OrphanedRecord(
                tableName: sourceTable,
                primaryKeyField: primaryKey ?? 'id',
                primaryKeyValue: record[primaryKey] ?? 'unknown',
                reason: '外键 $foreignKeyField 值 $foreignKeyValue 在目标表 $targetTable 中不存在',
                recordData: record,
              ),
            );
          }
        }
      }

      return orphans;
    } catch (e) {
      return orphans;
    }
  }

  /// 检查结构完整性
  Future<List<ValidationError>> _checkStructuralIntegrity(
    Map<String, dynamic> jsonData,
  ) async {
    final errors = <ValidationError>[];

    // 检查必需字段
    if (!jsonData.containsKey('metadata')) {
      errors.add(
        ValidationError(
          code: 'MISSING_METADATA',
          message: '缺少metadata字段',
          severity: ErrorSeverity.critical,
        ),
      );
    }

    if (!jsonData.containsKey('tables')) {
      errors.add(
        ValidationError(
          code: 'MISSING_TABLES',
          message: '缺少tables字段',
          severity: ErrorSeverity.critical,
        ),
      );
    }

    // 检查metadata结构
    if (jsonData.containsKey('metadata')) {
      final metadata = jsonData['metadata'];
      if (metadata is! Map<String, dynamic>) {
        errors.add(
          ValidationError(
            code: 'INVALID_METADATA_TYPE',
            message: 'metadata字段类型无效',
            severity: ErrorSeverity.high,
          ),
        );
      } else {
        // 检查metadata必需字段
        final requiredMetadataFields = ['id', 'fileName', 'createdAt', 'version', 'checksum'];
        for (final field in requiredMetadataFields) {
          if (!metadata.containsKey(field)) {
            errors.add(
              ValidationError(
                code: 'MISSING_METADATA_FIELD',
                message: 'metadata缺少必需字段: $field',
                severity: ErrorSeverity.high,
              ),
            );
          }
        }
      }
    }

    // 检查tables结构
    if (jsonData.containsKey('tables')) {
      final tables = jsonData['tables'];
      if (tables is! Map<String, dynamic>) {
        errors.add(
          ValidationError(
            code: 'INVALID_TABLES_TYPE',
            message: 'tables字段类型无效',
            severity: ErrorSeverity.high,
          ),
        );
      }
    }

    return errors;
  }

  /// 生成损坏修复建议
  List<String> _generateCorruptionRepairSuggestions(
    List<ValidationError> errors,
  ) {
    final suggestions = <String>[];
    final errorCodes = errors.map((e) => e.code).toSet();

    if (errorCodes.contains('JSON_CORRUPTION')) {
      suggestions.addAll([
        '尝试使用JSON修复工具',
        '检查文件是否被截断',
        '使用文本编辑器手动修复JSON格式',
      ]);
    }

    if (errorCodes.contains('CHECKSUM_MISMATCH')) {
      suggestions.addAll([
        '文件数据已被修改或损坏',
        '尝试从原始来源重新获取备份',
        '如果是网络传输问题，重新下载文件',
      ]);
    }

    if (errorCodes.contains('METADATA_CORRUPTION')) {
      suggestions.addAll([
        '尝试手动重建元数据',
        '使用备份文件修复工具',
        '联系技术支持获取专业帮助',
      ]);
    }

    return suggestions;
  }

  /// 生成恢复前修复建议
  List<String> _generatePreRestoreRepairSuggestions(
    List<ValidationError> errors,
    List<ValidationWarning> warnings,
  ) {
    final suggestions = <String>[];

    if (errors.isNotEmpty) {
      suggestions.addAll([
        '修复所有错误后再进行恢复',
        '考虑使用部分恢复模式跳过有问题的数据',
      ]);
    }

    if (warnings.isNotEmpty) {
      suggestions.addAll([
        '注意警告信息，可能影响恢复质量',
        '建议在测试环境中先进行恢复验证',
      ]);
    }

    return suggestions;
  }

  /// 计算兼容性分数
  double _calculateCompatibilityScore(CompatibilityCheckResult result) {
    if (result.isCompatible) return 1.0;

    double score = 1.0;
    
    // 根据问题严重程度扣分
    for (final issue in result.issues) {
      switch (issue.severity) {
        case CompatibilityIssueSeverity.critical:
          score -= 0.5;
          break;
        case CompatibilityIssueSeverity.error:
          score -= 0.3;
          break;
        case CompatibilityIssueSeverity.warning:
          score -= 0.1;
          break;
        case CompatibilityIssueSeverity.info:
          score -= 0.05;
          break;
      }
    }

    return (score < 0) ? 0.0 : score;
  }

  /// 检查表是否存在
  Future<bool> _tableExists(String tableName) async {
    try {
      final query = '''
        SELECT name FROM sqlite_master 
        WHERE type='table' AND name=?
      ''';
      final result = await _database.customSelect(
        query,
        variables: [Variable.withString(tableName)],
      ).getSingleOrNull();
      
      return result != null;
    } catch (e) {
      return false;
    }
  }

  /// 获取表结构信息
  Future<List<Map<String, dynamic>>> _getTableInfo(String tableName) async {
    try {
      final query = 'PRAGMA table_info($tableName)';
      final result = await _database.customSelect(query).get();
      
      return result.map((row) => row.data).toList();
    } catch (e) {
      return [];
    }
  }

  /// 获取表的主键列名
  Future<String?> _getPrimaryKeyColumn(String tableName) async {
    try {
      final tableInfo = await _getTableInfo(tableName);
      
      for (final col in tableInfo) {
        if (col['pk'] == 1) {
          return col['name'] as String;
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 检查数据类型兼容性
  bool _isTypeCompatible(String expectedType, dynamic value) {
    final type = expectedType.toUpperCase();
    
    switch (type) {
      case 'INTEGER':
      case 'INT':
        return value is int;
      case 'REAL':
      case 'FLOAT':
      case 'DOUBLE':
        return value is num;
      case 'TEXT':
      case 'VARCHAR':
      case 'CHAR':
        return value is String;
      case 'BLOB':
        return value is List<int> || value is String;
      case 'BOOLEAN':
      case 'BOOL':
        return value is bool || value is int;
      case 'DATETIME':
      case 'TIMESTAMP':
        return value is String || value is int;
      default:
        return true; // 未知类型，假设兼容
    }
  }

  /// 获取外键关系定义
  Future<List<Map<String, dynamic>>> _getForeignKeyRelationships() async {
    // 这里返回应用中定义的外键关系
    // 实际实现中应该从数据库架构或配置文件中读取
    return [
      {
        'sourceTable': 'product',
        'targetTable': 'category',
        'foreignKeyField': 'category_id',
        'targetKeyField': 'id',
      },
      {
        'sourceTable': 'product',
        'targetTable': 'unit',
        'foreignKeyField': 'unit_id',
        'targetKeyField': 'id',
      },
      {
        'sourceTable': 'stock',
        'targetTable': 'product',
        'foreignKeyField': 'product_id',
        'targetKeyField': 'id',
      },
      {
        'sourceTable': 'sales_transaction_item',
        'targetTable': 'sales_transaction',
        'foreignKeyField': 'transaction_id',
        'targetKeyField': 'id',
      },
      {
        'sourceTable': 'sales_transaction_item',
        'targetTable': 'product',
        'foreignKeyField': 'product_id',
        'targetKeyField': 'id',
      },
      {
        'sourceTable': 'purchase_order_item',
        'targetTable': 'purchase_order',
        'foreignKeyField': 'order_id',
        'targetKeyField': 'id',
      },
      {
        'sourceTable': 'purchase_order_item',
        'targetTable': 'product',
        'foreignKeyField': 'product_id',
        'targetKeyField': 'id',
      },
    ];
  }

  /// 获取表约束信息
  Future<List<Map<String, dynamic>>> _getTableConstraints(String tableName) async {
    final constraints = <Map<String, dynamic>>[];
    
    try {
      // 获取NOT NULL约束
      final tableInfo = await _getTableInfo(tableName);
      for (final col in tableInfo) {
        if (col['notnull'] == 1) {
          constraints.add({
            'type': 'NOT NULL',
            'column': col['name'],
          });
        }
      }

      // 获取UNIQUE约束（从索引信息中）
      final indexQuery = 'PRAGMA index_list($tableName)';
      final indexes = await _database.customSelect(indexQuery).get();
      
      for (final index in indexes) {
        final indexData = index.data;
        if (indexData['unique'] == 1) {
          final indexName = indexData['name'] as String;
          final indexInfoQuery = 'PRAGMA index_info($indexName)';
          final indexInfo = await _database.customSelect(indexInfoQuery).get();
          
          for (final info in indexInfo) {
            constraints.add({
              'type': 'UNIQUE',
              'column': info.data['name'],
            });
          }
        }
      }

      return constraints;
    } catch (e) {
      return constraints;
    }
  }
}