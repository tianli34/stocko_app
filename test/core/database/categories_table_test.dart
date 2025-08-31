import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

void main() {
  group('Category table', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('has correct columns', () {
      final table = database.category;
      final columns = table.columnsByName;

      expect(columns, hasLength(3));
      expect(columns.containsKey('id'), isTrue);
      expect(columns.containsKey('name'), isTrue);
      expect(columns.containsKey('parent_id'), isTrue);

      expect(columns['id']!.type, equals(DriftSqlType.int));
      expect(columns['name']!.type, equals(DriftSqlType.string));
      expect(columns['parent_id']!.type, equals(DriftSqlType.int));
    });

    test('has correct unique keys', () {
      final table = database.category;
      final uniqueKeys = table.uniqueKeys;

      expect(uniqueKeys, hasLength(1));
      final uniqueKey = uniqueKeys.first;
      expect(uniqueKey, hasLength(2));
      expect(uniqueKey.contains(table.name), isTrue);
      expect(uniqueKey.contains(table.parentId), isTrue);
    });
  });
}