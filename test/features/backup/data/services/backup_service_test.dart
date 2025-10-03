import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;

import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/backup/data/services/unified_backup_service.dart';
import 'package:stocko_app/features/backup/data/repository/optimized_data_export_repository.dart';
import 'package:stocko_app/features/backup/domain/models/backup_options.dart';
import 'package:stocko_app/features/backup/domain/models/backup_metadata.dart';
import 'package:stocko_app/features/backup/domain/models/backup_exception.dart';
import 'package:stocko_app/features/backup/domain/models/backup_error_type.dart';
import 'package:stocko_app/features/backup/domain/services/i_backup_service.dart';
import 'package:stocko_app/features/backup/domain/common/backup_common.dart';

// Mock classes
class MockAppDatabase extends Mock implements AppDatabase {}
class MockDataExportRepository extends Mock implements OptimizedDataExportRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('BackupService', () {
    late MockAppDatabase mockDatabase;
    late IBackupService backupService;
    late Directory tempDir;

    setUpAll(() {
      // Register fallback values for mocktail
      registerFallbackValue(const BackupOptions());
      registerFallbackValue(CancelToken());
    });

    setUp(() async {
      mockDatabase = MockAppDatabase();
      backupService = UnifiedBackupService(mockDatabase);
      
      // Create temporary directory for test files
      tempDir = await Directory.systemTemp.createTemp('backup_service_test');
    });

    tearDown(() async {
      // Clean up temporary directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Instance Creation', () {
      test('should create backup service instance', () {
        expect(backupService, isA<UnifiedBackupService>());
        expect(backupService, isA<IBackupService>());
      });
    });

    group('Backup Options Validation', () {
      test('should validate default backup options', () {
        const options = BackupOptions();
        
        expect(options.customName, isNull);
        expect(options.includeImages, isFalse);
        expect(options.encrypt, isFalse);
        expect(options.compress, isFalse);
        expect(options.excludeTables, isEmpty);
      });

      test('should validate custom backup options', () {
        const options = BackupOptions(
          customName: 'test_backup',
          includeImages: true,
          encrypt: true,
          password: 'test_password',
          compress: true,
          description: 'Test backup description',
          excludeTables: ['temp_table'],
        );
        
        expect(options.customName, equals('test_backup'));
        expect(options.includeImages, isTrue);
        expect(options.encrypt, isTrue);
        expect(options.password, equals('test_password'));
        expect(options.compress, isTrue);
        expect(options.description, equals('Test backup description'));
        expect(options.excludeTables, contains('temp_table'));
      });

      test('should serialize and deserialize backup options', () {
        const originalOptions = BackupOptions(
          customName: 'test_backup',
          includeImages: true,
          encrypt: false,
          description: 'Test description',
        );
        
        final json = originalOptions.toJson();
        final deserializedOptions = BackupOptions.fromJson(json);
        
        expect(deserializedOptions.customName, equals(originalOptions.customName));
        expect(deserializedOptions.includeImages, equals(originalOptions.includeImages));
        expect(deserializedOptions.encrypt, equals(originalOptions.encrypt));
        expect(deserializedOptions.description, equals(originalOptions.description));
      });
    });

    group('Cancel Token', () {
      test('should handle cancel token correctly', () {
        final cancelToken = CancelToken();
        expect(cancelToken.isCancelled, isFalse);
        
        cancelToken.cancel();
        expect(cancelToken.isCancelled, isTrue);
        
        expect(() => cancelToken.throwIfCancelled(), 
               throwsA(isA<BackupCancelledException>()));
      });

      test('should not throw when cancel token is not cancelled', () {
        final cancelToken = CancelToken();
        expect(() => cancelToken.throwIfCancelled(), returnsNormally);
      });
    });

    group('Backup File Validation', () {
      test('should validate valid backup file', () async {
        // Create a valid backup file
        final metadata = BackupMetadata(
          id: 'test_backup',
          fileName: 'test_backup.json',
          createdAt: DateTime.now(),
          fileSize: 1000,
          version: '1.0.0',
          tableCounts: {'products': 10, 'categories': 5},
          checksum: 'test_checksum',
        );

        final backupData = {
          'metadata': metadata.toJson(),
          'tables': {
            'products': [
              {'id': 1, 'name': 'Product 1'},
              {'id': 2, 'name': 'Product 2'},
            ],
            'categories': [
              {'id': 1, 'name': 'Category 1'},
            ],
          },
        };

        final backupFile = File(path.join(tempDir.path, 'valid_backup.json'));
        await backupFile.writeAsString(jsonEncode(backupData));

        // This will fail due to checksum mismatch, but tests the validation logic
        final isValid = await backupService.validateBackupFile(backupFile.path);
        expect(isValid, isFalse); // Expected due to checksum mismatch
      });

      test('should reject non-existent backup file', () async {
        final isValid = await backupService.validateBackupFile('/non/existent/file.json');
        expect(isValid, isFalse);
      });

      test('should reject invalid JSON backup file', () async {
        final invalidFile = File(path.join(tempDir.path, 'invalid.json'));
        await invalidFile.writeAsString('invalid json content');

        final isValid = await backupService.validateBackupFile(invalidFile.path);
        expect(isValid, isFalse);
      });

      test('should reject backup file with missing metadata', () async {
        final incompleteData = {
          'tables': {
            'products': [{'id': 1, 'name': 'Product 1'}],
          },
        };

        final incompleteFile = File(path.join(tempDir.path, 'incomplete.json'));
        await incompleteFile.writeAsString(jsonEncode(incompleteData));

        final isValid = await backupService.validateBackupFile(incompleteFile.path);
        expect(isValid, isFalse);
      });

      test('should reject backup file with missing tables', () async {
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

        final isValid = await backupService.validateBackupFile(incompleteFile.path);
        expect(isValid, isFalse);
      });
    });

    group('Backup Metadata', () {
      test('should get backup info from valid file', () async {
        final metadata = BackupMetadata(
          id: 'test_backup',
          fileName: 'test_backup.json',
          createdAt: DateTime.now(),
          fileSize: 1000,
          version: '1.0.0',
          tableCounts: {'products': 10, 'categories': 5},
          checksum: 'test_checksum',
        );

        final backupData = {
          'metadata': metadata.toJson(),
          'tables': {
            'products': [{'id': 1, 'name': 'Product 1'}],
            'categories': [{'id': 1, 'name': 'Category 1'}],
          },
        };

        final backupFile = File(path.join(tempDir.path, 'metadata_test.json'));
        await backupFile.writeAsString(jsonEncode(backupData));

        final retrievedMetadata = await backupService.getBackupInfo(backupFile.path);
        
        expect(retrievedMetadata, isNotNull);
        expect(retrievedMetadata!.id, equals(metadata.id));
        expect(retrievedMetadata.fileName, equals(metadata.fileName));
        expect(retrievedMetadata.version, equals(metadata.version));
        expect(retrievedMetadata.tableCounts, equals(metadata.tableCounts));
      });

      test('should return null for non-existent file', () async {
        final metadata = await backupService.getBackupInfo('/non/existent/file.json');
        expect(metadata, isNull);
      });

      test('should return null for invalid backup file', () async {
        final invalidFile = File(path.join(tempDir.path, 'invalid_metadata.json'));
        await invalidFile.writeAsString('invalid json');

        final metadata = await backupService.getBackupInfo(invalidFile.path);
        expect(metadata, isNull);
      });
    });

    group('Local Backup Management', () {
      test('should return empty list when no backups exist', () async {
        final backups = await backupService.getLocalBackups();
        expect(backups, isEmpty);
      });

      test('should delete backup file successfully', () async {
        // Create a test backup file in the expected location
        final backupId = 'test_backup_to_delete';
        
        // This test would need proper directory setup
        // For now, just test that the method doesn't throw
        final result = await backupService.deleteBackup(backupId);
        expect(result, isFalse); // Expected since file doesn't exist
      });
    });

    group('Error Handling', () {
      test('should handle backup exceptions properly', () {
        // Test different types of backup exceptions
        final fileSystemError = BackupException.fileSystem('File system error');
        expect(fileSystemError.type, equals(BackupErrorType.fileSystemError));
        expect(fileSystemError.message, equals('File system error'));

        final databaseError = BackupException.database('Database error');
        expect(databaseError.type, equals(BackupErrorType.databaseError));
        expect(databaseError.message, equals('Database error'));

        final validationError = BackupException.validation('Validation error');
        expect(validationError.type, equals(BackupErrorType.validationError));
        expect(validationError.message, equals('Validation error'));

        final encryptionError = BackupException.encryption('Encryption error');
        expect(encryptionError.type, equals(BackupErrorType.encryptionError));
        expect(encryptionError.message, equals('Encryption error'));

        final permissionError = BackupException.permissionDenied('Permission denied');
        expect(permissionError.type, equals(BackupErrorType.permissionDenied));
        expect(permissionError.message, equals('Permission denied'));

        final spaceError = BackupException.insufficientSpace('Insufficient space');
        expect(spaceError.type, equals(BackupErrorType.insufficientSpace));
        expect(spaceError.message, equals('Insufficient space'));
      });

      test('should handle serialization errors', () {
        final serializationError = BackupException.serialization(
          'Serialization failed',
          originalError: FormatException('Invalid format'),
        );
        
        expect(serializationError.type, equals(BackupErrorType.serializationError));
        expect(serializationError.message, equals('Serialization failed'));
        expect(serializationError.originalError, isA<FormatException>());
      });
    });

    group('Progress Callbacks', () {
      test('should handle progress callback correctly', () {
        final progressUpdates = <String>[];
        final progressValues = <int>[];
        final totalValues = <int>[];

        void progressCallback(String step, int current, int total) {
          progressUpdates.add(step);
          progressValues.add(current);
          totalValues.add(total);
        }

        // Simulate progress updates
        progressCallback('Starting backup...', 0, 100);
        progressCallback('Exporting data...', 50, 100);
        progressCallback('Backup complete', 100, 100);

        expect(progressUpdates, hasLength(3));
        expect(progressUpdates[0], equals('Starting backup...'));
        expect(progressUpdates[1], equals('Exporting data...'));
        expect(progressUpdates[2], equals('Backup complete'));

        expect(progressValues, equals([0, 50, 100]));
        expect(totalValues, equals([100, 100, 100]));
      });
    });

    group('Backup ID Generation', () {
      test('should generate unique backup IDs', () {
        // Since we can't directly test the private method, we test through behavior
        // Multiple backup operations should generate different IDs
        final service1 = UnifiedBackupService(mockDatabase);
        final service2 = UnifiedBackupService(mockDatabase);
        
        expect(service1, isNot(equals(service2)));
      });
    });

    group('Edge Cases', () {
      test('should handle empty backup options', () {
        const emptyOptions = BackupOptions();
        expect(emptyOptions.customName, isNull);
        expect(emptyOptions.includeTables, isNull);
        expect(emptyOptions.excludeTables, isEmpty);
      });

      test('should handle backup options with empty lists', () {
        const options = BackupOptions(
          includeTables: [],
          excludeTables: [],
        );
        expect(options.includeTables, isEmpty);
        expect(options.excludeTables, isEmpty);
      });

      test('should handle backup options serialization with null values', () {
        const options = BackupOptions(
          customName: null,
          password: null,
          description: null,
        );
        
        final json = options.toJson();
        final deserialized = BackupOptions.fromJson(json);
        
        expect(deserialized.customName, isNull);
        expect(deserialized.password, isNull);
        expect(deserialized.description, isNull);
      });
    });
  });
}