import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/product/data/repository/product_repository.dart';
import 'package:stocko_app/features/product/domain/model/product.dart';

void main() {
  group('ProductRepository', () {
    late AppDatabase db;
    late ProductRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      // enforce FKs
      db.customStatement('PRAGMA foreign_keys = ON');
      repo = ProductRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> _unit(String name) async =>
        await db.into(db.unit).insert(UnitCompanion.insert(name: name));

    test('add/get/update/delete product happy paths', () async {
      final unitId = await _unit('pcs');

      final product = ProductModel(
        name: 'Prod',
        baseUnitId: unitId,
        sku: 'SKU1',
      );

      final ok = await repo.addProduct(product);
      expect(ok, 1);

      final all = await repo.getAllProducts();
      expect(all.length, 1);
      final p = all.first;
      expect(p.name, 'Prod');

      final updatedOk = await repo.updateProduct(p.copyWith(name: 'P2'));
      expect(updatedOk, true);

      final fetched = await repo.getProductById(p.id!);
      expect(fetched!.name, 'P2');

      final deleted = await repo.deleteProduct(p.id!);
      expect(deleted, 1);
    });

    test('updateProduct throws when id missing', () async {
      final unitId = await _unit('box');
      final product = ProductModel(name: 'X', baseUnitId: unitId);
      expect(
        () => repo.updateProduct(product),
        throwsA(isA<Exception>()),
      );
    });
  });
}
