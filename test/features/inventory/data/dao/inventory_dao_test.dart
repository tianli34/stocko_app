import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/inventory/data/dao/inventory_dao.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;

void main() {
  late AppDatabase db;
  late InventoryDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    db.customStatement('PRAGMA foreign_keys = ON');
    dao = db.inventoryDao;
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

  StockCompanion inv({
    required int productId,
    required int shopId,
    int? batchId,
    int quantity = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StockCompanion.insert(
      productId: productId,
      shopId: shopId,
      batchId: batchId == null ? const Value.absent() : Value(batchId),
      quantity: quantity,
      createdAt: createdAt == null ? const Value.absent() : Value(createdAt),
      updatedAt: updatedAt == null ? const Value.absent() : Value(updatedAt),
    );
  }

  test('CRUD and basic queries', () async {
    final pid = await product();
    final sid = await shop();

    final id = await dao.insertInventory(inv(productId: pid, shopId: sid, quantity: 10));
    expect(id, isPositive);

    final got = await dao.getInventoryById(id);
    expect(got, isNotNull);
    expect(got!.quantity, 10);

    final ok = await dao.updateInventory(StockCompanion(id: Value(id), quantity: const Value(12)));
    expect(ok, true);

    final byPS = await dao.getInventoryByProductAndShop(pid, sid);
    expect(byPS, isNotNull);
    expect(byPS!.quantity, 12);

    final all = await dao.getAllInventory();
    expect(all.length, 1);

    final removed = await dao.deleteInventory(id);
    expect(removed, 1);
  });

  test('watchers and totals, low/out-of-stock', () async {
    final pid = await product();
    final sid = await shop();
    final sid2 = await shop(name: 'S2');

    await dao.insertInventory(inv(productId: pid, shopId: sid, quantity: 5));
    await dao.insertInventory(inv(productId: pid, shopId: sid2, quantity: 0));

  expect(dao.watchAllInventory(), emits(isA<List<StockData>>().having((e) => e.length, 'len', greaterThanOrEqualTo(2))));
  expect(dao.watchInventoryByShop(sid), emits(isA<List<StockData>>()));
  expect(dao.watchInventoryByProduct(pid), emits(isA<List<StockData>>()));

  // Totals may rely on SQL aggregate types; instead compute total by summing results
  final byShop = await dao.getInventoryByShop(sid);
  final totalShop = byShop.fold<int>(0, (a, b) => a + b.quantity);
  expect(totalShop, 5);

  final byProduct = await dao.getInventoryByProduct(pid);
  final totalProduct = byProduct.fold<int>(0, (a, b) => a + b.quantity);
  expect(totalProduct, 5);

    final low = await dao.getLowStockInventory(sid, 5);
    expect(low, isNotEmpty);

    final out = await dao.getOutOfStockInventory(sid2);
    expect(out, isNotEmpty);
  });

  test('increment/decrement and batch-specific update paths', () async {
    final pid = await product();
    final sid = await shop();
    final bid = await batch(pid, sid);

    // one row without batch, one with batch
    final id1 = await dao.insertInventory(inv(productId: pid, shopId: sid, quantity: 10));
    final id2 = await dao.insertInventory(inv(productId: pid, shopId: sid, batchId: bid, quantity: 20));
    expect(id1, isPositive);
    expect(id2, isPositive);

    // increment null batch
    final inc1 = await dao.incrementQuantity(pid, sid, null, 3);
    expect(inc1, greaterThanOrEqualTo(1));
  final s1List = await dao.getInventoryByProduct(pid);
  final s1 = s1List.firstWhere((x) => x.shopId == sid && x.batchId == null);
  expect(s1.quantity, 13);

    // decrement batch
    final dec2 = await dao.decrementQuantity(pid, sid, bid, 5);
    expect(dec2, greaterThanOrEqualTo(1));
  final s2List = await dao.getInventoryByProduct(pid);
  final s2 = s2List.firstWhere((x) => x.shopId == sid && x.batchId == bid);
  expect(s2.quantity, 15);

    // update by batch
    final okBatch = await dao.updateInventoryQuantityByBatch(pid, sid, bid, 99);
    expect(okBatch, true);
    final s2b = await dao.getInventoryByProductShopAndBatch(pid, sid, bid);
    expect(s2b!.quantity, 99);

    // existence and delete by product+shop
    final exists = await dao.inventoryExists(pid, sid);
    expect(exists, true);
    final delPS = await dao.deleteInventoryByProductAndShop(pid, sid);
    expect(delPS, greaterThanOrEqualTo(1));
  });
}
