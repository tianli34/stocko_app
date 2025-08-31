import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/product/domain/model/product.dart';

void main() {
  group('Product table', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
  // Ensure SQLite enforces FK constraints in tests
  db.customStatement('PRAGMA foreign_keys = ON');
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> _insertUnit(String name) async {
      return await db.into(db.unit).insert(UnitCompanion.insert(name: name));
    }

    test('has key columns with expected types', () {
      final table = db.product;
      final columns = table.columnsByName;

      // spot check a few critical columns to avoid brittle exact count assertions
      expect(columns['id']!.type, equals(DriftSqlType.int));
      expect(columns['name']!.type, equals(DriftSqlType.string));
      expect(columns['base_unit_id']!.type, equals(DriftSqlType.int));
      // mapped Money fields are stored as int in DB
      expect(columns['retail_price']!.type, equals(DriftSqlType.int));
    });

    test('insert/read product with Money mapping works', () async {
      final unitId = await _insertUnit('pcs');

      final id = await db.into(db.product).insert(
            ProductCompanion.insert(
              name: 'Test Product',
              baseUnitId: unitId,
              sku: const Value('SKU-001'),
              suggestedRetailPrice: const Value(Money(1234)),
            ),
          );

      final row = await (db.select(db.product)..where((t) => t.id.equals(id)))
          .getSingle();

      expect(row.name, 'Test Product');
      expect(row.baseUnitId, unitId);
      expect(row.suggestedRetailPrice, isNotNull);
      expect(row.suggestedRetailPrice!.cents, 1234);
    });

    test('sku must be unique (violates unique constraint)', () async {
      final unitId = await _insertUnit('g');

      await db.into(db.product).insert(
            ProductCompanion.insert(
              name: 'P1',
              baseUnitId: unitId,
              sku: const Value('DUP'),
            ),
          );

      expect(
        () async =>
            db.into(db.product).insert(
                  ProductCompanion.insert(
                    name: 'P2',
                    baseUnitId: unitId,
                    sku: const Value('DUP'),
                  ),
                ),
        throwsA(isA<Exception>()),
      );
    });

    test('foreign key constraint on baseUnitId', () async {
      // 9999 unit does not exist
      expect(
        () async =>
            db.into(db.product).insert(
                  ProductCompanion.insert(
                    name: 'FK Product',
                    baseUnitId: 9999,
                  ),
                ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
