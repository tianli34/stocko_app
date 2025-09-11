import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/sale/data/repository/sales_transaction_repository.dart';
import 'package:stocko_app/features/sale/domain/model/sales_transaction.dart' as domain;
import 'package:stocko_app/features/sale/domain/model/sales_transaction_item.dart' as domain;
import 'package:stocko_app/features/sale/domain/model/sale_cart_item.dart' as domain;

void main() {
  group('SalesTransactionRepository', () {
    late AppDatabase db;
    late SalesTransactionRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = SalesTransactionRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> insertUnit(String name) async {
      return await db.into(db.unit).insert(UnitCompanion.insert(name: name));
    }

    Future<int> insertProduct({required int unitId, String name = 'P'}) async {
      return await db.into(db.product).insert(
            ProductCompanion.insert(name: name, baseUnitId: unitId),
          );
    }

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

    test('addSalesTransaction inserts header and items, then retrievable', () async {
      final customerId = await insertCustomer();
      final shopId = await insertShop();
      final unitId = await insertUnit('pcs');
      final productId = await insertProduct(unitId: unitId);

      final tx = domain.SalesTransaction(
        customerId: customerId,
        shopId: shopId,
        totalAmount: 12.0,
        actualAmount: 12.0,
        items: [
          domain.SalesTransactionItem(
            salesTransactionId: 0, // will be replaced in repository
            productId: productId,
            quantity: 2,
            priceInCents: 600,
          ),
        ],
      );

      final id = await repo.addSalesTransaction(tx);
      expect(id, isPositive);

      final loaded = await repo.getSalesTransactionById(id);
      expect(loaded, isNotNull);
      expect(loaded!.items, hasLength(1));
      expect(loaded.items.first.productId, productId);
      expect(loaded.items.first.quantity, 2);
    });

    test('handleOutbound merges items by (productId,batchId)', () async {
      final shopId = await insertShop();
      final unitId = await insertUnit('pcs');
      final p1 = await insertProduct(unitId: unitId, name: 'P1');
      final p2 = await insertProduct(unitId: unitId, name: 'P2');

      final salesId = await db.into(db.salesTransaction).insert(
            SalesTransactionCompanion.insert(
              customerId: await insertCustomer(),
              shopId: shopId,
              totalAmount: 0,
              actualAmount: 0,
            ),
          );

      final receiptId = await repo.handleOutbound(
        shopId,
        salesId,
        [
          domain.SaleCartItem(
            id: '1',
            productId: p1,
            productName: 'P1',
            unitId: unitId,
            unitName: 'pcs',
            sellingPriceInCents: 100,
            quantity: 1,
            amount: 1.0,
            conversionRate: 1,
          ),
          domain.SaleCartItem(
            id: '2',
            productId: p1,
            productName: 'P1',
            unitId: unitId,
            unitName: 'pcs',
            sellingPriceInCents: 100,
            quantity: 3,
            amount: 3.0,
            conversionRate: 1,
          ),
          domain.SaleCartItem(
            id: '3',
            productId: p2,
            productName: 'P2',
            unitId: unitId,
            unitName: 'pcs',
            sellingPriceInCents: 200,
            quantity: 2,
            amount: 4.0,
            conversionRate: 1,
          ),
        ],
      );

      expect(receiptId, isPositive);

      final items = await (db.select(db.outboundItem)
            ..where((t) => t.receiptId.equals(receiptId)))
          .get();
      // merged: p1 -> 1+3=4, p2 -> 2
      expect(items, hasLength(2));
      final p1Item = items.firstWhere((e) => e.productId == p1);
      expect(p1Item.quantity, 4);
      final p2Item = items.firstWhere((e) => e.productId == p2);
      expect(p2Item.quantity, 2);
    });
  });
}
