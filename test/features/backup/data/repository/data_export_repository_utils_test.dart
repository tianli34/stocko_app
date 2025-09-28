import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/backup/data/repository/data_export_repository.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:mocktail/mocktail.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  group('DataExportRepository Utility Methods', () {
    late DataExportRepository repository;
    late MockAppDatabase mockDatabase;

    setUp(() {
      mockDatabase = MockAppDatabase();
      repository = DataExportRepository(mockDatabase);
    });

    group('serializeToJson', () {
      test('should serialize data to JSON string', () {
        // Arrange
        final data = {'key': 'value', 'number': 123};

        // Act
        final result = repository.serializeToJson(data);

        // Assert
        expect(result, isA<String>());
        expect(result, contains('key'));
        expect(result, contains('value'));
        expect(result, contains('123'));
      });

      test('should serialize with pretty print when requested', () {
        // Arrange
        final data = {'key': 'value'};

        // Act
        final result = repository.serializeToJson(data, prettyPrint: true);

        // Assert
        expect(result, contains('\n'));
        expect(result, contains('  '));
      });

      test('should handle empty data', () {
        // Arrange
        final data = <String, dynamic>{};

        // Act
        final result = repository.serializeToJson(data);

        // Assert
        expect(result, equals('{}'));
      });

      test('should handle nested data structures', () {
        // Arrange
        final data = {
          'level1': {
            'level2': ['item1', 'item2'],
            'number': 42
          }
        };

        // Act
        final result = repository.serializeToJson(data);

        // Assert
        expect(result, isA<String>());
        expect(result, contains('level1'));
        expect(result, contains('level2'));
        expect(result, contains('item1'));
      });
    });

    group('generateChecksum', () {
      test('should generate consistent SHA-256 checksum', () {
        // Arrange
        const data = 'test data';

        // Act
        final checksum1 = repository.generateChecksum(data);
        final checksum2 = repository.generateChecksum(data);

        // Assert
        expect(checksum1, equals(checksum2));
        expect(checksum1, hasLength(64)); // SHA-256 produces 64 character hex string
        expect(checksum1, matches(RegExp(r'^[a-f0-9]{64}$'))); // Valid hex string
      });

      test('should generate different checksums for different data', () {
        // Arrange
        const data1 = 'test data 1';
        const data2 = 'test data 2';

        // Act
        final checksum1 = repository.generateChecksum(data1);
        final checksum2 = repository.generateChecksum(data2);

        // Assert
        expect(checksum1, isNot(equals(checksum2)));
      });

      test('should handle empty string', () {
        // Arrange
        const data = '';

        // Act
        final checksum = repository.generateChecksum(data);

        // Assert
        expect(checksum, hasLength(64));
        expect(checksum, matches(RegExp(r'^[a-f0-9]{64}$')));
      });

      test('should handle unicode characters', () {
        // Arrange
        const data = '测试数据 🚀';

        // Act
        final checksum = repository.generateChecksum(data);

        // Assert
        expect(checksum, hasLength(64));
        expect(checksum, matches(RegExp(r'^[a-f0-9]{64}$')));
      });
    });

    group('validateChecksum', () {
      test('should return true for valid checksum', () {
        // Arrange
        const data = 'test data';
        final expectedChecksum = repository.generateChecksum(data);

        // Act
        final result = repository.validateChecksum(data, expectedChecksum);

        // Assert
        expect(result, true);
      });

      test('should return false for invalid checksum', () {
        // Arrange
        const data = 'test data';
        const invalidChecksum = 'invalid_checksum';

        // Act
        final result = repository.validateChecksum(data, invalidChecksum);

        // Assert
        expect(result, false);
      });

      test('should return false for empty checksum', () {
        // Arrange
        const data = 'test data';
        const emptyChecksum = '';

        // Act
        final result = repository.validateChecksum(data, emptyChecksum);

        // Assert
        expect(result, false);
      });

      test('should handle case sensitivity', () {
        // Arrange
        const data = 'test data';
        final checksum = repository.generateChecksum(data);
        final uppercaseChecksum = checksum.toUpperCase();

        // Act
        final result = repository.validateChecksum(data, uppercaseChecksum);

        // Assert
        expect(result, false); // SHA-256 hex should be lowercase
      });
    });

    group('getDatabaseSchemaVersion', () {
      test('should return database schema version', () async {
        // Arrange
        when(() => mockDatabase.schemaVersion).thenReturn(22);

        // Act
        final result = await repository.getDatabaseSchemaVersion();

        // Assert
        expect(result, 22);
        verify(() => mockDatabase.schemaVersion).called(1);
      });
    });
  });
}