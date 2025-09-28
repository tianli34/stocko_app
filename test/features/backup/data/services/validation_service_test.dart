import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/backup/data/services/validation_service.dart';
import 'package:stocko_app/features/backup/domain/models/validation_result.dart';
import 'package:stocko_app/features/backup/domain/services/i_encryption_service.dart';

// Mock classes
class MockAppDatabase extends Mock implements AppDatabase {}
class MockIEncryptionService extends Mock implements IEncryptionService {}

void main() {
  group('ValidationService', () {
    late ValidationService validationService;
    late MockAppDatabase mockDatabase;
    late MockIEncryptionService mockEncryptionService;

    setUp(() {
      mockDatabase = MockAppDatabase();
      mockEncryptionService = MockIEncryptionService();
      
      validationService = ValidationService(mockDatabase, mockEncryptionService);
    });

    group('validateBackupFormat', () {
      test('should return invalid result for non-existent file', () async {
        // 执行测试
        final result = await validationService.validateBackupFormat('non_existent_file.json');

        // 验证结果
        expect(result.isValid, isFalse);
        expect(result.type, equals(ValidationType.fileFormat));
        expect(result.errors, isNotEmpty);
        expect(result.errors.first.code, equals('FILE_NOT_FOUND'));
      });

      test('should return invalid result for empty file', () async {
        // 准备测试数据
        final testFile = File('empty_backup.json');
        await testFile.writeAsString('');

        try {
          // 执行测试
          final result = await validationService.validateBackupFormat(testFile.path);

          // 验证结果
          expect(result.isValid, isFalse);
          expect(result.errors.any((e) => e.code == 'EMPTY_FILE'), isTrue);
        } finally {
          // 清理测试文件
          if (await testFile.exists()) {
            await testFile.delete();
          }
        }
      });

      test('should return invalid result for invalid JSON', () async {
        // 准备测试数据
        final testFile = File('invalid_backup.json');
        await testFile.writeAsString('invalid json content');

        try {
          // 执行测试
          final result = await validationService.validateBackupFormat(testFile.path);

          // 验证结果
          expect(result.isValid, isFalse);
          expect(result.errors.any((e) => e.code == 'INVALID_JSON'), isTrue);
        } finally {
          // 清理测试文件
          if (await testFile.exists()) {
            await testFile.delete();
          }
        }
      });

      test('should return invalid result for missing metadata', () async {
        // 准备测试数据
        final testFile = File('no_metadata_backup.json');
        final backupData = {
          'tables': {
            'products': [{'id': 1, 'name': 'Product 1'}],
          },
        };
        await testFile.writeAsString(jsonEncode(backupData));

        try {
          // 执行测试
          final result = await validationService.validateBackupFormat(testFile.path);

          // 验证结果
          expect(result.isValid, isFalse);
          expect(result.errors.any((e) => e.code == 'MISSING_METADATA'), isTrue);
        } finally {
          // 清理测试文件
          if (await testFile.exists()) {
            await testFile.delete();
          }
        }
      });
    });

    group('generateRepairSuggestions', () {
      test('should generate appropriate suggestions for different error types', () {
        // 准备测试数据
        final validationResults = [
          ValidationResult(
            isValid: false,
            type: ValidationType.fileFormat,
            target: 'test.json',
            errors: [
              ValidationError(
                code: 'FILE_NOT_FOUND',
                message: 'File not found',
                severity: ErrorSeverity.critical,
              ),
            ],
          ),
          ValidationResult(
            isValid: false,
            type: ValidationType.fileCorruption,
            target: 'test.json',
            errors: [
              ValidationError(
                code: 'JSON_CORRUPTION',
                message: 'JSON corrupted',
                severity: ErrorSeverity.critical,
              ),
            ],
          ),
        ];

        // 执行测试
        final suggestions = validationService.generateRepairSuggestions(validationResults);

        // 验证结果
        expect(suggestions, isNotEmpty);
        expect(suggestions.any((s) => s.contains('检查备份文件路径')), isTrue);
      });

      test('should return generic suggestions when no specific errors found', () {
        // 准备测试数据
        final validationResults = [
          ValidationResult(
            isValid: false,
            type: ValidationType.dataIntegrity,
            target: 'test.json',
            errors: [
              ValidationError(
                code: 'UNKNOWN_ERROR',
                message: 'Unknown error',
                severity: ErrorSeverity.medium,
              ),
            ],
          ),
        ];

        // 执行测试
        final suggestions = validationService.generateRepairSuggestions(validationResults);

        // 验证结果
        expect(suggestions, isNotEmpty);
        expect(suggestions.any((s) => s.contains('检查备份文件完整性')), isTrue);
      });
    });
  });
}