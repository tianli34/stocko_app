import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/database/database.dart';

void main() {
  group('sales_transaction and items: FK and defaults', () {
    late AppDatabase db;

    setUp(() {
  db = AppDatabase(NativeDatabase.memory());
  db.customStatement('PRAGMA foreign_keys = ON');
    });

    tearDown(() async => db.close());

    Future<int> _customer() async =>
        await db.into(db.customers).insert(CustomersCompanion.insert(name: 'C'));
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

    test('sales_transaction has default status preset', () async {
      final cid = await _customer();
      final sid = await _shop();
      final id = await db.salesTransactionDao.insertSalesTransaction(
        SalesTransactionCompanion.insert(
          customerId: cid,
          shopId: sid,
          totalAmount: 0,
          actualAmount: 0,
        ),
      );
      final row = await db.salesTransactionDao.findSalesTransactionById(id);
      expect(row, isNotNull);
      expect(row!.status, 'preset');
    });

    test('sales_transaction_item basic FK', () async {
      final cid = await _customer();
      final sid = await _shop();
      final pid = await _product();
      final txId = await db.salesTransactionDao.insertSalesTransaction(
        SalesTransactionCompanion.insert(
          customerId: cid,
          shopId: sid,
          totalAmount: 100,
          actualAmount: 100,
        ),
      );

      final itemId = await db.salesTransactionItemDao.insertSalesTransactionItem(
        SalesTransactionItemCompanion.insert(
          salesTransactionId: txId,
          productId: pid,
          priceInCents: 1000,
          quantity: 1,
        ),
      );
      expect(itemId, isPositive);

      // invalid FKs should fail
      expect(
        () async => db.salesTransactionItemDao.insertSalesTransactionItem(
          SalesTransactionItemCompanion.insert(
            salesTransactionId: 9999,
            productId: 8888,
            priceInCents: 1,
            quantity: 1,
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
