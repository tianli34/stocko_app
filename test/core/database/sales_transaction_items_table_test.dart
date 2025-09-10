import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/database/database.dart';

void main() {
  group('sales_transaction_items_table', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      db.customStatement('PRAGMA foreign_keys = ON');
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> unit(String name) async =>
        await db.into(db.unit).insert(UnitCompanion.insert(name: name));

    Future<int> product() async {
      final unitId = await unit('pcs');
      return await db
          .into(db.product)
          .insert(ProductCompanion.insert(name: 'P', baseUnitId: unitId));
    }

  Future<int> customer() async => await db
    .into(db.customers)
    .insert(CustomersCompanion.insert(name: 'C'));

  Future<int> shop() async => await db
    .into(db.shop)
    .insert(ShopCompanion.insert(name: 'S', manager: 'M'));

    Future<int> transaction() async {
      final cid = await customer();
      final sid = await shop();
      return await db.salesTransactionDao.insertSalesTransaction(
        SalesTransactionCompanion.insert(
          customerId: cid,
          shopId: sid,
          totalAmount: 100,
          actualAmount: 100,
        ),
      );
    }

    Future<int> batch(int productId, int shopId) async {
      return await db.into(db.productBatch).insert(
            ProductBatchCompanion.insert(
              productId: productId,
              productionDate: DateTime(2024, 1, 1),
              totalInboundQuantity: 100,
              shopId: shopId,
            ),
          );
    }

    test('FKs enforced on insert', () async {
      // non-existing FKs should fail
      expect(
        () async =>
            db.into(db.salesTransactionItem).insert(
                  SalesTransactionItemCompanion.insert(
                    salesTransactionId: 999,
                    productId: 888,
                    priceInCents: 123,
                    quantity: 1,
                  ),
                ),
        throwsA(isA<Exception>()),
      );
    });

    test('CRUD without batch', () async {
      final tid = await transaction();
      final pid = await product();

      final id = await db.into(db.salesTransactionItem).insert(
            SalesTransactionItemCompanion.insert(
              salesTransactionId: tid,
              productId: pid,
              priceInCents: 999,
              quantity: 2,
            ),
          );

      final got = await (db.select(db.salesTransactionItem)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      expect(got.productId, pid);

      final updated = await (db.update(db.salesTransactionItem)
            ..where((t) => t.id.equals(id)))
          .write(const SalesTransactionItemCompanion(quantity: Value(5)));
      expect(updated, 1);

      final del = await (db.delete(db.salesTransactionItem)
            ..where((t) => t.id.equals(id)))
          .go();
      expect(del, 1);
    });

    test('CRUD with batch', () async {
      final tid = await transaction();
      final sid = await shop();
      final pid = await product();
      final bid = await batch(pid, sid);

      final id = await db.into(db.salesTransactionItem).insert(
            SalesTransactionItemCompanion.insert(
              salesTransactionId: tid,
              productId: pid,
              batchId: Value(bid),
              priceInCents: 1000,
              quantity: 3,
            ),
          );

      final row = await (db.select(db.salesTransactionItem)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      expect(row.batchId, bid);
    });

    test('deleting referenced transaction should be restricted', () async {
      final tid = await transaction();
      final pid = await product();
      await db.into(db.salesTransactionItem).insert(
            SalesTransactionItemCompanion.insert(
              salesTransactionId: tid,
              productId: pid,
              priceInCents: 1,
              quantity: 1,
            ),
          );

      // Should fail due to FK restrict
      expect(
        () async => (db.delete(db.salesTransaction)
              ..where((t) => t.id.equals(tid)))
            .go(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
