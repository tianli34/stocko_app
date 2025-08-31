import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/inventory/data/dao/shop_dao.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;

void main() {
  late AppDatabase db;
  late ShopDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    db.customStatement('PRAGMA foreign_keys = ON');
    dao = db.shopDao;
  });

  tearDown(() async {
    await db.close();
  });

  ShopCompanion _shop({required String name, String manager = 'M'}) =>
      ShopCompanion.insert(name: name, manager: manager);

  test('CRUD + get by id/name + watch', () async {
    final id = await dao.insertShop(_shop(name: 'S1'));
    expect(id, isPositive);

    final one = await dao.getShopById(id);
    expect(one, isNotNull);
    expect(one!.name, 'S1');

    final byName = await dao.getShopByName('S1');
    expect(byName, isNotNull);

    final ok = await dao.updateShop(ShopCompanion(id: Value(id), manager: const Value('MM')));
    expect(ok, true);

    final all = await dao.getAllShops();
    expect(all.length, 1);

    expect(dao.watchAllShops(), emits(isA<List<ShopData>>().having((e) => e.length, 'len', 1)));

    final removed = await dao.deleteShop(id);
    expect(removed, 1);
  });

  test('search, isNameExists with excludeId, count', () async {
    final id1 = await dao.insertShop(_shop(name: 'Alpha', manager: 'Alice'));
    await dao.insertShop(_shop(name: 'Beta', manager: 'Bob'));

    final byName = await dao.searchShopsByName('Al');
    expect(byName.map((e) => e.name), contains('Alpha'));

    final byMgr = await dao.searchShopsByManager('Bo');
    expect(byMgr.map((e) => e.manager), contains('Bob'));

    final exists1 = await dao.isShopNameExists('Alpha');
    expect(exists1, true);
    final existsExcl = await dao.isShopNameExists('Alpha', id1 + 1);
    expect(existsExcl, true); // still true because other id exists
    final existsExclSelf = await dao.isShopNameExists('Alpha', id1);
    expect(existsExclSelf, false);

    final count = await dao.getShopCount();
    expect(count, 2);
  });
}
