import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/purchase/data/repository/supplier_repository.dart';
import 'package:stocko_app/features/purchase/domain/model/supplier.dart';

void main() {
  group('SupplierRepository', () {
    late AppDatabase db;
    late SupplierRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      db.customStatement('PRAGMA foreign_keys = ON');
      repo = SupplierRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('add/get/update/delete and name exists checks', () async {
      final id = await repo.addSupplier(const Supplier(name: 'S1'));
      expect(id, isPositive);

      final got = await repo.getSupplierById(id);
      expect(got!.name, 'S1');

      final exists = await repo.isSupplierNameExists('S1');
      expect(exists, true);

      final updated = await repo.updateSupplier(Supplier(id: id, name: 'S2'));
      expect(updated, true);

      final byName = await repo.getSupplierByName('S2');
      expect(byName, isNotNull);

      final list = await repo.getAllSuppliers();
      expect(list, hasLength(1));

      final del = await repo.deleteSupplier(id);
      expect(del, 1);
    });

    test('search and count', () async {
      await repo.addSupplier(const Supplier(name: 'Alpha'));
      await repo.addSupplier(const Supplier(name: 'Beta'));
      await repo.addSupplier(const Supplier(name: 'Alpine'));

      final result = await repo.searchSuppliersByName('Al');
      expect(result.map((e) => e.name), containsAll(['Alpha', 'Alpine']));

      final count = await repo.getSupplierCount();
      expect(count, 3);
    });
  });
}
