import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/database/database.dart';

void main() {
  group('SalesTransactionDao', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> insertCustomer() async {
      return await db.into(db.customers).insert(
            CustomersCompanion.insert(name: 'Alice'),
          );
    }

    Future<int> insertShop() async {
      return await db.into(db.shop).insert(
            ShopCompanion.insert(name: 'Main', manager: 'Bob'),
          );
    }

    test('insert and find by id', () async {
      final customerId = await insertCustomer();
      final shopId = await insertShop();

      final id = await db.salesTransactionDao.insertSalesTransaction(
        SalesTransactionCompanion.insert(
          customerId: customerId,
          shopId: shopId,
          totalAmount: 100.0,
          actualAmount: 100.0,
        ),
      );

      final found = await db.salesTransactionDao.findSalesTransactionById(id);
      expect(found, isNotNull);
      expect(found!.customerId, customerId);
      expect(found.shopId, shopId);
      expect(found.totalAmount, 100.0);
    });

    test('watchAllSalesTransactions emits inserted rows', () async {
      final customerId = await insertCustomer();
      final shopId = await insertShop();

      final stream = db.salesTransactionDao.watchAllSalesTransactions();
      expect(stream, emits(isA<List<SalesTransactionData>>()));

      await db.salesTransactionDao.insertSalesTransaction(
        SalesTransactionCompanion.insert(
          customerId: customerId,
          shopId: shopId,
          totalAmount: 50.0,
          actualAmount: 50.0,
        ),
      );
    });

    test('update status returns true when row affected', () async {
      final customerId = await insertCustomer();
      final shopId = await insertShop();

      final id = await db.salesTransactionDao.insertSalesTransaction(
        SalesTransactionCompanion.insert(
          customerId: customerId,
          shopId: shopId,
          totalAmount: 10.0,
          actualAmount: 10.0,
        ),
      );

      final ok = await db.salesTransactionDao.updateSalesTransactionStatus(
        id,
        'settled',
      );
      expect(ok, isTrue);
      final updated = await db.salesTransactionDao.findSalesTransactionById(id);
      expect(updated!.status, 'settled');
    });
  });
}
