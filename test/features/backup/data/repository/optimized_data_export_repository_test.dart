import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stocko_app/features/backup/data/repository/optimized_data_export_repository.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/backup/domain/models/performance_metrics.dart';

// Mock classes
class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  group('OptimizedDataExportRepository Stream Features', () {
    late OptimizedDataExportRepository repository;
    late MockAppDatabase mockDatabase;

    setUp(() {
      mockDatabase = MockAppDatabase();
      repository = OptimizedDataExportRepository(mockDatabase);
    });

    test('should create optimized data export repository instance', () {
      expect(repository, isA<OptimizedDataExportRepository>());
    });

    test('should support stream export configuration', () {
      const config = StreamProcessingConfig(
        batchSize: 500,
        enableMemoryMonitoring: true,
      );
      
      expect(config.batchSize, equals(500));
      expect(config.enableMemoryMonitoring, isTrue);
    });

    test('should have backward compatibility methods', () async {
      // Test that all backward compatibility methods exist
      expect(repository.exportAllTables, isA<Function>());
      expect(repository.serializeToJson, isA<Function>());
      expect(repository.generateChecksum, isA<Function>());
      expect(repository.validateChecksum, isA<Function>());
      expect(repository.tableExists, isA<Function>());
      expect(repository.testConnection, isA<Function>());
      expect(repository.checkDatabaseIntegrity, isA<Function>());
      expect(repository.checkLongRunningTransactions, isA<Function>());
      expect(repository.isDatabaseLocked, isA<Function>());
      expect(repository.getTableRowCount, isA<Function>());
      expect(repository.exportTableBatch, isA<Function>());
    });

    test('should generate and validate checksums correctly', () {
      const testData = 'test data for checksum';
      
      final checksum1 = repository.generateChecksum(testData);
      final checksum2 = repository.generateChecksum(testData);
      
      // Same data should produce same checksum
      expect(checksum1, equals(checksum2));
      
      // Validation should work correctly
      expect(repository.validateChecksum(testData, checksum1), isTrue);
      expect(repository.validateChecksum(testData, 'wrong_checksum'), isFalse);
    });

    test('should serialize JSON correctly', () {
      final testData = {
        'key1': 'value1',
        'key2': 123,
        'key3': ['item1', 'item2'],
      };
      
      final json = repository.serializeToJson(testData);
      expect(json, isA<String>());
      expect(json, contains('key1'));
      expect(json, contains('value1'));
      
      final prettyJson = repository.serializeToJson(testData, prettyPrint: true);
      expect(prettyJson, contains('\n'));
      expect(prettyJson, contains('  '));
    });
  });
}