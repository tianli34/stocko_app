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
import 'purchase_orders_table.dart';
import 'purchase_order_items_table.dart';
import 'barcodes_table.dart'; // 新增条码表
import 'customers_table.dart';
import 'sales_transactions_table.dart';
import 'sales_transaction_items_table.dart';
import 'outbound_receipts_table.dart';
import 'outbound_receipt_items_table.dart';
import '../../features/product/data/dao/product_dao.dart';
import '../../features/product/data/dao/category_dao.dart';
import '../../features/product/data/dao/unit_dao.dart';
import '../../features/product/data/dao/product_unit_dao.dart';
import '../../features/purchase/data/dao/supplier_dao.dart';
import '../../features/product/data/dao/batch_dao.dart';
import '../../features/inventory/data/dao/shop_dao.dart';
import '../../features/inventory/data/dao/inventory_dao.dart';
import '../../features/inventory/data/dao/inventory_transaction_dao.dart';
import '../../features/inbound/data/dao/location_dao.dart';
import '../../features/inbound/data/dao/inbound_receipt_dao.dart';
import '../../features/inbound/data/dao/inbound_item_dao.dart';
import '../../features/purchase/data/dao/purchase_dao.dart';
import '../../features/product/data/dao/barcode_dao.dart';
import '../../features/sale/data/dao/customer_dao.dart';
import '../../features/sale/data/dao/sales_transaction_dao.dart';
import '../../features/sale/data/dao/sales_transaction_item_dao.dart';
import '../../features/outbound/data/dao/outbound_receipt_dao.dart';
import '../../features/outbound/data/dao/outbound_item_dao.dart';
import '../../features/product/domain/model/product.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Product,
    Category,
    Unit,
    UnitProduct,
    Shop,
    Supplier,
    ProductBatch,
    Stock,
    InventoryTransaction,
    LocationsTable,
    InboundReceipt,
    InboundItem,
    PurchaseOrder,
    PurchaseOrderItem,
    Barcode, // 新增条码表
    Customers,
    SalesTransaction,
    SalesTransactionItem,
    OutboundReceipt,
    OutboundItem,
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
    PurchaseDao,
    BarcodeDao, // 新增条码DAO
    CustomerDao,
    SalesTransactionDao,
    SalesTransactionItemDao,
    OutboundReceiptDao,
    OutboundItemDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);
  @override
  int get schemaVersion => 24; 

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      // 创建条码表的条码值索引以提高查询性能
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_barcode_barcode_value ON barcode(barcode_value);',
      );
      // 创建条码表的产品单位ID索引
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_barcode_unit_product_id ON barcode(unit_product_id);',
      );
      // 采购单相关索引
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_po_supplier ON purchase_order(supplier_id);',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_po_shop ON purchase_order(shop_id);',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_po_status ON purchase_order(status);',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_po_created ON purchase_order(created_at);',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_poi_po ON purchase_order_item(purchase_order_id);',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_poi_unit_product ON purchase_order_item(unit_product_id);',
      );
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS poi_unique_with_date ON purchase_order_item(purchase_order_id, unit_product_id, production_date) WHERE production_date IS NOT NULL;',
      );
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS poi_unique_without_date ON purchase_order_item(purchase_order_id, unit_product_id) WHERE production_date IS NULL;',
      );
      // 为库存表创建部分唯一索引
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS stock_unique_with_batch ON stock(product_id, shop_id, batch_id) WHERE batch_id IS NOT NULL;',
      );
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS stock_unique_without_batch ON stock(product_id, shop_id) WHERE batch_id IS NULL;',
      );
      // 为入库单明细表创建部分唯一索引
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS inbound_item_unique_with_batch ON inbound_item(receipt_id, product_id, batch_id) WHERE batch_id IS NOT NULL;',
      );
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS inbound_item_unique_without_batch ON inbound_item(receipt_id, product_id) WHERE batch_id IS NULL;',
      );
      // 为出库单明细表创建部分唯一索引
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS outbound_item_unique_with_batch ON outbound_item(receipt_id, product_id, batch_id) WHERE batch_id IS NOT NULL;',
      );
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS outbound_item_unique_without_batch ON outbound_item(receipt_id, product_id) WHERE batch_id IS NULL;',
      );
    },
    onUpgrade: (Migrator m, int from, int to) async {
      
      if (from < 24 && to >= 24) {
        // 迁移 purchase_order_item 表：将 product_id 改为 unit_product_id
        
        // 1. 创建新表
        await customStatement('''
          CREATE TABLE IF NOT EXISTS purchase_order_item_new (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            purchase_order_id INTEGER NOT NULL REFERENCES purchase_order (id) ON DELETE CASCADE,
            unit_product_id INTEGER NOT NULL REFERENCES unit_product (id) ON DELETE RESTRICT,
            production_date INTEGER,
            unit_price_in_cents INTEGER NOT NULL,
            quantity INTEGER NOT NULL,
            CHECK(quantity >= 1),
            CHECK(unit_price_in_cents >= 0)
          );
        ''');
        
        // 2. 迁移数据：将 product_id 映射到对应的 unit_product_id（使用基础单位）
        await customStatement('''
          INSERT INTO purchase_order_item_new (id, purchase_order_id, unit_product_id, production_date, unit_price_in_cents, quantity)
          SELECT 
            poi.id,
            poi.purchase_order_id,
            COALESCE(
              (SELECT up.id FROM unit_product up WHERE up.product_id = poi.product_id AND up.conversion_rate = 1 LIMIT 1),
              (SELECT up.id FROM unit_product up WHERE up.product_id = poi.product_id LIMIT 1)
            ) as unit_product_id,
            poi.production_date,
            poi.unit_price_in_cents,
            poi.quantity
          FROM purchase_order_item poi
          WHERE EXISTS (SELECT 1 FROM unit_product up WHERE up.product_id = poi.product_id);
        ''');
        
        // 3. 删除旧表
        await customStatement('DROP TABLE purchase_order_item;');
        
        // 4. 重命名新表
        await customStatement('ALTER TABLE purchase_order_item_new RENAME TO purchase_order_item;');
        
        // 5. 重建索引
        await customStatement('DROP INDEX IF EXISTS idx_poi_product;');
        await customStatement('DROP INDEX IF EXISTS poi_unique_with_date;');
        await customStatement('DROP INDEX IF EXISTS poi_unique_without_date;');
        
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_poi_po ON purchase_order_item(purchase_order_id);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_poi_unit_product ON purchase_order_item(unit_product_id);',
        );
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS poi_unique_with_date ON purchase_order_item(purchase_order_id, unit_product_id, production_date) WHERE production_date IS NOT NULL;',
        );
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS poi_unique_without_date ON purchase_order_item(purchase_order_id, unit_product_id) WHERE production_date IS NULL;',
        );
      }
      
      if (from < 23 && to >= 23) {
        // 添加 unit_id 列到 sales_transaction_item 表
        // 先检查列是否已存在
        final result = await customSelect(
          "PRAGMA table_info(sales_transaction_item);",
        ).get();
        
        final hasUnitId = result.any((row) => row.data['name'] == 'unit_id');
        
        if (!hasUnitId) {
          // 先添加为可空列
          await customStatement(
            'ALTER TABLE sales_transaction_item ADD COLUMN unit_id INTEGER REFERENCES unit (id);',
          );
        }
        
        // 如果有现有数据，需要为它们设置一个默认的 unit_id
        // 这里假设使用产品的基础单位（换算率为1的单位）
        await customStatement('''
          UPDATE sales_transaction_item 
          SET unit_id = (
            SELECT up.unit_id 
            FROM unit_product up 
            WHERE up.product_id = sales_transaction_item.product_id 
            AND up.conversion_rate = 1 
            LIMIT 1
          )
          WHERE unit_id IS NULL;
        ''');
      }
      if (from < 22 && to >= 22) {
        // 添加移动加权平均价格字段
        await m.addColumn(stock, stock.averageUnitPriceInCents);
        // 添加入库单明细表单价字段
        // await m.addColumn(inboundItem, inboundItem.unitPriceInCents);
      }
      if (from < 21 && to >= 21) {
        // 删除旧的唯一索引（如果存在）
        await customStatement('DROP INDEX IF EXISTS poi_unique_line;');
        // 创建新的条件唯一索引（注意：如果从21升级到24，这些索引会被24的迁移重建）
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS poi_unique_with_date ON purchase_order_item(purchase_order_id, product_id, production_date) WHERE production_date IS NOT NULL;',
        );
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS poi_unique_without_date ON purchase_order_item(purchase_order_id, product_id) WHERE production_date IS NULL;',
        );

        // 为库存表创建部分唯一索引（与 onCreate 保持一致，确保老版本升级后也具备约束）
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS stock_unique_with_batch ON stock(product_id, shop_id, batch_id) WHERE batch_id IS NOT NULL;',
        );
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS stock_unique_without_batch ON stock(product_id, shop_id) WHERE batch_id IS NULL;',
        );

        // 为出库单明细表创建部分唯一索引
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS outbound_item_unique_with_batch ON outbound_item(receipt_id, product_id, batch_id) WHERE batch_id IS NOT NULL;',
        );
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS outbound_item_unique_without_batch ON outbound_item(receipt_id, product_id) WHERE batch_id IS NULL;',
        );
      }
      if (from < 20 && to >= 20) {
        await m.createTable(outboundReceipt);
        await m.createTable(outboundItem);
      }
      if (from < 17 && to >= 17) {
        await m.createTable(salesTransaction);
        await m.createTable(salesTransactionItem);
      }
      if (from < 19 && to >= 19) {
        // 新增采购单/明细索引与唯一索引
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_po_supplier ON purchase_order(supplier_id);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_po_shop ON purchase_order(shop_id);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_po_status ON purchase_order(status);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_po_created ON purchase_order(created_at);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_poi_po ON purchase_order_item(purchase_order_id);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_poi_product ON purchase_order_item(product_id);',
        );
        // This is now handled by the migration to version 21
      }
      if (from < 18 && to >= 18) {
        // 为 sales_transaction_items 表的 unit_id 列添加明确的列名
        // 由于我们已经修改了表结构，需要重新创建表
        await m.createTable(salesTransactionItem);
      }
      if (from < 16 && to >= 16) {
        await m.createTable(customers);
      }
      if (from < 15 && to >= 15) {
        await m.addColumn(inboundReceipt, inboundReceipt.source);
      }
      if (from < 14 && to >= 14) {
        await m.deleteTable('purchases');
        await m.createTable(purchaseOrder);
        await m.createTable(purchaseOrderItem);
      }
      if (from < 13 && to >= 13) {
        // 为 product_units 表添加 wholesale_price 列
        await m.addColumn(unitProduct, unitProduct.wholesalePriceInCents);
      }
      if (from < 12 && to >= 12) {
        // 重建采购表以使 production_date 列可为空
        // This migration is now obsolete as purchasesTable is removed.
        // The logic is replaced by migration to version 14.
      }
      if (from < 11 && to >= 11) {
        // 添加条码表
        await m.createTable(barcode);
        // 创建条码表的索引
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_barcode_barcode_value ON barcode(barcode_value);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_barcode_unit_product_id ON barcode(unit_product_id);',
        );
      }
      
      if (from < 8 && to >= 8) {
        // This migration is now obsolete as purchasesTable is removed.
        // The logic is replaced by migration to version 14.
      }
      if (from == 1 && to == 2) {
        // 从版本1升级到版本2：修改产品表的ID列为非空
        // 由于SQLite不支持直接修改列的null约束，我们需要重建表
        await m.recreateAllViews();
      }
      if (from == 2 && to == 3) {
        // 从版本2升级到版本3：添加类别表
        await m.createTable(category);
      }
      if (from == 3 && to == 4) {
        // 从版本3升级到版本4：添加单位表
        await m.createTable(unit);
      }
      if (from == 4 && to == 5) {
        // 从版本4升级到版本5：添加产品单位表
        await m.createTable(unitProduct);
      }
      if (from == 5 && to == 6) {
        // 从版本5升级到版本6：添加店铺表
        await m.createTable(shop);
      }
      if (from == 6 && to == 7) {
        // 从版本6升级到版本7：添加所有缺失的表
        await m.createTable(supplier);
        await m.createTable(productBatch);
        await m.createTable(stock);
        await m.createTable(inventoryTransaction);
        await m.createTable(locationsTable);
        await m.createTable(inboundReceipt);
        await m.createTable(inboundItem);
      }
      // 处理从旧版本直接升级到版本7的情况
      if (from < 7 && to == 7) {
        // 确保所有表都存在
        if (from < 3) await m.createTable(category);
        if (from < 4) await m.createTable(unit);
        if (from < 5) await m.createTable(unitProduct);
        if (from < 6) await m.createTable(shop);
        await m.createTable(supplier);
        await m.createTable(productBatch);
        await m.createTable(stock);
        await m.createTable(inventoryTransaction);
        await m.createTable(locationsTable);
        await m.createTable(inboundReceipt);
        await m.createTable(inboundItem);
      }
      // 保留原有的迁移逻辑
      if (from == 1 && to == 3) {
        // 从版本1直接升级到版本3
        await m.recreateAllViews();
        await m.createTable(category);
      }
      if (from == 1 && to == 4) {
        // 从版本1直接升级到版本4
        await m.recreateAllViews();
        await m.createTable(category);
        await m.createTable(unit);
      }
      if (from == 1 && to == 5) {
        // 从版本1直接升级到版本5
        await m.recreateAllViews();
        await m.createTable(category);
        await m.createTable(unit);
        await m.createTable(unitProduct);
      }
      if (from == 2 && to == 4) {
        // 从版本2直接升级到版本4
        await m.createTable(category);
        await m.createTable(unit);
      }
      if (from == 2 && to == 5) {
        // 从版本2升级到版本5
        await m.createTable(category);
        await m.createTable(unit);
        await m.createTable(unitProduct);
      }
      if (from == 3 && to == 5) {
        // 从版本3升级到版本5
        await m.createTable(unit);
        await m.createTable(unitProduct);
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
