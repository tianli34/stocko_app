import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/backup/data/repository/optimized_data_export_repository.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:drift/native.dart';

void main() {
  group('OptimizedDataExportRepository Integration Tests', () {
    late AppDatabase database;
    late OptimizedDataExportRepository repository;

    setUp(() async {
      // Create an in-memory database for testing
      database = AppDatabase(NativeDatabase.memory());
      repository = OptimizedDataExportRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('should be able to get database schema version', () async {
      // Act
      final version = await repository.getDatabaseSchemaVersion();

      // Assert
      expect(version, isA<int>());
      expect(version, greaterThan(0));
    });

    test('should be able to get all table names', () async {
      // Act
      final tableNames = await repository.getAllTableNames();

      // Assert
      expect(tableNames, isA<List<String>>());
      expect(tableNames, isNotEmpty);
      
      // Check for some expected tables
      expect(tableNames, contains('product'));
      expect(tableNames, contains('category'));
      expect(tableNames, contains('unit'));
    });

    test('should be able to check if table exists', () async {
      // Act
      final productsExists = await repository.tableExists('product');
      final nonExistentExists = await repository.tableExists('non_existent_table');

      // Assert
      expect(productsExists, true);
      expect(nonExistentExists, false);
    });

    test('should be able to get table counts for empty database', () async {
      // Act
      final counts = await repository.getTableCounts();

      // Assert
      expect(counts, isA<Map<String, int>>());
      expect(counts.containsKey('product'), true);
      expect(counts.containsKey('category'), true);
      
      // All tables should be empty in a new database
      for (final count in counts.values) {
        expect(count, 0);
      }
    });

    test('should be able to estimate export size for empty database', () async {
      // Act
      final estimatedSize = await repository.estimateExportSize();

      // Assert
      expect(estimatedSize, isA<int>());
      expect(estimatedSize, greaterThanOrEqualTo(0));
    });

    test('should handle JSON serialization of complex backup data structure', () {
      // Arrange
      final backupData = {
        'metadata': {
          'id': 'backup_test_123',
          'version': '1.0.0',
          'createdAt': DateTime.now().toIso8601String(),
          'tableCounts': {'product': 0, 'category': 0},
          'checksum': 'test_checksum',
        },
        'data': {
          'product': <Map<String, dynamic>>[],
          'category': <Map<String, dynamic>>[],
        },
        'settings': {
          'autoBackupEnabled': true,
          'backupFrequency': 'weekly',
        },
      };

      // Act
      final jsonString = repository.serializeToJson(backupData);
      final prettyJsonString = repository.serializeToJson(backupData, prettyPrint: true);

      // Assert
      expect(jsonString, isA<String>());
      expect(jsonString, contains('metadata'));
      expect(jsonString, contains('backup_test_123'));
      
      expect(prettyJsonString, contains('\n'));
      expect(prettyJsonString.length, greaterThan(jsonString.length));
    });

    test('should generate and validate checksums for backup data', () {
      // Arrange
      final backupData = {
        'product': [
          {'id': 1, 'name': 'Test Product', 'price': 100},
          {'id': 2, 'name': 'Another Product', 'price': 200},
        ],
        'category': [
          {'id': 1, 'name': 'Test Category'},
        ],
      };
      final jsonString = repository.serializeToJson(backupData);

      // Act
      final checksum = repository.generateChecksum(jsonString);
      final isValid = repository.validateChecksum(jsonString, checksum);

      // Assert
      expect(checksum, hasLength(64));
      expect(isValid, true);
      
      // Verify checksum changes when data changes
      final modifiedData = Map<String, dynamic>.from(backupData);
      modifiedData['product'] = [
        {'id': 1, 'name': 'Modified Product', 'price': 150},
      ];
      final modifiedJsonString = repository.serializeToJson(modifiedData);
      final isValidForModified = repository.validateChecksum(modifiedJsonString, checksum);
      
      expect(isValidForModified, false);
    });
  });
}