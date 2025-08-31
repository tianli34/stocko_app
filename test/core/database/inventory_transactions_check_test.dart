import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/database/database.dart';

void main() {
  group('inventory_transaction.type check constraint', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      db.customStatement('PRAGMA foreign_keys = ON');
    });

    tearDown(() async => db.close());

    Future<int> _shop() async => await db
        .into(db.shop)
        .insert(ShopCompanion.insert(name: 'S', manager: 'M'));
    Future<int> _unit() async =>
        await db.into(db.unit).insert(UnitCompanion.insert(name: 'pcs'));
    Future<int> _product() async {
      final uid = await _unit();
      return await db
          .into(db.product)
          .insert(ProductCompanion.insert(name: 'P', baseUnitId: uid));
    }

    test('accepts valid types', () async {
      final pid = await _product();
      final sid = await _shop();
  for (final t in ['in', 'out', 'adjust', 'transfer', 'return']) {
        final id = await db.into(db.inventoryTransaction).insert(
              InventoryTransactionCompanion.insert(
                productId: pid,
        transactionType: t,
                quantity: 1,
                shopId: sid,
              ),
            );
        expect(id, isPositive);
      }
    });

    test('rejects invalid type', () async {
      final pid = await _product();
      final sid = await _shop();
      expect(
        () async => db.into(db.inventoryTransaction).insert(
              InventoryTransactionCompanion.insert(
                productId: pid,
                transactionType: 'invalid',
                quantity: 1,
                shopId: sid,
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
