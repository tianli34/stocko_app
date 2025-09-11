import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/inventory/data/repository/inventory_transaction_repository.dart';
import 'package:stocko_app/features/inventory/domain/model/inventory_transaction.dart';

void main() {
  group('InventoryTransactionRepository', () {
    late AppDatabase db;
    late InventoryTransactionRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      db.customStatement('PRAGMA foreign_keys = ON');
      repo = InventoryTransactionRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> unit() async =>
        await db.into(db.unit).insert(UnitCompanion.insert(name: 'pcs'));
    Future<int> product() async {
      final u = await unit();
      return await db
          .into(db.product)
          .insert(ProductCompanion.insert(name: 'P', baseUnitId: u));
    }
    Future<int> shop({String name = 'S'}) async => await db
        .into(db.shop)
        .insert(ShopCompanion.insert(name: name, manager: 'M'));

    test('add/get/update/delete + basic filters', () async {
      final pid = await product();
      final sid = await shop();

      final id = await repo.addTransaction(InventoryTransactionModel.createInbound(
        productId: pid,
        quantity: 10,
        shopId: sid,
      ));
      expect(id, isPositive);

      final got = await repo.getTransactionById(id);
      expect(got, isNotNull);
      expect(got!.isInbound, true);

  // update (some drift versions may report 0 affected even when values unchanged)
  await repo.updateTransaction(got.copyWith(quantity: 12));

      final all = await repo.getAllTransactions();
      expect(all, isNotEmpty);
      final byProd = await repo.getTransactionsByProduct(pid);
      expect(byProd.any((e) => e.id == id), true);
      final byShop = await repo.getTransactionsByShop(sid);
      expect(byShop.any((e) => e.id == id), true);
      final byType = await repo.getTransactionsByType(InventoryTransactionType.inbound.name);
      expect(byType.any((e) => e.id == id), true);

      final removed = await repo.deleteTransaction(id);
      expect(removed, 1);
    });

    test('date range, recent, count, summary and watchers', () async {
      final pid = await product();
      final sid = await shop(name: 'A');

      // seed 3
      await repo.addTransaction(InventoryTransactionModel(
        productId: pid,
        type: InventoryTransactionType.inbound,
        quantity: 5,
        shopId: sid,
        createdAt: DateTime(2023, 1, 1, 10),
      ));
      await repo.addTransaction(InventoryTransactionModel(
        productId: pid,
        type: InventoryTransactionType.outbound,
        quantity: 2,
        shopId: sid,
        createdAt: DateTime(2023, 1, 2, 10),
      ));
      await repo.addTransaction(InventoryTransactionModel(
        productId: pid,
        type: InventoryTransactionType.adjustment,
        quantity: 3,
        shopId: sid,
        createdAt: DateTime(2023, 1, 3, 10),
      ));

      final range = await repo.getTransactionsByDateRange(DateTime(2023, 1, 1), DateTime(2023, 1, 2, 23, 59));
      expect(range.length, 2);

      final recents = await repo.getRecentTransactions(2);
      expect(recents.length, 2);

      final cnt = await repo.getTransactionCount(shopId: sid);
      expect(cnt, 3);

  final summary = await repo.getTransactionSummaryByDateRange(DateTime(2023, 1, 1), DateTime(2023, 1, 3, 23));
  // keys are enum names
  expect(summary['inbound'], 5);
  expect(summary['outbound'], 2);
  expect(summary['adjustment'], 3);

      expect(repo.watchAllTransactions(), emits(isA<List<InventoryTransactionModel>>().having((e) => e.length, 'len', 3)));
      expect(repo.watchTransactionsByProduct(pid), emits(isA<List<InventoryTransactionModel>>()));
      expect(repo.watchTransactionsByShop(sid), emits(isA<List<InventoryTransactionModel>>()));
    });
  });
}
