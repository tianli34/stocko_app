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
import 'shops_table.dart';
import 'suppliers_table.dart';
import 'batches_table.dart';
import 'inventory_table.dart';
import 'inventory_transactions_table.dart';
import 'locations_table.dart';
import 'inbound_receipts_table.dart';
import 'inbound_receipt_items_table.dart';
import '../../features/product/data/dao/product_dao.dart';
import '../../features/product/data/dao/category_dao.dart';
import '../../features/product/data/dao/unit_dao.dart';
import '../../features/product/data/dao/product_unit_dao.dart';
import '../../features/product/data/dao/supplier_dao.dart';
import '../../features/product/data/dao/batch_dao.dart';
import '../../features/inventory/data/dao/shop_dao.dart';
import '../../features/inventory/data/dao/inventory_dao.dart';
import '../../features/inventory/data/dao/inventory_transaction_dao.dart';
import '../../features/inbound/data/dao/location_dao.dart';
import '../../features/inbound/data/dao/inbound_receipt_dao.dart';
import '../../features/inbound/data/dao/inbound_item_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    ProductsTable,
    CategoriesTable,
    UnitsTable,
    ProductUnitsTable,
    ShopsTable,
    SuppliersTable,
    BatchesTable,
    InventoryTable,
    InventoryTransactionsTable,
    LocationsTable,
    InboundReceiptsTable,
    InboundReceiptItemsTable,
  ],
  daos: [
    ProductDao,
    CategoryDao,
    UnitDao,
    ProductUnitDao,
    ShopDao,
    SupplierDao,
    BatchDao,
    InventoryDao,
    InventoryTransactionDao,
    LocationDao,
    InboundReceiptDao,
    InboundItemDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);
  @override
  int get schemaVersion => 7;

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
      if (from == 5 && to == 6) {
        // 从版本5升级到版本6：添加店铺表
        await m.createTable(shopsTable);
      }
      if (from == 6 && to == 7) {
        // 从版本6升级到版本7：添加所有缺失的表
        await m.createTable(suppliersTable);
        await m.createTable(batchesTable);
        await m.createTable(inventoryTable);
        await m.createTable(inventoryTransactionsTable);
        await m.createTable(locationsTable);
        await m.createTable(inboundReceiptsTable);
        await m.createTable(inboundReceiptItemsTable);
      }
      // 处理从旧版本直接升级到版本7的情况
      if (from < 7 && to == 7) {
        // 确保所有表都存在
        if (from < 3) await m.createTable(categoriesTable);
        if (from < 4) await m.createTable(unitsTable);
        if (from < 5) await m.createTable(productUnitsTable);
        if (from < 6) await m.createTable(shopsTable);
        await m.createTable(suppliersTable);
        await m.createTable(batchesTable);
        await m.createTable(inventoryTable);
        await m.createTable(inventoryTransactionsTable);
        await m.createTable(locationsTable);
        await m.createTable(inboundReceiptsTable);
        await m.createTable(inboundReceiptItemsTable);
      }
      // 保留原有的迁移逻辑
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
