import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/database/database.dart';

void main() {
  group('inbound tables', () {
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

    Future<int> _receipt(int shopId) async => await db
        .into(db.inboundReceipt)
        .insert(InboundReceiptCompanion.insert(
          shopId: shopId,
          source: 'manual',
        ));

    Future<int> _batch(int productId, int shopId) async => await db
        .into(db.productBatch)
        .insert(ProductBatchCompanion.insert(
          productId: productId,
          productionDate: DateTime(2024, 1, 1),
          totalInboundQuantity: 100,
          shopId: shopId,
        ));

    test('FKs enforced for inbound_item', () async {
      expect(
        () async => db.into(db.inboundItem).insert(
              InboundItemCompanion.insert(
                receiptId: 999,
                productId: 888,
                quantity: 1,
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });

    test('partial unique without batch on inbound_item', () async {
      final sid = await _shop();
      final rid = await _receipt(sid);
      final pid = await _product();

      final id = await db.into(db.inboundItem).insert(
            InboundItemCompanion.insert(
              receiptId: rid,
              productId: pid,
              quantity: 5,
            ),
          );
      expect(id, isPositive);

      // same receipt+product with NULL batch must be unique
      expect(
        () async => db.into(db.inboundItem).insert(
              InboundItemCompanion.insert(
                receiptId: rid,
                productId: pid,
                quantity: 1,
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });

    test('partial unique with batch on inbound_item', () async {
      final sid = await _shop();
      final rid = await _receipt(sid);
      final pid = await _product();
      final bid = await _batch(pid, sid);

      await db.into(db.inboundItem).insert(
            InboundItemCompanion.insert(
              receiptId: rid,
              productId: pid,
              batchId: Value(bid),
              quantity: 10,
            ),
          );

      // duplicate trio should violate unique index
      expect(
        () async => db.into(db.inboundItem).insert(
              InboundItemCompanion.insert(
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
