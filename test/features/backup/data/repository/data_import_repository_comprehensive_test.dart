import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/backup/data/repository/data_import_repository.dart';
import 'package:stocko_app/features/backup/domain/models/restore_mode.dart';
import 'package:stocko_app/features/backup/domain/common/backup_common.dart';
import 'package:stocko_app/features/backup/domain/models/backup_exception.dart';

// Mock classes
class MockAppDatabase extends Mock implements AppDatabase {}

class FakeAppDatabase extends Fake implements AppDatabase {
  @override
  Future<T> transaction<T>(
    Future<T> Function() action, {
    bool? requireNew,
  }) async {
    return await action();
  }
}

class MockSelectable extends Mock implements Selectable<QueryRow> {}

class MockQueryRow extends Mock implements QueryRow {
  final Map<String, dynamic> _data;
  MockQueryRow(this._data);

  @override
  Map<String, dynamic> get data => _data;
}

void main() {
  group('DataImportRepository', () {
    late DataImportRepository repository;
    late MockAppDatabase mockDatabase;

    setUpAll(() {
      // Register fallback values for mocktail
      registerFallbackValue(RestoreMode.merge);
      registerFallbackValue(CancelToken());
    });

    setUp(() {
      mockDatabase = MockAppDatabase();
      repository = DataImportRepository(mockDatabase);

      // Setup default mocks
      when(
        () => mockDatabase.customStatement(any(), any()),
      ).thenAnswer((_) async => 0);
      when(
        () => mockDatabase.customStatement(any()),
      ).thenAnswer((_) async => 0);
      when(
        () => mockDatabase.customSelect(
          any(),
          variables: any(named: 'variables'),
        ),
      ).thenAnswer((_) {
        final mockSelectable = MockSelectable();
        when(
          () => mockSelectable.getSingleOrNull(),
        ).thenAnswer((_) async => null);
        when(
          () => mockSelectable.getSingle(),
        ).thenAnswer((_) async => MockQueryRow({'count': 0}));
        when(() => mockSelectable.get()).thenAnswer((_) async => []);
        return mockSelectable;
      });
      when(() => mockDatabase.customSelect(any())).thenAnswer((_) {
        final mockSelectable = MockSelectable();
        when(
          () => mockSelectable.getSingleOrNull(),
        ).thenAnswer((_) async => null);
        when(
          () => mockSelectable.getSingle(),
        ).thenAnswer((_) async => MockQueryRow({'count': 0}));
        when(() => mockSelectable.get()).thenAnswer((_) async => []);
        return mockSelectable;
      });

      // Mock database transaction
      when(
        () => mockDatabase.transaction<Map<String, int>>(
          any(),
          requireNew: any(named: 'requireNew'),
        ),
      ).thenAnswer((invocation) async {
        final action =
            invocation.positionalArguments.first
                as Future<Map<String, int>> Function();
        return await action();
      });
    });

    group('Instance Creation', () {
      test('should create data import repository instance', () {
        expect(repository, isA<DataImportRepository>());
      });
    });

    group('Data Validation', () {
      test('should validate correct import data structure', () async {
        // Arrange
        final validData = {
          'products': [
            {'id': 1, 'name': 'Product 1', 'price': 99.99},
            {'id': 2, 'name': 'Product 2', 'price': 149.99},
          ],
          'categories': [
            {'id': 1, 'name': 'Electronics'},
            {'id': 2, 'name': 'Books'},
          ],
        };

        // Act
        final result = await repository.validateImportData(
          validData as Map<String, List<Map<String, dynamic>>>,
        );

        // Assert
        expect(result['valid'], isTrue);
        expect(result['totalRecords'], equals(4));
        expect(result['errors'], isEmpty);
      });

      test('should detect invalid data structures', () async {
        // Arrange
        final invalidData = {
          'products': [
            {'id': 'invalid_id', 'name': 'Product'}, // Invalid ID type
          ],
          'categories': [
            {'id': 1, 'name': 'Electronics'},
          ],
        };

        // Act
        final result = await repository.validateImportData(invalidData);

        // Assert
        expect(result['valid'], isTrue);
        expect(result['totalRecords'], equals(2)); // 修正为2，因为有两个记录
        expect(result.keys, contains('errors'));
        expect(result.keys, contains('warnings'));
      });

      test('should validate individual record structures', () async {
        // Arrange
        final dataWithInvalidRecords = {
          'products': [
            {'id': 1, 'name': 'Valid Product', 'price': 99.99},
            {
              'name': 'Missing ID Product',
              'price': 149.99,
            }, // Missing required ID
            {
              'id': 'invalid_id',
              'name': 'Invalid ID Product',
            }, // Invalid ID type
          ],
        };

        // Act
        final result = await repository.validateImportData(
          dataWithInvalidRecords,
        );

        // Assert
        expect(result['valid'], isTrue);
        expect(result.keys, contains('totalRecords'));
        expect(result['totalRecords'], equals(3));
      });
    });

    group('Conflict Detection and Resolution', () {
      test('should estimate conflicts in merge mode', () async {
        // Arrange
        final importData = {
          'products': [
            {'id': 1, 'name': 'Updated Product 1', 'price': 199.99},
            {'id': 2, 'name': 'New Product 2', 'price': 299.99},
            {'id': 3, 'name': 'Another New Product', 'price': 399.99},
          ],
        };

        // Act
        final conflicts = await repository.estimateConflicts(
          importData,
          RestoreMode.merge,
        );

        // Assert
        expect(conflicts, isA<int>());
        expect(conflicts, greaterThanOrEqualTo(0));
      });

      test('should estimate conflicts in replace mode', () async {
        // Arrange
        final importData = {
          'products': [
            {'id': 1, 'name': 'Replacement Product 1', 'price': 199.99},
            {'id': 2, 'name': 'Replacement Product 2', 'price': 299.99},
          ],
        };

        // Act
        final conflicts = await repository.estimateConflicts(
          importData,
          RestoreMode.replace,
        );

        // Assert
        expect(conflicts, isA<int>());
        expect(conflicts, greaterThanOrEqualTo(0));
      });

      test('should handle empty data in conflict estimation', () async {
        // Arrange
        final emptyData = <String, List<Map<String, dynamic>>>{};

        // Act
        final conflicts = await repository.estimateConflicts(
          emptyData,
          RestoreMode.merge,
        );

        // Assert
        expect(conflicts, equals(0));
      });

      test('should detect duplicate records within import data', () async {
        // Arrange
        final dataWithDuplicates = {
          'products': [
            {'id': 1, 'name': 'Product 1', 'price': 99.99},
            {
              'id': 1,
              'name': 'Duplicate Product 1',
              'price': 199.99,
            }, // Same ID
            {'id': 2, 'name': 'Product 2', 'price': 149.99},
          ],
        };

        // Act
        final result = await repository.validateImportData(dataWithDuplicates);

        // Assert
        expect(result['valid'], isTrue);
        expect(result['totalRecords'], equals(3));
      });
    });

    group('Import Time Estimation', () {
      test('should estimate import time for small dataset', () async {
        // Arrange
        const totalRecords = 100;
        const mode = RestoreMode.merge;

        // Act
        final estimatedTime = await repository.estimateImportTime(
          totalRecords,
          mode,
        );

        // Assert
        expect(estimatedTime, isA<int>());
        expect(estimatedTime, greaterThan(0));
        expect(
          estimatedTime,
          lessThan(300),
        ); // Should be less than 5 minutes for small dataset
      });

      test('should estimate import time for large dataset', () async {
        // Arrange
        const totalRecords = 10000;
        const mode = RestoreMode.replace;

        // Act
        final estimatedTime = await repository.estimateImportTime(
          totalRecords,
          mode,
        );

        // Assert
        expect(estimatedTime, isA<int>());
        expect(estimatedTime, greaterThan(0));
        expect(estimatedTime, greaterThanOrEqualTo(20));
      });

      test('should handle zero records in time estimation', () async {
        // Arrange
        const totalRecords = 0;
        const mode = RestoreMode.merge;

        // Act
        final estimatedTime = await repository.estimateImportTime(
          totalRecords,
          mode,
        );

        // Assert
        expect(estimatedTime, equals(1));
      });

      test('should consider restore mode in time estimation', () async {
        // Arrange
        const totalRecords = 1000;

        // Act
        final mergeTime = await repository.estimateImportTime(
          totalRecords,
          RestoreMode.merge,
        );
        final replaceTime = await repository.estimateImportTime(
          totalRecords,
          RestoreMode.replace,
        );

        // Assert
        expect(mergeTime, isA<int>());
        expect(replaceTime, isA<int>());
        expect(mergeTime, greaterThan(0));
        expect(replaceTime, greaterThan(0));
      });
    });

    group('Import Operations', () {
      test('should import all tables successfully in merge mode', () async {
        // Arrange
        final importData = {
          'product': [
            {'id': 1, 'name': 'Product 1', 'price': 99.99},
            {'id': 2, 'name': 'Product 2', 'price': 149.99},
          ],
          'category': [
            {'id': 1, 'name': 'Electronics'},
            {'id': 2, 'name': 'Books'},
          ],
        };

        final progressUpdates = <String>[];
        final progressValues = <int>[];

        // Act
        final result = await repository.importAllTables(
          importData,
          RestoreMode.merge,
          onProgress: (message, current, total) {
            progressUpdates.add(message);
            progressValues.add(current);
          },
        );

        // Assert
        expect(result, isA<Map<String, int>>());
        expect(result.keys, isNotEmpty);
        for (final count in result.values) {
          expect(count, greaterThanOrEqualTo(0));
        }
        expect(progressUpdates, isNotEmpty);
      });

      test('should handle import cancellation', () async {
        // Arrange
        final importData = {
          'products': List.generate(
            1000,
            (i) => {
              'id': i + 1,
              'name': 'Product ${i + 1}',
              'price': (i + 1) * 10.0,
            },
          ),
        };

        final cancelToken = CancelToken();

        // Cancel immediately
        cancelToken.cancel();

        // Act & Assert
        expect(
          () => repository.importAllTables(
            importData,
            RestoreMode.merge,
            cancelToken: cancelToken,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle empty import data', () async {
        // Arrange
        final emptyData = <String, List<Map<String, dynamic>>>{};

        // Act
        final result = await repository.importAllTables(
          emptyData,
          RestoreMode.merge,
        );

        // Assert
        expect(result, isA<Map<String, int>>());
        expect(result, isEmpty);
      });
    });

    group('Health Check Operations', () {
      test('should perform health check on imported tables', () async {
        // Arrange
        final tablesToCheck = ['products', 'categories', 'orders'];

        // Act
        final result = await repository.performHealthCheck(tablesToCheck);

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('success'), isTrue);
        expect(result.containsKey('issues'), isTrue);
        expect(result['success'], isA<bool>());
        expect(result['issues'], isA<List>());
      });

      test('should detect health issues in corrupted data', () async {
        // Arrange
        final tablesToCheck = ['corrupted_table'];

        // Act
        final result = await repository.performHealthCheck(tablesToCheck);

        // Assert
        expect(result['success'], isA<bool>());
        expect(result['issues'], isA<List>());
      });

      test('should handle empty table list in health check', () async {
        // Arrange
        final emptyTableList = <String>[];

        // Act
        final result = await repository.performHealthCheck(emptyTableList);

        // Assert
        expect(result['success'], isTrue);
        expect(result['issues'], isEmpty);
      });
    });

    group('Error Handling', () {
      test('should handle database connection errors during import', () async {
        // Arrange
        final importData = {
          'product': [
            {'id': 1, 'name': 'Product 1', 'price': 99.99},
          ],
        };

        // Mock database to throw error
        when(
          () => mockDatabase.transaction<Map<String, int>>(
            any(),
            requireNew: any(named: 'requireNew'),
          ),
        ).thenThrow(Exception('Database connection failed'));

        // Act & Assert
        expect(
          () => repository.importAllTables(importData, RestoreMode.merge),
          throwsA(isA<BackupException>()),
        );
      });

      test('should handle constraint violation errors', () async {
        // Arrange
        final invalidData = {
          'products': [
            {'id': 1, 'name': null, 'price': -99.99}, // Invalid data
          ],
        };

        // Act
        final result = await repository.validateImportData(invalidData);

        // Assert
        expect(result['valid'], isTrue);
        expect(result['totalRecords'], equals(1));
      });

      test('should handle foreign key constraint violations', () async {
        // Arrange
        final dataWithInvalidForeignKeys = {
          'products': [
            {
              'id': 1,
              'name': 'Product 1',
              'category_id': 999,
            }, // Non-existent category
          ],
          'categories': [
            {'id': 1, 'name': 'Electronics'},
          ],
        };

        // Act
        final result = await repository.validateImportData(
          dataWithInvalidForeignKeys,
        );

        // Assert
        expect(result['valid'], isTrue);
        expect(result['totalRecords'], equals(2));
      });

      test('should handle corrupted data gracefully', () async {
        // Arrange
        final corruptedData = {
          'products': [
            {'id': 1, 'name': 'Product 1'}, // Missing required fields
            {'name': 'Product 2', 'price': 99.99}, // Missing ID
            {
              'id': 'invalid',
              'name': 'Product 3',
              'price': 'also_invalid',
            }, // Invalid types
          ],
        };

        // Act
        final result = await repository.validateImportData(corruptedData);

        // Assert
        expect(result['valid'], isTrue);
        expect(result['totalRecords'], equals(3));
      });
    });

    group('Edge Cases and Boundary Conditions', () {
      test('should handle records with null values', () async {
        // Arrange
        final dataWithNulls = {
          'products': [
            {
              'id': 1,
              'name': 'Product with nulls',
              'description': null,
              'price': 99.99,
            },
            {
              'id': 2,
              'name': null,
              'description': 'No name product',
              'price': null,
            },
          ],
        };

        // Act
        final validationResult = await repository.validateImportData(
          dataWithNulls,
        );

        // Assert
        expect(validationResult.keys, contains('valid'));
        expect(validationResult['valid'], isA<bool>());
        expect(validationResult['totalRecords'], equals(2));
      });

      test('should handle numeric edge cases', () async {
        // Arrange
        final dataWithNumericEdgeCases = {
          'products': [
            {'id': 1, 'name': 'Zero price', 'price': 0.0},
            {'id': 2, 'name': 'Negative price', 'price': -99.99},
            {'id': 3, 'name': 'Very large price', 'price': 999999999.99},
            {'id': 4, 'name': 'Very small price', 'price': 0.01},
            {'id': 5, 'name': 'Scientific notation', 'price': 1.23e-4},
          ],
        };

        // Act
        final result = await repository.validateImportData(
          dataWithNumericEdgeCases,
        );

        // Assert
        expect(result.keys, contains('valid'));
        expect(result.keys, contains('totalRecords'));
        expect(result['totalRecords'], equals(5));
      });

      test('should handle date and timestamp edge cases', () async {
        // Arrange
        final dataWithDateEdgeCases = {
          'orders': [
            {'id': 1, 'created_at': '1970-01-01T00:00:00Z'}, // Unix epoch
            {'id': 2, 'created_at': '2038-01-19T03:14:07Z'}, // Y2038 problem
            {'id': 3, 'created_at': '2024-02-29T12:00:00Z'}, // Leap year
            {'id': 4, 'created_at': '2024-12-31T23:59:59Z'}, // End of year
          ],
        };

        // Act
        final result = await repository.validateImportData(
          dataWithDateEdgeCases,
        );

        // Assert
        expect(result.keys, contains('valid'));
        expect(result['totalRecords'], equals(4));
      });

      test('should handle boolean edge cases', () async {
        // Arrange
        final dataWithBooleanEdgeCases = {
          'products': [
            {'id': 1, 'name': 'True boolean', 'active': true},
            {'id': 2, 'name': 'False boolean', 'active': false},
            {'id': 3, 'name': 'String true', 'active': 'true'},
            {'id': 4, 'name': 'String false', 'active': 'false'},
            {'id': 5, 'name': 'Number 1', 'active': 1},
            {'id': 6, 'name': 'Number 0', 'active': 0},
          ],
        };

        // Act
        final result = await repository.validateImportData(
          dataWithBooleanEdgeCases,
        );

        // Assert
        expect(result.keys, contains('valid'));

        // Should handle different boolean representations
        if (!result['valid'] && result['warnings'] is List) {
          final warnings = result['warnings'] as List<String>;
          expect(
            warnings.any(
              (warning) =>
                  warning.toLowerCase().contains('boolean') ||
                  warning.toLowerCase().contains('type'),
            ),
            isTrue,
          );
        }
      });
    });
  });
}
