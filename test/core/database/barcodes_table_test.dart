import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';

void main() {
  group('Barcode table', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('has correct columns', () {
      final table = database.barcode;
      final columns = table.columnsByName;

      expect(columns, hasLength(3));
      expect(columns.containsKey('id'), isTrue);
      expect(columns.containsKey('unit_product_id'), isTrue);
      expect(columns.containsKey('barcode_value'), isTrue);

      expect(columns['id']!.type, equals(DriftSqlType.int));
      expect(columns['unit_product_id']!.type, equals(DriftSqlType.int));
      expect(columns['barcode_value']!.type, equals(DriftSqlType.string));
    });
  });
}