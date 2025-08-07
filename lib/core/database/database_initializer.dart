import 'package:drift/drift.dart';
import 'database.dart';

/// 数据库初始化服务
/// 负责初始化各种默认数据
class DatabaseInitializer {
  final AppDatabase _database;

  DatabaseInitializer(this._database);

  /// 初始化所有默认数据
  Future<void> initializeAllDefaults() async {
    await initializeDefaultShops();
    await initializeDefaultCategories();
    await initializeDefaultUnits();
    await initializeDefaultProducts();
    await initializeDefaultProductUnits();
    await initializeDefaultBarcodes();
    await initializeDefaultCustomers();
    // 可以继续添加其他初始化方法
  }

  /// 初始化默认店铺
  Future<void> initializeDefaultShops() async {
    try {
      // 检查是否已有数据
      final count = await (_database.select(
        _database.shopsTable,
      )..limit(1)).get();

      if (count.isNotEmpty) {
        print('🏪 店铺数据已存在，跳过初始化');
        return;
      }

      final defaultShops = [
        ShopsTableCompanion.insert(
          id: 'shop_branch_01',
          name: '长山的店',
          manager: 'changshan',
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        ShopsTableCompanion.insert(
          id: 'shop_branch_02',
          name: '田立的店',
          manager: 'tianli',
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      ];

      // 使用事务批量插入
      await _database.transaction(() async {
        for (final shop in defaultShops) {
          await _database.into(_database.shopsTable).insert(shop);
        }
      });

      print('✅ 成功初始化 ${defaultShops.length} 个默认店铺');
    } catch (e) {
      print('❌ 初始化默认店铺失败: $e');
      rethrow;
    }
  }

  /// 初始化默认类别
  Future<void> initializeDefaultCategories() async {
    try {
      final count = await (_database.select(
        _database.categoriesTable,
      )..limit(1)).get();

      if (count.isNotEmpty) {
        print('📂 类别数据已存在，跳过初始化');
        return;
      }

      final defaultCategories = [
        CategoriesTableCompanion.insert(
          id: 'cat_food',
          name: '食品',
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        CategoriesTableCompanion.insert(
          id: 'cat_beverage',
          name: '饮料',
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        CategoriesTableCompanion.insert(
          id: 'cat_daily',
          name: '日用品',
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      ];

      await _database.transaction(() async {
        for (final category in defaultCategories) {
          await _database.into(_database.categoriesTable).insert(category);
        }
      });

      print('✅ 成功初始化 ${defaultCategories.length} 个默认类别');
    } catch (e) {
      print('❌ 初始化默认类别失败: $e');
    }
  }

  /// 初始化默认单位
  Future<void> initializeDefaultUnits() async {
    try {
      final count = await (_database.select(
        _database.unitsTable,
      )..limit(1)).get();

      if (count.isNotEmpty) {
        print('📏 单位数据已存在，跳过初始化');
        return;
      }
      final defaultUnits = [
        UnitsTableCompanion.insert(
          id: 'unit_piece',
          name: '个',
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        UnitsTableCompanion.insert(
          id: 'unit_kg',
          name: '千克',
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        UnitsTableCompanion.insert(
          id: 'unit_box',
          name: '箱',
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        UnitsTableCompanion.insert(
          id: 'unit_bottle',
          name: '瓶',
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        UnitsTableCompanion.insert(
          id: 'unit_package',
          name: '包',
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      ];

      await _database.transaction(() async {
        for (final unit in defaultUnits) {
          await _database.into(_database.unitsTable).insert(unit);
        }
      });

      print('✅ 成功初始化 ${defaultUnits.length} 个默认单位');
    } catch (e) {
      print('❌ 初始化默认单位失败: $e');
    }
  }

  /// 初始化默认商品
  Future<void> initializeDefaultProducts() async {
    try {
      final count = await (_database.select(
        _database.productsTable,
      )..limit(1)).get();

      if (count.isNotEmpty) {
        print('📦 商品数据已存在，跳过初始化');
        return;
      }

      final defaultProducts = [
        ProductsTableCompanion.insert(
          id: const Value(1),
          name: '大米',
          categoryId: const Value('cat_food'),
          unitId: const Value('unit_kg'),
          retailPrice: const Value(2.5),
          suggestedRetailPrice: const Value(3.0),
          stockWarningValue: const Value(10),
          shelfLife: const Value(365),
          shelfLifeUnit: const Value('days'),
          enableBatchManagement: const Value(false),
          status: const Value('active'),
          lastUpdated: Value(DateTime.now()),
        ),
        ProductsTableCompanion.insert(
          id: const Value(2),
          name: '面粉',
          categoryId: const Value('cat_food'),
          unitId: const Value('unit_kg'),
          retailPrice: const Value(3.0),
          suggestedRetailPrice: const Value(3.5),
          stockWarningValue: const Value(5),
          shelfLife: const Value(180),
          shelfLifeUnit: const Value('days'),
          enableBatchManagement: const Value(false),
          status: const Value('active'),
          lastUpdated: Value(DateTime.now()),
        ),
        ProductsTableCompanion.insert(
          id: const Value(3),
          name: '可乐',
          categoryId: const Value('cat_beverage'),
          unitId: const Value('unit_bottle'),
          retailPrice: const Value(1.5),
          suggestedRetailPrice: const Value(2.0),
          stockWarningValue: const Value(20),
          shelfLife: const Value(365),
          shelfLifeUnit: const Value('days'),
          enableBatchManagement: const Value(false),
          status: const Value('active'),
          lastUpdated: Value(DateTime.now()),
        ),
        ProductsTableCompanion.insert(
          id: const Value(4),
          name: '矿泉水',
          categoryId: const Value('cat_beverage'),
          unitId: const Value('unit_bottle'),
          retailPrice: const Value(1.0),
          suggestedRetailPrice: const Value(1.5),
          stockWarningValue: const Value(30),
          shelfLife: const Value(730),
          shelfLifeUnit: const Value('days'),
          enableBatchManagement: const Value(true), // 启用批次管理
          status: const Value('active'),
          lastUpdated: Value(DateTime.now()),
        ),
        ProductsTableCompanion.insert(
          id: const Value(5),
          name: '面条',
          categoryId: const Value('cat_food'),
          unitId: const Value('unit_kg'),
          retailPrice: const Value(4.0),
          suggestedRetailPrice: const Value(4.5),
          stockWarningValue: const Value(8),
          shelfLife: const Value(180),
          shelfLifeUnit: const Value('days'),
          enableBatchManagement: const Value(false),
          status: const Value('active'),
          lastUpdated: Value(DateTime.now()),
        ),
        ProductsTableCompanion.insert(
          id: const Value(6),
          name: '牛奶',
          categoryId: const Value('cat_beverage'),
          unitId: const Value('unit_box'),
          retailPrice: const Value(5.0),
          suggestedRetailPrice: const Value(6.0),
          stockWarningValue: const Value(15),
          shelfLife: const Value(7),
          shelfLifeUnit: const Value('days'),
          enableBatchManagement: const Value(false),
          status: const Value('active'),
          lastUpdated: Value(DateTime.now()),
        ),
        ProductsTableCompanion.insert(
          id: const Value(7),
          name: '牙膏',
          categoryId: const Value('cat_daily'),
          unitId: const Value('unit_piece'),
          retailPrice: const Value(8.0),
          suggestedRetailPrice: const Value(10.0),
          stockWarningValue: const Value(5),
          shelfLife: const Value(730),
          shelfLifeUnit: const Value('days'),
          enableBatchManagement: const Value(false),
          status: const Value('active'),
          lastUpdated: Value(DateTime.now()),
        ),
        ProductsTableCompanion.insert(
          id: const Value(8),
          name: '酱油',
          categoryId: const Value('cat_food'),
          unitId: const Value('unit_bottle'),
          retailPrice: const Value(7.5),
          suggestedRetailPrice: const Value(8.0),
          stockWarningValue: const Value(10),
          shelfLife: const Value(365),
          shelfLifeUnit: const Value('days'),
          enableBatchManagement: const Value(false),
          status: const Value('active'),
          lastUpdated: Value(DateTime.now()),
        ),
        ProductsTableCompanion.insert(
          id: const Value(9),
          name: '卫生纸',
          categoryId: const Value('cat_daily'),
          unitId: const Value('unit_roll'),
          retailPrice: const Value(12.0),
          suggestedRetailPrice: const Value(15.0),
          stockWarningValue: const Value(5),
          shelfLife: const Value(1095),
          shelfLifeUnit: const Value('days'),
          enableBatchManagement: const Value(false),
          status: const Value('active'),
          lastUpdated: Value(DateTime.now()),
        ),
        ProductsTableCompanion.insert(
          id: const Value(10),
          name: '啤酒',
          categoryId: const Value('cat_beverage'),
          unitId: const Value('unit_bottle'),
          retailPrice: const Value(4.5),
          suggestedRetailPrice: const Value(6.0),
          stockWarningValue: const Value(20),
          shelfLife: const Value(180),
          shelfLifeUnit: const Value('days'),
          enableBatchManagement: const Value(false),
          status: const Value('active'),
          lastUpdated: Value(DateTime.now()),
        ),
        ProductsTableCompanion.insert(
          id: const Value(11),
          name: '洗发水',
          categoryId: const Value('cat_daily'),
          unitId: const Value('unit_bottle'),
          retailPrice: const Value(25.0),
          suggestedRetailPrice: const Value(30.0),
          stockWarningValue: const Value(8),
          shelfLife: const Value(365),
          shelfLifeUnit: const Value('days'),
          enableBatchManagement: const Value(false),
          status: const Value('active'),
          lastUpdated: Value(DateTime.now()),
        ),
        ProductsTableCompanion.insert(
          id: const Value(12),
          name: '鸡蛋',
          categoryId: const Value('cat_food'),
          unitId: const Value('unit_box'),
          retailPrice: const Value(15.0),
          suggestedRetailPrice: const Value(18.0),
          stockWarningValue: const Value(10),
          shelfLife: const Value(30),
          shelfLifeUnit: const Value('days'),
          enableBatchManagement: const Value(false),
          status: const Value('active'),
          lastUpdated: Value(DateTime.now()),
        ),
        ProductsTableCompanion.insert(
          id: const Value(13),
          name: '食盐',
          categoryId: const Value('cat_food'),
          unitId: const Value('unit_bag'),
          retailPrice: const Value(2.0),
          suggestedRetailPrice: const Value(3.0),
          stockWarningValue: const Value(5),
          shelfLife: const Value(730),
          shelfLifeUnit: const Value('days'),
          enableBatchManagement: const Value(false),
          status: const Value('active'),
          lastUpdated: Value(DateTime.now()),
        ),
        ProductsTableCompanion.insert(
          id: const Value(14),
          name: '抽纸',
          categoryId: const Value('cat_daily'),
          unitId: const Value('unit_pack'),
          retailPrice: const Value(8.0),
          suggestedRetailPrice: const Value(10.0),
          stockWarningValue: const Value(15),
          shelfLife: const Value(1095),
          shelfLifeUnit: const Value('days'),
          enableBatchManagement: const Value(false),
          status: const Value('active'),
          lastUpdated: Value(DateTime.now()),
        ),
      ];

      await _database.transaction(() async {
        for (final product in defaultProducts) {
          await _database.into(_database.productsTable).insert(product);
        }
      });

      print('✅ 成功初始化 ${defaultProducts.length} 个默认商品');
    } catch (e) {
      print('❌ 初始化默认商品失败: $e');
    }
  }

  /// 初始化默认商品单位关联
  Future<void> initializeDefaultProductUnits() async {
    try {
      final count = await (_database.select(
        _database.productUnitsTable,
      )..limit(1)).get();

      if (count.isNotEmpty) {
        print('📦 产品单位数据已存在，跳过初始化');
        return;
      }

      final defaultProductUnits = [
        ProductUnitsTableCompanion.insert(
          productUnitId: 'pu_rice_kg',
          productId: 1,
          unitId: 'unit_kg',
          conversionRate: 1.0, // 基础单位
          lastUpdated: Value(DateTime.now()),
        ),
        ProductUnitsTableCompanion.insert(
          productUnitId: 'pu_flour_kg',
          productId: 2,
          unitId: 'unit_kg',
          conversionRate: 1.0, // 基础单位
          lastUpdated: Value(DateTime.now()),
        ),
        ProductUnitsTableCompanion.insert(
          productUnitId: 'pu_cola_bottle',
          productId: 3,
          unitId: 'unit_bottle',
          conversionRate: 1.0, // 基础单位
          lastUpdated: Value(DateTime.now()),
        ),
        ProductUnitsTableCompanion.insert(
          productUnitId: 'pu_water_bottle',
          productId: 4, // 修改为整数ID
          unitId: 'unit_bottle',
          conversionRate: 1.0, // 基础单位
          lastUpdated: Value(DateTime.now()),
        ),
      ];

      await _database.transaction(() async {
        for (final productUnit in defaultProductUnits) {
          await _database.into(_database.productUnitsTable).insert(productUnit);
        }
      });

      print('✅ 成功初始化 ${defaultProductUnits.length} 个默认产品单位');
    } catch (e) {
      print('❌ 初始化默认产品单位失败: $e');
    }
  }

  /// 初始化默认条码
  Future<void> initializeDefaultBarcodes() async {
    try {
      final count = await (_database.select(
        _database.barcodesTable,
      )..limit(1)).get();

      if (count.isNotEmpty) {
        print('🏷️ 条码数据已存在，跳过初始化');
        return;
      }

      final defaultBarcodes = [
        BarcodesTableCompanion.insert(
          id: 'bc_rice',
          productUnitId: 'pu_rice_kg',
          barcode: '1234567890123',
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        BarcodesTableCompanion.insert(
          id: 'bc_flour',
          productUnitId: 'pu_flour_kg',
          barcode: '1234567890124',
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        BarcodesTableCompanion.insert(
          id: 'bc_cola',
          productUnitId: 'pu_cola_bottle',
          barcode: '1234567890125',
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        BarcodesTableCompanion.insert(
          id: 'bc_water',
          productUnitId: 'pu_water_bottle',
          barcode: '1234567890126',
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      ];

      await _database.transaction(() async {
        for (final barcode in defaultBarcodes) {
          await _database.into(_database.barcodesTable).insert(barcode);
        }
      });

      print('✅ 成功初始化 ${defaultBarcodes.length} 个默认条码');
    } catch (e) {
      print('❌ 初始化默认条码失败: $e');
    }
  }

  /// 初始化默认客户
  Future<void> initializeDefaultCustomers() async {
    try {
      final count = await (_database.select(
        _database.customers,
      )..limit(1)).get();

      if (count.isNotEmpty) {
        print('👥 客户数据已存在，跳过初始化');
        return;
      }

      final defaultCustomers = [
        CustomersCompanion.insert(
          id: const Value(0),
          name: '匿名散客',
        ),
      ];

      await _database.transaction(() async {
        for (final customer in defaultCustomers) {
          await _database.into(_database.customers).insert(customer);
        }
      });

      print('✅ 成功初始化 ${defaultCustomers.length} 个默认客户');
    } catch (e) {
      print('❌ 初始化默认客户失败: $e');
    }
  }

  /// 重置所有数据（仅用于开发/测试）
  Future<void> resetAllData() async {
    await _database.transaction(() async {
      // 删除销售相关的表数据
      await _database.delete(_database.salesTransactionItemsTable).go();
      await _database.delete(_database.salesTransactionsTable).go();
      await _database.delete(_database.customers).go();

      // 删除业务数据表
      await _database.delete(_database.inboundReceiptItemsTable).go();
      await _database.delete(_database.inboundReceiptsTable).go();
      await _database.delete(_database.purchaseOrderItemsTable).go();
      await _database.delete(_database.purchaseOrdersTable).go();
      await _database.delete(_database.inventoryTransactionsTable).go();
      await _database.delete(_database.inventoryTable).go();
      await _database.delete(_database.batchesTable).go();
      await _database.delete(_database.suppliersTable).go();

      // 删除基础数据表
      await _database.delete(_database.barcodesTable).go();
      await _database.delete(_database.productUnitsTable).go();
      await _database.delete(_database.productsTable).go();
      await _database.delete(_database.shopsTable).go();
      await _database.delete(_database.categoriesTable).go();
      await _database.delete(_database.unitsTable).go();
    });

    await initializeAllDefaults();
    print('🔄 数据库已重置并重新初始化');
  }
}
