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
import 'product_suppliers_table.dart';
import 'batches_table.dart';
import 'inventory_table.dart';
import 'inventory_transactions_table.dart';
import 'locations_table.dart';
import 'inbound_receipts_table.dart';
import 'inbound_receipt_items_table.dart';
import 'purchases_table.dart'; // 新增采购表
import 'barcodes_table.dart'; // 新增条码表
import '../../features/product/data/dao/product_dao.dart';
import '../../features/product/data/dao/category_dao.dart';
import '../../features/product/data/dao/unit_dao.dart';
import '../../features/product/data/dao/product_unit_dao.dart';
import '../../features/purchase/data/dao/supplier_dao.dart';
import '../../features/purchase/data/dao/product_supplier_dao.dart';
import '../../features/product/data/dao/batch_dao.dart';
import '../../features/inventory/data/dao/shop_dao.dart';
import '../../features/inventory/data/dao/inventory_dao.dart';
import '../../features/inventory/data/dao/inventory_transaction_dao.dart';
import '../../features/inbound/data/dao/location_dao.dart';
import '../../features/inbound/data/dao/inbound_receipt_dao.dart';
import '../../features/inbound/data/dao/inbound_item_dao.dart';
import '../../features/purchase/data/dao/purchase_dao.dart';
import '../../features/product/data/dao/barcode_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    ProductsTable,
    CategoriesTable,
    UnitsTable,
    ProductUnitsTable,
    ShopsTable,
    SuppliersTable,
    ProductSuppliersTable,
    BatchesTable,
    InventoryTable,
    InventoryTransactionsTable,
    LocationsTable,
    InboundReceiptsTable,
    InboundReceiptItemsTable,
    PurchasesTable, // 新增采购表
    BarcodesTable, // 新增条码表
  ],
  daos: [
    ProductDao,
    CategoryDao,
    UnitDao,
    ProductUnitDao,
    ShopDao,
    SupplierDao,
    ProductSupplierDao,
    BatchDao,
    InventoryDao,
    InventoryTransactionDao,
    LocationDao,
    InboundReceiptDao,
    InboundItemDao,
    PurchaseDao,
    BarcodeDao, // 新增条码DAO
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);
  @override
  int get schemaVersion => 13; // 提升版本以应用新的迁移

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      // 创建条码表的条码值索引以提高查询性能
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_barcodes_barcode ON barcodes(barcode);',
      );
      // 创建条码表的产品单位ID索引
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_barcodes_product_unit_id ON barcodes(product_unit_id);',
      );
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 13 && to >= 13) {
        // 为 product_units 表添加 wholesale_price 列
        await m.addColumn(productUnitsTable, productUnitsTable.wholesalePrice);
      }
      if (from < 12 && to >= 12) {
        // 重建采购表以使 production_date 列可为空
        await m.drop(purchasesTable);
        await m.createTable(purchasesTable);
      }
      if (from < 11 && to >= 11) {
        // 添加条码表
        await m.createTable(barcodesTable);
        // 创建条码表的索引
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_barcodes_barcode ON barcodes(barcode);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_barcodes_product_unit_id ON barcodes(product_unit_id);',
        );
      }
      if (from < 10 && to >= 10) {
        // 删除旧的product_suppliers表并重新创建（因为结构有重大变更）
        await m.drop(productSuppliersTable);
        await m.createTable(productSuppliersTable);
      }
      if (from < 9 && to >= 9) {
        await m.createTable(productSuppliersTable);
      }
      if (from < 8 && to >= 8) {
        await m.createTable(purchasesTable);
      }
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
      // 在任何版本升级后都确保条码表索引存在（移除了产品表条码索引，因为产品表已无条码字段）
      // 注释掉：产品表已无条码字段
      // await customStatement(
      //   'CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode);',
      // );
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
