import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'products_table.dart';
import 'categories_table.dart';
import 'units_table.dart';
import 'product_units_table.dart';
import '../../features/product/data/dao/product_dao.dart';
import '../../features/product/data/dao/category_dao.dart';
import '../../features/product/data/dao/unit_dao.dart';
import '../../features/product/data/dao/product_unit_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [ProductsTable, CategoriesTable, UnitsTable, ProductUnitsTable],
  daos: [ProductDao, CategoryDao, UnitDao, ProductUnitDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from == 1 && to == 2) {
        // 从版本1升级到版本2：修改产品表的ID列为非空
        // 由于SQLite不支持直接修改列的null约束，我们需要重建表
        await m.recreateAllViews();
      }
      if (from == 2 && to == 3) {
        // 从版本2升级到版本3：添加类别表
        await m.createTable(categoriesTable);
      }
      if (from == 3 && to == 4) {
        // 从版本3升级到版本4：添加单位表
        await m.createTable(unitsTable);
      }
      if (from == 4 && to == 5) {
        // 从版本4升级到版本5：添加产品单位表
        await m.createTable(productUnitsTable);
      }
      if (from == 1 && to == 3) {
        // 从版本1直接升级到版本3
        await m.recreateAllViews();
        await m.createTable(categoriesTable);
      }
      if (from == 1 && to == 4) {
        // 从版本1直接升级到版本4
        await m.recreateAllViews();
        await m.createTable(categoriesTable);
        await m.createTable(unitsTable);
      }
      if (from == 1 && to == 5) {
        // 从版本1直接升级到版本5
        await m.recreateAllViews();
        await m.createTable(categoriesTable);
        await m.createTable(unitsTable);
        await m.createTable(productUnitsTable);
      }
      if (from == 2 && to == 4) {
        // 从版本2直接升级到版本4
        await m.createTable(categoriesTable);
        await m.createTable(unitsTable);
      }
      if (from == 2 && to == 5) {
        // 从版本2升级到版本5
        await m.createTable(categoriesTable);
        await m.createTable(unitsTable);
        await m.createTable(productUnitsTable);
      }
      if (from == 3 && to == 5) {
        // 从版本3升级到版本5
        await m.createTable(unitsTable);
        await m.createTable(productUnitsTable);
      }
    },
  );
}

@riverpod
AppDatabase appDatabase(Ref ref) {
  return AppDatabase(_openConnection());
}

QueryExecutor _openConnection() {
  // Use LazyDatabase with NativeDatabase for native platforms (mobile & desktop)
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app_database.db'));
    return NativeDatabase(file);
  });
}
