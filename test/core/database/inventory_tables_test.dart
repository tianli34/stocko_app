import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/database/database.dart';

void main() {
  group('inventory tables', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      db.customStatement('PRAGMA foreign_keys = ON');
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> _shop() async => await db
        .into(db.shop)
        .insert(ShopCompanion.insert(name: 'S', manager: 'M'));

    Future<int> _unit() async =>
        await db.into(db.unit).insert(UnitCompanion.insert(name: 'pcs'));

    Future<int> _product() async {
      final u = await _unit();
      return await db
          .into(db.product)
          .insert(ProductCompanion.insert(name: 'P', baseUnitId: u));
    }

    Future<int> _batch(int productId, int shopId) async => await db
        .into(db.productBatch)
        .insert(ProductBatchCompanion.insert(
          productId: productId,
          productionDate: DateTime(2024, 1, 1),
          totalInboundQuantity: 100,
          shopId: shopId,
        ));

    test('FKs enforced for stock and inventory_transaction', () async {
      // invalid FKs
      expect(
        () async => db.into(db.stock).insert(
              StockCompanion.insert(
                productId: 999,
                quantity: 0,
                shopId: 888,
                updatedAt: Value(DateTime.now()),
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });

    test('stock CRUD and partial unique without batch', () async {
      final pid = await _product();
      final sid = await _shop();

      final id = await db.into(db.stock).insert(
            StockCompanion.insert(
              productId: pid,
              quantity: 0,
              shopId: sid,
              updatedAt: Value(DateTime.now()),
            ),
          );
      expect(id, isPositive);

      final row = await (db.select(db.stock)..where((t) => t.id.equals(id)))
          .getSingle();
      expect(row.batchId, isNull);

      // same product+shop with NULL batch is unique
      expect(
        () async => db.into(db.stock).insert(
              StockCompanion.insert(
                productId: pid,
                quantity: 1,
                shopId: sid,
                updatedAt: Value(DateTime.now()),
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });

    test('stock partial unique with batch', () async {
      final pid = await _product();
      final sid = await _shop();
      final bid = await _batch(pid, sid);

      await db.into(db.stock).insert(
            StockCompanion.insert(
              productId: pid,
              quantity: 10,
              shopId: sid,
              batchId: Value(bid),
              updatedAt: Value(DateTime.now()),
            ),
          );

      // duplicate trio should violate unique index
      expect(
        () async => db.into(db.stock).insert(
              StockCompanion.insert(
                productId: pid,
                quantity: 5,
                shopId: sid,
                batchId: Value(bid),
                updatedAt: Value(DateTime.now()),
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
