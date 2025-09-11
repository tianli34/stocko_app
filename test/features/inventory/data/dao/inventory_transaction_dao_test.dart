import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/inventory/data/dao/inventory_transaction_dao.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;

void main() {
  late AppDatabase db;
  late InventoryTransactionDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    db.customStatement('PRAGMA foreign_keys = ON');
    dao = db.inventoryTransactionDao;
  });

  tearDown(() async {
    await db.close();
  });

  // Helpers
  Future<int> unit() async =>
      await db.into(db.unit).insert(UnitCompanion.insert(name: 'pcs'));
  Future<int> product() async {
    final u = await unit();
    return await db
        .into(db.product)
        .insert(ProductCompanion.insert(name: 'P1', baseUnitId: u));
  }
  Future<int> shop({String name = 'S1'}) async => await db
      .into(db.shop)
      .insert(ShopCompanion.insert(name: name, manager: 'M'));
  Future<int> batch(int productId, int shopId) async => await db
      .into(db.productBatch)
      .insert(ProductBatchCompanion.insert(
        productId: productId,
        productionDate: DateTime(2024, 1, 1),
        totalInboundQuantity: 0,
        shopId: shopId,
      ));

  InventoryTransactionCompanion tx({
    required int productId,
    required String type,
    required int quantity,
    required int shopId,
    int? batchId,
    DateTime? createdAt,
  }) {
    return InventoryTransactionCompanion.insert(
      productId: productId,
      transactionType: type,
      quantity: quantity,
      shopId: shopId,
      batchId: batchId == null ? const Value.absent() : Value(batchId),
      createdAt: createdAt == null ? const Value.absent() : Value(createdAt),
    );
  }

  test('insert/get/update/delete and basic queries', () async {
    final pid = await product();
    final sid = await shop();
    final bid = await batch(pid, sid);

    final id = await dao.insertTransaction(
      tx(productId: pid, type: 'in', quantity: 10, shopId: sid, batchId: bid),
    );
    expect(id, isPositive);

    final got = await dao.getTransactionById(id);
    expect(got, isNotNull);
    expect(got!.productId, pid);
    expect(got.transactionType, 'in');

    // update
    final ok = await dao.updateTransaction(
      InventoryTransactionCompanion(
        id: Value(id),
        quantity: const Value(15),
      ),
    );
    expect(ok, true);

    // queries
    final all = await dao.getAllTransactions();
    expect(all, isNotEmpty);

    final byProduct = await dao.getTransactionsByProduct(pid);
    expect(byProduct.map((e) => e.id), contains(id));

    final byShop = await dao.getTransactionsByShop(sid);
    expect(byShop.map((e) => e.id), contains(id));

    final byType = await dao.getTransactionsByType('in');
    expect(byType.map((e) => e.id), contains(id));

    final byProdShop = await dao.getTransactionsByProductAndShop(pid, sid);
    expect(byProdShop.map((e) => e.id), contains(id));

    // delete
    final del = await dao.deleteTransaction(id);
    expect(del, 1);
  });

  test('date range, recents, count and watchers', () async {
    final pid = await product();
    final sid1 = await shop(name: 'A');
    final sid2 = await shop(name: 'B');

    final t1 = DateTime(2023, 1, 1, 10);
    final t2 = DateTime(2023, 1, 2, 10);
    final t3 = DateTime(2023, 1, 3, 10);

    await dao.insertTransaction(tx(productId: pid, type: 'in', quantity: 5, shopId: sid1, createdAt: t1));
    await dao.insertTransaction(tx(productId: pid, type: 'out', quantity: 2, shopId: sid1, createdAt: t2));
    await dao.insertTransaction(tx(productId: pid, type: 'in', quantity: 3, shopId: sid2, createdAt: t3));

    final range = await dao.getTransactionsByDateRange(DateTime(2023, 1, 1), DateTime(2023, 1, 2, 23, 59, 59));
    expect(range.length, 2);

    final rangeShop = await dao.getTransactionsByDateRange(DateTime(2023, 1, 1), DateTime(2023, 1, 4), shopId: sid2);
    expect(rangeShop.length, 1);

    final recent2 = await dao.getRecentTransactions(2);
    expect(recent2.length, 2);

    final cntAll = await dao.getTransactionCount();
    expect(cntAll, 3);
    final cntShop = await dao.getTransactionCount(shopId: sid1);
    expect(cntShop, 2);
    final cntType = await dao.getTransactionCount(type: 'in');
    expect(cntType, 2);

    // watchers
    final allStream = dao.watchAllTransactions();
    expect(
      allStream,
      emits(isA<List<InventoryTransactionData>>().having((e) => e.length, 'len', greaterThanOrEqualTo(3))),
    );

    final byProdStream = dao.watchTransactionsByProduct(pid);
    expect(
      byProdStream,
      emits(isA<List<InventoryTransactionData>>().having((e) => e.every((x) => x.productId == pid), 'all for product', true)),
    );

    final byShopStream = dao.watchTransactionsByShop(sid1);
    expect(
      byShopStream,
      emits(isA<List<InventoryTransactionData>>().having((e) => e.every((x) => x.shopId == sid1), 'all for shop', true)),
    );
  });
}
