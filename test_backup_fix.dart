import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/backup/data/repository/data_import_repository.dart';
import 'package:stocko_app/features/backup/data/services/validation_service.dart';
import 'package:stocko_app/features/backup/domain/models/backup_metadata.dart';
import 'package:stocko_app/features/backup/domain/models/restore_mode.dart';
import 'package:stocko_app/features/backup/domain/models/compatibility_check_result.dart';
import 'package:stocko_app/features/backup/domain/services/i_encryption_service.dart';

// Mock classes
class MockAppDatabase extends Mock implements AppDatabase {}
class MockIEncryptionService extends Mock implements IEncryptionService {}

void main() {
  group('Backup Fix Verification', () {
    test('DataImportRepository should handle estimateImportTime correctly', () async {
      // Arrange
      final mockDatabase = MockAppDatabase();
      final repository = DataImportRepository(mockDatabase);
      
      // Act
      final result = await repository.estimateImportTime(0, RestoreMode.merge);
      
      // Assert
      expect(result, equals(1)); // Should return minimum 1 second, not 0
    });

    test('ValidationService should work without throwing exceptions', () async {
      // Arrange
      final mockDatabase = MockAppDatabase();
      final mockEncryption = MockIEncryptionService();
      final validationService = ValidationService(mockDatabase, mockEncryption);
      
      final metadata = BackupMetadata(
        id: 'test',
        fileName: 'test.json',
        createdAt: DateTime.now(),
        fileSize: 1000,
        version: '1.0.0',
        tableCounts: {'products': 10},
        checksum: 'test_checksum',
      );
      
      // Mock database schema version
      when(() => mockDatabase.schemaVersion).thenReturn(1);
      
      // Act
      final result = await validationService.checkVersionCompatibility(metadata);
      
      // Assert
      expect(result, isA<CompatibilityCheckResult>());
      expect(result.isCompatible, isTrue);
    });
  });
}