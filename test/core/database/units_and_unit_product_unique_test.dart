import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/database/database.dart';

void main() {
  group('units and unit_product unique constraints', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async => db.close());

    test('units.name is unique', () async {
      final id1 = await db.into(db.unit).insert(UnitCompanion.insert(name: 'pcs'));
      expect(id1, isPositive);

      expect(
        () async => db.into(db.unit).insert(UnitCompanion.insert(name: 'pcs')),
        throwsA(isA<Exception>()),
      );
    });

    test('unit_product composite unique (product_id, unit_id)', () async {
      final uid = await db.into(db.unit).insert(UnitCompanion.insert(name: 'box'));
      final pid = await db
          .into(db.product)
          .insert(ProductCompanion.insert(name: 'P', baseUnitId: uid));

      final u2 = await db.into(db.unit).insert(UnitCompanion.insert(name: 'bag'));

      final id = await db.into(db.unitProduct).insert(
            UnitProductCompanion.insert(
              productId: pid,
              unitId: u2,
              conversionRate: 10,
            ),
          );
      expect(id, isPositive);

      // duplicate pair should violate unique
      expect(
        () async => db.into(db.unitProduct).insert(
              UnitProductCompanion.insert(
                productId: pid,
                unitId: u2,
                conversionRate: 12,
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
