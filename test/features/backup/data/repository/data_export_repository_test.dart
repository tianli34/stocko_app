import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stocko_app/features/backup/data/repository/data_export_repository.dart';
import 'package:stocko_app/core/database/database.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  group('DataExportRepository', () {
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
    });
  });
}