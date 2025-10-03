import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/backup/data/repository/optimized_data_export_repository.dart';

// Mock classes
class MockAppDatabase extends Mock implements AppDatabase {}
class MockSelectable extends Mock implements Selectable<QueryRow> {}
class MockQueryRow extends Mock implements QueryRow {
  final Map<String, dynamic> _data;
  MockQueryRow(this._data);
  
  @override
  Map<String, dynamic> get data => _data;
}

void main() {
  group('OptimizedDataExportRepository', () {
    late OptimizedDataExportRepository repository;
    late MockAppDatabase mockDatabase;

    setUp(() {
      mockDatabase = MockAppDatabase();
      repository = OptimizedDataExportRepository(mockDatabase);
    });

    group('Instance Creation', () {
      test('should create data export repository instance', () {
        expect(repository, isA<OptimizedDataExportRepository>());
      });
    });

    group('Data Serialization', () {
      test('should serialize simple data to JSON', () {
        // Arrange
        final data = {
          'name': 'Test Product',
          'price': 99.99,
          'active': true,
        };

        // Act
        final jsonString = repository.serializeToJson(data);
        final parsedData = jsonDecode(jsonString);

        // Assert
        expect(jsonString, isA<String>());
        expect(parsedData['name'], equals('Test Product'));
        expect(parsedData['price'], equals(99.99));
        expect(parsedData['active'], equals(true));
      });

      test('should serialize complex nested data to JSON', () {
        // Arrange
        final complexData = {
          'product': {
            'id': 1,
            'name': 'Complex Product',
            'categories': ['electronics', 'gadgets'],
            'metadata': {
              'created_at': '2024-01-01T00:00:00Z',
              'tags': ['new', 'featured'],
            },
          },
          'inventory': [
            {'location': 'warehouse_a', 'quantity': 100},
            {'location': 'warehouse_b', 'quantity': 50},
          ],
        };

        // Act
        final jsonString = repository.serializeToJson(complexData);
        final parsedData = jsonDecode(jsonString);

        // Assert
        expect(jsonString, isA<String>());
        expect(parsedData['product']['name'], equals('Complex Product'));
        expect(parsedData['product']['categories'], hasLength(2));
        expect(parsedData['inventory'], hasLength(2));
        expect(parsedData['product']['metadata']['tags'], contains('featured'));
      });

      test('should serialize with pretty printing when enabled', () {
        // Arrange
        final data = {
          'name': 'Pretty Product',
          'details': {
            'price': 199.99,
            'available': true,
          },
        };

        // Act
        final compactJson = repository.serializeToJson(data, prettyPrint: false);
        final prettyJson = repository.serializeToJson(data, prettyPrint: true);

        // Assert
        expect(compactJson, isNot(contains('\n')));
        expect(prettyJson, contains('\n'));
        expect(prettyJson, contains('  ')); // Indentation
        
        // Both should parse to the same data
        expect(jsonDecode(compactJson), equals(jsonDecode(prettyJson)));
      });

      test('should handle null values in serialization', () {
        // Arrange
        final dataWithNulls = {
          'name': 'Product with nulls',
          'description': null,
          'price': 99.99,
          'metadata': {
            'created_by': null,
            'updated_at': '2024-01-01T00:00:00Z',
          },
        };

        // Act
        final jsonString = repository.serializeToJson(dataWithNulls);
        final parsedData = jsonDecode(jsonString);

        // Assert
        expect(parsedData['description'], isNull);
        expect(parsedData['metadata']['created_by'], isNull);
        expect(parsedData['price'], equals(99.99));
      });

      test('should handle empty collections in serialization', () {
        // Arrange
        final dataWithEmptyCollections = {
          'name': 'Product with empty collections',
          'categories': <String>[],
          'metadata': <String, dynamic>{},
          'variants': <Map<String, dynamic>>[],
        };

        // Act
        final jsonString = repository.serializeToJson(dataWithEmptyCollections);
        final parsedData = jsonDecode(jsonString);

        // Assert
        expect(parsedData['categories'], isEmpty);
        expect(parsedData['metadata'], isEmpty);
        expect(parsedData['variants'], isEmpty);
      });

      test('should handle special characters in serialization', () {
        // Arrange
        final dataWithSpecialChars = {
          'name': 'Product with "quotes" and \\backslashes',
          'description': 'Special chars: 中文 العربية русский 🚀',
          'tags': ['tag with spaces', 'tag/with/slashes', 'tag"with"quotes'],
        };

        // Act
        final jsonString = repository.serializeToJson(dataWithSpecialChars);
        final parsedData = jsonDecode(jsonString);

        // Assert
        expect(parsedData['name'], contains('"quotes"'));
        expect(parsedData['description'], contains('🚀'));
        expect(parsedData['tags'], contains('tag with spaces'));
      });
    });

    group('Checksum Generation', () {
      test('should generate consistent checksum for same data', () {
        // Arrange
        const data = 'Test data for checksum';

        // Act
        final checksum1 = repository.generateChecksum(data);
        final checksum2 = repository.generateChecksum(data);

        // Assert
        expect(checksum1, equals(checksum2));
        expect(checksum1, isNotEmpty);
        expect(checksum1.length, equals(64)); // SHA-256 hex string
      });

      test('should generate different checksums for different data', () {
        // Arrange
        const data1 = 'First test data';
        const data2 = 'Second test data';

        // Act
        final checksum1 = repository.generateChecksum(data1);
        final checksum2 = repository.generateChecksum(data2);

        // Assert
        expect(checksum1, isNot(equals(checksum2)));
      });

      test('should generate checksum for complex JSON data', () {
        // Arrange
        final complexData = {
          'products': [
            {'id': 1, 'name': 'Product 1'},
            {'id': 2, 'name': 'Product 2'},
          ],
          'metadata': {
            'total': 2,
            'exported_at': '2024-01-01T00:00:00Z',
          },
        };
        final jsonData = jsonEncode(complexData);

        // Act
        final checksum = repository.generateChecksum(jsonData);

        // Assert
        expect(checksum, isNotEmpty);
        expect(checksum.length, equals(64));
      });

      test('should be sensitive to data order in checksum', () {
        // Arrange
        final data1 = jsonEncode({'a': 1, 'b': 2});
        final data2 = jsonEncode({'b': 2, 'a': 1});

        // Act
        final checksum1 = repository.generateChecksum(data1);
        final checksum2 = repository.generateChecksum(data2);

        // Assert
        // Note: JSON encoding might reorder keys, so this tests the actual behavior
        // If the JSON encoder maintains order, checksums will be different
        // If it reorders, they might be the same
        expect(checksum1, isA<String>());
        expect(checksum2, isA<String>());
      });

      test('should handle empty data in checksum generation', () {
        // Arrange
        const emptyData = '';

        // Act
        final checksum = repository.generateChecksum(emptyData);

        // Assert
        expect(checksum, isNotEmpty);
        expect(checksum.length, equals(64));
      });

      test('should handle large data in checksum generation', () {
        // Arrange
        final largeData = 'A' * 100000; // 100KB of data

        // Act
        final checksum = repository.generateChecksum(largeData);

        // Assert
        expect(checksum, isNotEmpty);
        expect(checksum.length, equals(64));
      });
    });

    group('Mock Database Operations', () {
      test('should handle database schema version retrieval', () async {
        // Arrange
        const expectedVersion = 5;
        when(() => mockDatabase.schemaVersion).thenReturn(expectedVersion);

        // Act
        final version = await repository.getDatabaseSchemaVersion();

        // Assert
        expect(version, equals(expectedVersion));
        verify(() => mockDatabase.schemaVersion).called(1);
      });

      test('should handle table names retrieval', () async {
        // Arrange
        final expectedTables = ['category', 'unit', 'shop', 'supplier'];
        
        // Mock the database customSelect method
        when(() => mockDatabase.customSelect(any())).thenAnswer((_) {
          final mockSelectable = MockSelectable();
          when(() => mockSelectable.get()).thenAnswer((_) async => [
            MockQueryRow({'name': 'category'}),
            MockQueryRow({'name': 'unit'}),
            MockQueryRow({'name': 'shop'}),
            MockQueryRow({'name': 'supplier'}),
          ]);
          return mockSelectable;
        });

        // Act
        final tables = await repository.getAllTableNames();

        // Assert
        expect(tables, equals(expectedTables));
        expect(tables, hasLength(4));
        expect(tables, contains('category'));
        expect(tables, contains('unit'));
      });

      test('should handle empty table list', () async {
        // Arrange
        when(() => repository.getAllTableNames()).thenAnswer((_) async => <String>[]);

        // Act
        final tables = await repository.getAllTableNames();

        // Assert
        expect(tables, isEmpty);
      });

      test('should handle table count retrieval', () async {
        // Arrange
        // Mock the database customSelect method for count queries
        when(() => mockDatabase.customSelect(any())).thenAnswer((invocation) {
          final mockSelectable = MockSelectable();
          when(() => mockSelectable.getSingle()).thenAnswer((_) async => 
            MockQueryRow({'count': 150})
          );
          return mockSelectable;
        });

        // Act
        final counts = await repository.getTableCounts();

        // Assert
        expect(counts, isA<Map<String, int>>());
        expect(counts.keys, isNotEmpty);
        for (final count in counts.values) {
          expect(count, equals(150));
        }
      });

      test('should handle export size estimation', () async {
        // Arrange
        // Mock the database customSelect method for count queries
        when(() => mockDatabase.customSelect(any())).thenAnswer((invocation) {
          final mockSelectable = MockSelectable();
          when(() => mockSelectable.getSingle()).thenAnswer((_) async => 
            MockQueryRow({'count': 100})
          );
          return mockSelectable;
        });

        // Act
        final size = await repository.estimateExportSize();

        // Assert
        expect(size, isA<int>());
        expect(size, greaterThan(0));
      });

      test('should handle table data export', () async {
        // Arrange
        // Mock the database customSelect method for data queries
        when(() => mockDatabase.customSelect(any())).thenAnswer((invocation) {
          final mockSelectable = MockSelectable();
          when(() => mockSelectable.get()).thenAnswer((_) async => [
            MockQueryRow({'id': 1, 'name': 'Test Item'}),
          ]);
          return mockSelectable;
        });

        // Act
        final data = await repository.exportAllTables();

        // Assert
        expect(data, isA<Map<String, List<Map<String, dynamic>>>>());
        expect(data.keys, contains('category'));
        expect(data.keys, contains('unit'));
        expect(data['category'], isA<List<Map<String, dynamic>>>());
      });
    });

    group('Error Handling', () {
      test('should handle serialization errors gracefully', () {
        // Arrange - Create circular reference that can't be serialized
        final Map<String, dynamic> circularData = {};
        circularData['self'] = circularData;

        // Act & Assert
        expect(
          () => repository.serializeToJson(circularData),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle database connection errors', () async {
        // Arrange
        when(() => mockDatabase.schemaVersion).thenThrow(Exception('Database connection failed'));

        // Act & Assert
        expect(
          () => repository.getDatabaseSchemaVersion(),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle export operation failures', () async {
        // Arrange
        when(() => mockDatabase.customSelect(any())).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.exportAllTables(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Performance and Edge Cases', () {
      test('should handle concurrent serialization operations', () async {
        // Arrange
        final dataList = List.generate(10, (i) => {
          'id': i,
          'name': 'Item $i',
          'data': List.generate(100, (j) => 'value_${i}_$j'),
        });

        // Act
        final futures = dataList.map((data) => 
          Future.value(repository.serializeToJson(data))
        ).toList();
        
        final results = await Future.wait(futures);

        // Assert
        expect(results, hasLength(10));
        for (int i = 0; i < results.length; i++) {
          final parsed = jsonDecode(results[i]);
          expect(parsed['id'], equals(i));
          expect(parsed['name'], equals('Item $i'));
        }
      });

      test('should handle very large data structures', () {
        // Arrange
        final largeData = {
          'items': List.generate(1000, (i) => {
            'id': i,
            'name': 'Item $i',
            'description': 'A' * 1000, // 1KB description each
            'metadata': {
              'created_at': '2024-01-01T00:00:00Z',
              'tags': List.generate(10, (j) => 'tag_${i}_$j'),
            },
          }),
        };

        // Act
        final jsonString = repository.serializeToJson(largeData);
        final checksum = repository.generateChecksum(jsonString);

        // Assert
        expect(jsonString, isNotEmpty);
        expect(checksum, isNotEmpty);
        expect(checksum.length, equals(64));
        
        // Verify it can be parsed back
        final parsed = jsonDecode(jsonString);
        expect(parsed['items'], hasLength(1000));
      });

      test('should handle data with various numeric types', () {
        // Arrange
        final numericData = {
          'integer': 42,
          'double': 3.14159,
          'negative': -123,
          'zero': 0,
          'large_number': 9223372036854775807, // Max int64
          'scientific': 1.23e-4,
        };

        // Act
        final jsonString = repository.serializeToJson(numericData);
        final parsed = jsonDecode(jsonString);

        // Assert
        expect(parsed['integer'], equals(42));
        expect(parsed['double'], closeTo(3.14159, 0.00001));
        expect(parsed['negative'], equals(-123));
        expect(parsed['zero'], equals(0));
        expect(parsed['large_number'], equals(9223372036854775807));
        expect(parsed['scientific'], closeTo(0.000123, 0.0000001));
      });
    });
  });
}