import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/inventory/data/repository/shop_repository.dart';
import 'package:stocko_app/features/inventory/domain/model/shop.dart';

void main() {
  group('ShopRepository', () {
    late AppDatabase db;
    late ShopRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      db.customStatement('PRAGMA foreign_keys = ON');
      repo = ShopRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('add/get/update/delete + watch', () async {
      final id = await repo.addShop(Shop.create(name: 'S', manager: 'M'));
      expect(id, isPositive);

      final one = await repo.getShopById(id);
      expect(one, isNotNull);
      expect(one!.name, 'S');

      final byName = await repo.getShopByName('S');
      expect(byName, isNotNull);

      final ok = await repo.updateShop(one.updateInfo(manager: 'MM'));
      expect(ok, true);

      final all = await repo.getAllShops();
      expect(all.length, 1);

      expect(repo.watchAllShops(), emits(isA<List<Shop>>().having((e) => e.length, 'len', 1)));

      final removed = await repo.deleteShop(id);
      expect(removed, 1);
    });

    test('search, name exists and count', () async {
      final id1 = await repo.addShop(Shop.create(name: 'Alpha', manager: 'Alice'));
      await repo.addShop(Shop.create(name: 'Beta', manager: 'Bob'));

      final byName = await repo.searchShopsByName('Al');
      expect(byName.map((e) => e.name), contains('Alpha'));

      final byMgr = await repo.searchShopsByManager('Bo');
      expect(byMgr.map((e) => e.manager), contains('Bob'));

      final exists = await repo.isShopNameExists('Alpha');
      expect(exists, true);
      final notExistsWhenExcluded = await repo.isShopNameExists('Alpha', id1);
      expect(notExistsWhenExcluded, false);

      final count = await repo.getShopCount();
      expect(count, 2);
    });
  });
}
