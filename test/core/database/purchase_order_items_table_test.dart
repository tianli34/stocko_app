import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/database/database.dart';

void main() {
  group('purchase_order_item conditional unique', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      db.customStatement('PRAGMA foreign_keys = ON');
    });

    tearDown(() async => db.close());

    Future<int> supplier() async =>
        await db.into(db.supplier).insert(SupplierCompanion.insert(name: 'X'));
    Future<int> shop() async =>
        await db.into(db.shop).insert(ShopCompanion.insert(name: 'S', manager: 'M'));
    Future<int> unit() async =>
        await db.into(db.unit).insert(UnitCompanion.insert(name: 'pcs'));
    Future<int> product() async {
      final u = await unit();
      return await db
          .into(db.product)
          .insert(ProductCompanion.insert(name: 'P', baseUnitId: u));
    }

    Future<int> po() async {
      final sid = await supplier();
      final shopId = await shop();
      return await db.into(db.purchaseOrder).insert(
            PurchaseOrderCompanion.insert(
              supplierId: sid,
              shopId: shopId,
            ),
          );
    }

    test('unique when production_date IS NULL', () async {
      final poId = await po();
      final pid = await product();

      await db.into(db.purchaseOrderItem).insert(
            PurchaseOrderItemCompanion.insert(
              purchaseOrderId: poId,
              productId: pid,
              unitPriceInCents: 100,
              quantity: 1,
            ),
          );

      // same po+product with NULL production_date -> unique violation
      expect(
        () async => db.into(db.purchaseOrderItem).insert(
              PurchaseOrderItemCompanion.insert(
                purchaseOrderId: poId,
                productId: pid,
                unitPriceInCents: 100,
                quantity: 2,
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });

    test('unique when production_date IS NOT NULL', () async {
      final poId = await po();
      final pid = await product();

      final date = DateTime(2024, 1, 1);
      await db.into(db.purchaseOrderItem).insert(
            PurchaseOrderItemCompanion.insert(
              purchaseOrderId: poId,
              productId: pid,
              productionDate: Value(date),
              unitPriceInCents: 100,
              quantity: 1,
            ),
          );

      // same trio po+product+date -> unique violation
      expect(
        () async => db.into(db.purchaseOrderItem).insert(
              PurchaseOrderItemCompanion.insert(
                purchaseOrderId: poId,
                productId: pid,
                productionDate: Value(date),
                unitPriceInCents: 100,
                quantity: 2,
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
