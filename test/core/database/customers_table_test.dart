import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

void main() {
  group('Customers table', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('has correct columns', () {
      final table = database.customers;
      final columns = table.columnsByName;

      expect(columns, hasLength(2));
      expect(columns.containsKey('id'), isTrue);
      expect(columns.containsKey('name'), isTrue);

      expect(columns['id']!.type, equals(DriftSqlType.int));
      expect(columns['name']!.type, equals(DriftSqlType.string));
    });
  });
}