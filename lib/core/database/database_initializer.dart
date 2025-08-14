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
          
          updatedAt: Value(DateTime.now()),
        ),
        ShopsTableCompanion.insert(
          id: 'shop_branch_02',
          name: '田立的店',
          manager: 'tianli',
          
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
        _database.category,
      )..limit(1)).get();

      if (count.isNotEmpty) {
        print('📂 类别数据已存在，跳过初始化');
        return;
      }

      final defaultCategories = [
        CategoryCompanion.insert(
          id: const Value(1),
          name: '食品',
        ),
        CategoryCompanion.insert(
          id: const Value(2),
          name: '饮料',
        ),
        CategoryCompanion.insert(
          id: const Value(3),
          name: '日用品',
        ),
      ];

      await _database.transaction(() async {
        for (final category in defaultCategories) {
          await _database.into(_database.category).insert(category);
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
        _database.unit,
      )..limit(1)).get();

      if (count.isNotEmpty) {
        print('📏 单位数据已存在，跳过初始化');
        return;
      }
      final defaultUnits = [
        UnitCompanion.insert(
          id: Value(1),
          name: '个',
          
          
        ),
        UnitCompanion.insert(
          id: Value(2),
          name: '千克',
        ),
        UnitCompanion.insert(
          id: Value(3),
          name: '箱',
          
          
        ),
        UnitCompanion.insert(
          id: Value(4),
          name: '瓶',
          
          
        ),
        UnitCompanion.insert(
          id: Value(5),
          name: '包',
          
        ),
      ];

      await _database.transaction(() async {
        for (final unit in defaultUnits) {
          await _database.into(_database.unit).insert(unit);
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
        _database.product,
      )..limit(1)).get();

      if (count.isNotEmpty) {
        print('📦 商品数据已存在，跳过初始化');
        return;
      }

      final defaultProducts = [];

      await _database.transaction(() async {
        for (final product in defaultProducts) {
          await _database.into(_database.product).insert(product);
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
        _database.productUnit,
      )..limit(1)).get();

      if (count.isNotEmpty) {
        print('📦 产品单位数据已存在，跳过初始化');
        return;
      }

      final defaultProductUnits = [
        ProductUnitCompanion.insert(
          productUnitId: const Value(1),
          productId: 1,
          unitId: 2,
          conversionRate: 1, // 基础单位
          lastUpdated: Value(DateTime.now()),
        ),
        ProductUnitCompanion.insert(
          productUnitId: const Value(2),
          productId: 2,
          unitId: 2,
          conversionRate: 1, // 基础单位
          lastUpdated: Value(DateTime.now()),
        ),
        ProductUnitCompanion.insert(
          productUnitId: const Value(3),
          productId: 3,
          unitId: 4,
          conversionRate: 1, // 基础单位
          lastUpdated: Value(DateTime.now()),
        ),
        ProductUnitCompanion.insert(
          productUnitId: const Value(4),
          productId: 4, // 修改为整数ID
          unitId: 4,
          conversionRate: 1, // 基础单位
          lastUpdated: Value(DateTime.now()),
        ),
      ];

      await _database.transaction(() async {
        for (final productUnit in defaultProductUnits) {
          await _database.into(_database.productUnit).insert(productUnit);
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
        _database.barcode,
      )..limit(1)).get();

      if (count.isNotEmpty) {
        print('🏷️ 条码数据已存在，跳过初始化');
        return;
      }

      final defaultBarcodes = [
        BarcodeCompanion.insert(
          productUnitId: 1,
          barcodeValue: '1234567890123',
          
        ),
        BarcodeCompanion.insert(
          productUnitId: 2,
          barcodeValue: '1234567890124',
          
        ),
        BarcodeCompanion.insert(
          productUnitId: 3,
          barcodeValue: '1234567890125',
          
        ),
        BarcodeCompanion.insert(
          productUnitId: 4,
          barcodeValue: '1234567890126',
          
        ),
      ];

      await _database.transaction(() async {
        for (final barcode in defaultBarcodes) {
          await _database.into(_database.barcode).insert(barcode);
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
      await _database.delete(_database.inventoryTransaction).go();
      await _database.delete(_database.stock).go();
      await _database.delete(_database.productBatch).go();
      await _database.delete(_database.suppliersTable).go();

      // 删除基础数据表
      await _database.delete(_database.barcode).go();
      await _database.delete(_database.productUnit).go();
      await _database.delete(_database.product).go();
      await _database.delete(_database.shopsTable).go();
      await _database.delete(_database.category).go();
      await _database.delete(_database.unit).go();
    });

    await initializeAllDefaults();
    print('🔄 数据库已重置并重新初始化');
  }
}
