import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/inventory/data/repository/inventory_repository.dart';
import 'package:stocko_app/features/inventory/domain/model/inventory.dart';

void main() {
  group('InventoryRepository', () {
    late AppDatabase db;
    late InventoryRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      db.customStatement('PRAGMA foreign_keys = ON');
      repo = InventoryRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> _unit() async =>
        await db.into(db.unit).insert(UnitCompanion.insert(name: 'pcs'));
    Future<int> _product() async {
      final u = await _unit();
      return await db
          .into(db.product)
          .insert(ProductCompanion.insert(name: 'P', baseUnitId: u));
    }
    Future<int> _shop() async => await db
        .into(db.shop)
        .insert(ShopCompanion.insert(name: 'S', manager: 'M'));

    test('add/get/update/delete inventory', () async {
      final pid = await _product();
      final sid = await _shop();

      final id = await repo.addInventory(
        StockModel(
          id: null,
          productId: pid,
          quantity: 0,
          shopId: sid,
          batchId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      expect(id, isPositive);

      final got = await repo.getInventoryById(id);
      expect(got, isNotNull);
      expect(got!.quantity, 0);

      final ok = await repo.updateInventory(
        got.copyWith(quantity: 5, updatedAt: DateTime.now()),
      );
      expect(ok, true);

      final removed = await repo.deleteInventory(id);
      expect(removed, 1);
    });

    test('quantity ops via dao helpers', () async {
      final pid = await _product();
      final sid = await _shop();

      final id = await repo.addInventory(
        StockModel(
          id: null,
          productId: pid,
          quantity: 10,
          shopId: sid,
          batchId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      expect(id, isPositive);

      final added = await repo.addInventoryQuantity(pid, sid, 3);
      expect(added, true);

      final sub = await repo.subtractInventoryQuantity(pid, sid, 5);
      expect(sub, true);

      final cur = await repo.getInventoryByProductAndShop(pid, sid);
      expect(cur!.quantity, 8);
    });
  });
}
