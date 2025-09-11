import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/database/database.dart';

void main() {
  group('outbound tables', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      db.customStatement('PRAGMA foreign_keys = ON');
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> shop() async => await db
        .into(db.shop)
        .insert(ShopCompanion.insert(name: 'S', manager: 'M'));

    Future<int> unit() async =>
        await db.into(db.unit).insert(UnitCompanion.insert(name: 'pcs'));

    Future<int> product() async {
      final u = await unit();
      return await db
          .into(db.product)
          .insert(ProductCompanion.insert(name: 'P', baseUnitId: u));
    }

    Future<int> receipt(int shopId) async => await db
        .into(db.outboundReceipt)
        .insert(OutboundReceiptCompanion.insert(
          shopId: shopId,
          reason: 'Manual',
          createdAt: Value(DateTime.now()),
        ));

    Future<int> batch(int productId, int shopId) async => await db
        .into(db.productBatch)
        .insert(ProductBatchCompanion.insert(
          productId: productId,
          productionDate: DateTime(2024, 1, 1),
          totalInboundQuantity: 100,
          shopId: shopId,
        ));

    test('FKs enforced for outbound_item', () async {
      expect(
        () async => db.into(db.outboundItem).insert(
              OutboundItemCompanion.insert(
                receiptId: 999,
                productId: 888,
                quantity: 1,
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });

    test('CRUD and partial unique index on outbound_item (no batch)', () async {
      final sid = await shop();
      final rid = await receipt(sid);
      final pid = await product();

      final id = await db.into(db.outboundItem).insert(
            OutboundItemCompanion.insert(
              receiptId: rid,
              productId: pid,
              quantity: 10,
            ),
          );
      final row = await (db.select(db.outboundItem)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      expect(row.quantity, 10);

      // same receipt+product with NULL batch must be unique
      expect(
        () async => db.into(db.outboundItem).insert(
              OutboundItemCompanion.insert(
                receiptId: rid,
                productId: pid,
                quantity: 1,
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });

    test('partial unique index with batch', () async {
      final sid = await shop();
      final rid = await receipt(sid);
      final pid = await product();
      final bid = await batch(pid, sid);

      await db.into(db.outboundItem).insert(
            OutboundItemCompanion.insert(
              receiptId: rid,
              productId: pid,
              batchId: Value(bid),
              quantity: 5,
            ),
          );

      // same trio receipt+product+batch must be unique
      expect(
        () async => db.into(db.outboundItem).insert(
              OutboundItemCompanion.insert(
                receiptId: rid,
                productId: pid,
                batchId: Value(bid),
                quantity: 1,
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
