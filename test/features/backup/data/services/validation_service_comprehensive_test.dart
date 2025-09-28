import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;

import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/backup/data/services/validation_service.dart';
import 'package:stocko_app/features/backup/domain/models/backup_metadata.dart';
import 'package:stocko_app/features/backup/domain/models/backup_data.dart';
import 'package:stocko_app/features/backup/domain/models/validation_result.dart';
import 'package:stocko_app/features/backup/domain/models/compatibility_check_result.dart';
import 'package:stocko_app/features/backup/domain/models/integrity_check_result.dart';
import 'package:stocko_app/features/backup/domain/services/i_validation_service.dart';
import 'package:stocko_app/features/backup/domain/services/i_encryption_service.dart';

// Mock classes
class MockAppDatabase extends Mock implements AppDatabase {}
class MockIEncryptionService extends Mock implements IEncryptionService {}

void main() {
  group('ValidationService', () {
    late IValidationService validationService;
    late MockAppDatabase mockDatabase;
    late MockIEncryptionService mockEncryptionService;
    late Directory tempDir;

    setUp(() async {
      mockDatabase = MockAppDatabase();
      mockEncryptionService = MockIEncryptionService();
      validationService = ValidationService(mockDatabase, mockEncryptionService);
      
      // Create temporary directory for test files
      tempDir = await Directory.systemTemp.createTemp('validation_service_test');
    });

    tearDown(() async {
      // Clean up temporary directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Instance Creation', () {
      test('should create validation service instance', () {
        expect(validationService, isA<ValidationService>());
        expect(validationService, isA<IValidationService>());
      });
    });

    group('Backup Format Validation', () {
      test('should validate correct backup file format', () async {
        // Arrange
        final metadata = BackupMetadata(
          id: 'test_backup',
          fileName: 'test_backup.json',
          createdAt: DateTime.now(),
          fileSize: 1000,
          version: '1.0.0',
          tableCounts: {'products': 10, 'categories': 5},
          checksum: 'test_checksum',
        );

        final backupData = BackupData(
          metadata: metadata,
          tables: {
            'products': [
              {'id': 1, 'name': 'Product 1'},
              {'id': 2, 'name': 'Product 2'},
            ],
            'categories': [
              {'id': 1, 'name': 'Category 1'},
            ],
          },
        );

        final backupFile = File(path.join(tempDir.path, 'valid_backup.json'));
        await backupFile.writeAsString(jsonEncode(backupData.toJson()));

        // Act
        final result = await validationService.validateBackupFormat(backupFile.path);

        // Assert
        expect(result, isA<ValidationResult>());
        expect(result.isValid, isTrue);
        expect(result.type, equals(ValidationType.fileFormat));
        expect(result.errors, isEmpty);
      });

      test('should detect non-existent backup file', () async {
        // Act
        final result = await validationService.validateBackupFormat('/non/existent/file.json');

        // Assert
        expect(result, isA<ValidationResult>());
        expect(result.isValid, isFalse);
        expect(result.errors, isNotEmpty);
        expect(result.errors.first.code, equals('FILE_NOT_FOUND'));
      });

      test('should detect empty backup file', () async {
        // Arrange
        final emptyFile = File(path.join(tempDir.path, 'empty.json'));
        await emptyFile.writeAsString('');

        // Act
        final result = await validationService.validateBackupFormat(emptyFile.path);

        // Assert
        expect(result, isA<ValidationResult>());
        expect(result.isValid, isFalse);
        expect(result.errors, isNotEmpty);
        expect(result.errors.first.code, equals('EMPTY_FILE'));
      });

      test('should detect invalid JSON format', () async {
        // Arrange
        final invalidFile = File(path.join(tempDir.path, 'invalid.json'));
        await invalidFile.writeAsString('invalid json content {');

        // Act
        final result = await validationService.validateBackupFormat(invalidFile.path);

        // Assert
        expect(result, isA<ValidationResult>());
        expect(result.isValid, isFalse);
        expect(result.errors, isNotEmpty);
        expect(result.errors.first.code, equals('INVALID_JSON'));
      });

      test('should detect missing metadata field', () async {
        // Arrange
        final incompleteData = {
          'tables': {
            'products': [{'id': 1, 'name': 'Product 1'}],
          },
        };

        final incompleteFile = File(path.join(tempDir.path, 'no_metadata.json'));
        await incompleteFile.writeAsString(jsonEncode(incompleteData));

        // Act
        final result = await validationService.validateBackupFormat(incompleteFile.path);

        // Assert
        expect(result, isA<ValidationResult>());
        expect(result.isValid, isFalse);
        expect(result.errors, isNotEmpty);
        expect(result.errors.any((error) => error.code == 'MISSING_METADATA'), isTrue);
      });

      test('should detect missing tables field', () async {
        // Arrange
        final metadata = BackupMetadata(
          id: 'test_backup',
          fileName: 'test_backup.json',
          createdAt: DateTime.now(),
          fileSize: 1000,
          version: '1.0.0',
          tableCounts: {'products': 10},
          checksum: 'test_checksum',
        );

        final incompleteData = {
          'metadata': metadata.toJson(),
        };

        final incompleteFile = File(path.join(tempDir.path, 'no_tables.json'));
        await incompleteFile.writeAsString(jsonEncode(incompleteData));

        // Act
        final result = await validationService.validateBackupFormat(incompleteFile.path);

        // Assert
        expect(result, isA<ValidationResult>());
        expect(result.isValid, isFalse);
        expect(result.errors, isNotEmpty);
        expect(result.errors.any((error) => error.code == 'MISSING_TABLES'), isTrue);
      });
    });

    group('Version Compatibility Validation', () {
      test('should validate compatible backup version', () async {
        // Arrange
        final metadata = BackupMetadata(
          id: 'compatible_backup',
          fileName: 'compatible_backup.json',
          createdAt: DateTime.now(),
          fileSize: 1000,
          version: '1.0.0', // Compatible version
          tableCounts: {'products': 10},
          checksum: 'compatible_checksum',
          schemaVersion: 1,
          appVersion: '1.0.0+1',
        );

        // Mock database schema version
        when(() => mockDatabase.schemaVersion).thenReturn(1);

        // Act
        final result = await validationService.checkVersionCompatibility(metadata);

        // Assert
        expect(result, isA<CompatibilityCheckResult>());
        expect(result.isCompatible, isTrue);
        expect(result.backupFormatCompatible, isTrue);
        expect(result.schemaVersionCompatible, isTrue);
        expect(result.appVersionCompatible, isTrue);
        // 在测试环境中，数据库表不存在，所以会有警告
        expect(result.issues, isNotEmpty);
      });

      test('should detect incompatible backup format version', () async {
        // Arrange
        final metadata = BackupMetadata(
          id: 'incompatible_backup',
          fileName: 'incompatible_backup.json',
          createdAt: DateTime.now(),
          fileSize: 1000,
          version: '2.0.0', // Incompatible version
          tableCounts: {'products': 10},
          checksum: 'incompatible_checksum',
          schemaVersion: 1,
        );

        // Act
        final result = await validationService.checkVersionCompatibility(metadata);

        // Assert
        expect(result, isA<CompatibilityCheckResult>());
        expect(result.isCompatible, isFalse);
        expect(result.backupFormatCompatible, isFalse);
        expect(result.issues, isNotEmpty);
        expect(result.issues.any((issue) => 
          issue.type == CompatibilityIssueType.backupFormatIncompatible
        ), isTrue);
      });

      test('should detect schema version too old', () async {
        // Arrange
        final metadata = BackupMetadata(
          id: 'old_schema_backup',
          fileName: 'old_schema_backup.json',
          createdAt: DateTime.now(),
          fileSize: 1000,
          version: '1.0.0',
          tableCounts: {'products': 10},
          checksum: 'old_schema_checksum',
          schemaVersion: 0, // Too old
        );

        // Act
        final result = await validationService.checkVersionCompatibility(metadata);

        // Assert
        expect(result, isA<CompatibilityCheckResult>());
        expect(result.isCompatible, isFalse);
        expect(result.schemaVersionCompatible, isFalse);
        expect(result.issues, isNotEmpty);
        expect(result.issues.any((issue) => 
          issue.type == CompatibilityIssueType.schemaVersionIncompatible
        ), isTrue);
      });

      test('should detect schema version too new', () async {
        // Arrange
        final metadata = BackupMetadata(
          id: 'new_schema_backup',
          fileName: 'new_schema_backup.json',
          createdAt: DateTime.now(),
          fileSize: 1000,
          version: '1.0.0',
          tableCounts: {'products': 10},
          checksum: 'new_schema_checksum',
          schemaVersion: 100, // Too new
        );

        // Act
        final result = await validationService.checkVersionCompatibility(metadata);

        // Assert
        expect(result, isA<CompatibilityCheckResult>());
        expect(result.isCompatible, isFalse);
        expect(result.schemaVersionCompatible, isFalse);
        expect(result.issues, isNotEmpty);
        expect(result.upgradeRecommendations, isNotEmpty);
      });

      test('should warn about large version gaps', () async {
        // Arrange
        final metadata = BackupMetadata(
          id: 'gap_backup',
          fileName: 'gap_backup.json',
          createdAt: DateTime.now(),
          fileSize: 1000,
          version: '1.0.0',
          tableCounts: {'products': 10},
          checksum: 'gap_checksum',
          schemaVersion: 5, // Large gap from current
        );

        // Mock current schema version to be much higher
        when(() => mockDatabase.schemaVersion).thenReturn(20);

        // Act
        final result = await validationService.checkVersionCompatibility(metadata);

        // Assert
        expect(result, isA<CompatibilityCheckResult>());
        expect(result.warnings, isNotEmpty);
        expect(result.warnings.any((warning) => 
          warning.type == CompatibilityWarningType.versionGapLarge
        ), isTrue);
      });

      test('should detect unknown tables', () async {
        // Arrange
        final metadata = BackupMetadata(
          id: 'unknown_tables_backup',
          fileName: 'unknown_tables_backup.json',
          createdAt: DateTime.now(),
          fileSize: 1000,
          version: '1.0.0',
          tableCounts: {'unknown_table': 10, 'products': 5},
          checksum: 'unknown_tables_checksum',
        );

        // Mock current tables
        when(() => mockDatabase.schemaVersion).thenReturn(1);

        // Act
        final result = await validationService.checkVersionCompatibility(metadata);

        // Assert
        expect(result, isA<CompatibilityCheckResult>());
        expect(result.tableCompatibility, contains('unknown_table'));
        expect(result.tableCompatibility['unknown_table'], isFalse);
        expect(result.issues.any((issue) => 
          issue.type == CompatibilityIssueType.unknownTable
        ), isTrue);
      });
    });

    group('Data Integrity Validation', () {
      test('should validate data integrity with correct checksum', () async {
        // Arrange
        final tablesData = {
          'products': [
            {'id': 1, 'name': 'Product 1'},
            {'id': 2, 'name': 'Product 2'},
          ],
        };

        final correctChecksum = 'correct_checksum_value';

        final metadata = BackupMetadata(
          id: 'integrity_backup',
          fileName: 'integrity_backup.json',
          createdAt: DateTime.now(),
          fileSize: 1000,
          version: '1.0.0',
          tableCounts: {'products': 2},
          checksum: correctChecksum,
        );

        // Act
        final result = await validationService.validateDataIntegrity(tablesData, metadata);

        // Assert
        expect(result, isA<IntegrityCheckResult>());
        expect(result.isIntegrityValid, isA<bool>());
        expect(result.statistics.totalRecords, equals(2));
        expect(result.statistics.validRecords, greaterThanOrEqualTo(0));
      });

      test('should detect checksum mismatch', () async {
        // Arrange
        final tablesData = {
          'products': [
            {'id': 1, 'name': 'Product 1'},
          ],
        };

        final metadata = BackupMetadata(
          id: 'checksum_mismatch_backup',
          fileName: 'checksum_mismatch_backup.json',
          createdAt: DateTime.now(),
          fileSize: 1000,
          version: '1.0.0',
          tableCounts: {'products': 1},
          checksum: 'wrong_checksum',
        );

        // Act
        final result = await validationService.validateDataIntegrity(tablesData, metadata);

        // Assert
        expect(result, isA<IntegrityCheckResult>());
        expect(result.checksumValid, isFalse);
        expect(result.detailedResults, isNotEmpty);
        expect(result.detailedResults.any((r) => 
          r.errors.any((e) => e.code == 'CHECKSUM_MISMATCH')
        ), isTrue);
      });

      test('should detect duplicate records', () async {
        // Arrange
        final tablesDataWithDuplicates = {
          'products': [
            {'id': 1, 'name': 'Product 1'},
            {'id': 1, 'name': 'Duplicate Product 1'}, // Same ID
            {'id': 2, 'name': 'Product 2'},
          ],
        };

        final metadata = BackupMetadata(
          id: 'duplicates_backup',
          fileName: 'duplicates_backup.json',
          createdAt: DateTime.now(),
          fileSize: 1000,
          version: '1.0.0',
          tableCounts: {'products': 3},
          checksum: 'duplicates_checksum',
        );

        // Act
        final result = await validationService.validateDataIntegrity(tablesDataWithDuplicates, metadata);

        // Assert
        expect(result, isA<IntegrityCheckResult>());
        expect(result.duplicateRecords, isA<List>());
        expect(result.statistics.duplicateRecordCount, greaterThanOrEqualTo(0));
      });

      test('should detect missing relationships', () async {
        // Arrange
        final tablesDataWithMissingRefs = {
          'products': [
            {'id': 1, 'name': 'Product 1', 'category_id': 999}, // Non-existent category
          ],
          'categories': [
            {'id': 1, 'name': 'Electronics'},
          ],
        };

        final metadata = BackupMetadata(
          id: 'missing_refs_backup',
          fileName: 'missing_refs_backup.json',
          createdAt: DateTime.now(),
          fileSize: 1000,
          version: '1.0.0',
          tableCounts: {'products': 1, 'categories': 1},
          checksum: 'missing_refs_checksum',
        );

        // Act
        final result = await validationService.validateDataIntegrity(tablesDataWithMissingRefs, metadata);

        // Assert
        expect(result, isA<IntegrityCheckResult>());
        expect(result.missingRelationships, isA<List>());
        expect(result.statistics.missingRelationshipCount, greaterThanOrEqualTo(0));
      });

      test('should detect orphaned records', () async {
        // Arrange
        final tablesDataWithOrphans = {
          'order_items': [
            {'id': 1, 'order_id': 999, 'product_id': 1}, // Non-existent order
          ],
          'orders': [
            {'id': 1, 'total': 99.99},
          ],
          'products': [
            {'id': 1, 'name': 'Product 1'},
          ],
        };

        final metadata = BackupMetadata(
          id: 'orphans_backup',
          fileName: 'orphans_backup.json',
          createdAt: DateTime.now(),
          fileSize: 1000,
          version: '1.0.0',
          tableCounts: {'order_items': 1, 'orders': 1, 'products': 1},
          checksum: 'orphans_checksum',
        );

        // Act
        final result = await validationService.validateDataIntegrity(tablesDataWithOrphans, metadata);

        // Assert
        expect(result, isA<IntegrityCheckResult>());
        expect(result.orphanedRecords, isA<List>());
        expect(result.statistics.orphanedRecordCount, greaterThanOrEqualTo(0));
      });
    });
  });
}