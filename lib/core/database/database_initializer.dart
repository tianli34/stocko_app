import 'package:drift/drift.dart';
import 'database.dart';
import '../../config/flavor_config.dart';

/// 数据库初始化服务
/// 负责初始化各种默认数据
class DatabaseInitializer {
  final AppDatabase _database;
  final FlavorConfig _flavorConfig;

  DatabaseInitializer(this._database, this._flavorConfig);

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
        _database.shop,
      )..limit(1)).get();

      if (count.isNotEmpty) {
        print('🏪 店铺数据已存在，跳过初始化');
        return;
      }

      // 根据 flavor 初始化不同的店铺
      final List<ShopCompanion> defaultShops;
      if (_flavorConfig.flavor == AppFlavor.generic) {
        defaultShops = [
          ShopCompanion.insert(
            id: Value(1),
            name: '我的店铺',
            manager: 'admin',
            updatedAt: Value(DateTime.now()),
          ),
        ];
      } else {
        defaultShops = [
          ShopCompanion.insert(
            id: Value(1),
            name: '长山的店',
            manager: 'changshan',
            updatedAt: Value(DateTime.now()),
          ),
          ShopCompanion.insert(
            id: Value(2),
            name: '田立的店',
            manager: 'tianli',
            updatedAt: Value(DateTime.now()),
          ),
        ];
      }

      // 使用事务批量插入
      await _database.transaction(() async {
        for (final shop in defaultShops) {
          await _database.into(_database.shop).insert(shop);
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
      rethrow;
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
      rethrow;
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

      final defaultProducts = [
        ProductCompanion.insert(
          id: const Value(1),
          name: '可口可乐',
          categoryId: const Value(2),
          baseUnitId: 4, // 瓶
        ),
        ProductCompanion.insert(
          id: const Value(2),
          name: '康师傅冰红茶',
          categoryId: const Value(2),
          baseUnitId: 4, // 瓶
        ),
        ProductCompanion.insert(
          id: const Value(3),
          name: '农夫山泉',
          categoryId: const Value(2),
          baseUnitId: 4, // 瓶
        ),
        ProductCompanion.insert(
          id: const Value(4),
          name: '奥利奥',
          categoryId: const Value(1),
          baseUnitId: 5, // 包
        ),
        ProductCompanion.insert(
          id: const Value(5),
          name: '乐事薯片',
          categoryId: const Value(1),
          baseUnitId: 5, // 包
        ),
        ProductCompanion.insert(
          id: const Value(6),
          name: '统一老坛酸菜牛肉面',
          categoryId: const Value(1),
          baseUnitId: 5, // 包
        ),
        ProductCompanion.insert(
          id: const Value(7),
          name: '清风抽纸',
          categoryId: const Value(3),
          baseUnitId: 5, // 包
        ),
        ProductCompanion.insert(
          id: const Value(8),
          name: '高露洁牙膏',
          categoryId: const Value(3),
          baseUnitId: 1, // 个
        ),
        ProductCompanion.insert(
          id: const Value(9),
          name: '娃哈哈AD钙奶',
          categoryId: const Value(2),
          baseUnitId: 4, // 瓶
        ),
        ProductCompanion.insert(
          id: const Value(10),
          name: '达利园蛋黄派',
          categoryId: const Value(1),
          baseUnitId: 5, // 包
        ),
      ];

      await _database.transaction(() async {
        for (final product in defaultProducts) {
          await _database.into(_database.product).insert(product);
        }
      });

      print('✅ 成功初始化 ${defaultProducts.length} 个默认商品');
    } catch (e) {
      print('❌ 初始化默认商品失败: $e');
      rethrow;
    }
  }

  /// 初始化默认商品单位关联
  Future<void> initializeDefaultProductUnits() async {
    try {
      final count = await (_database.select(
        _database.unitProduct,
      )..limit(1)).get();

      if (count.isNotEmpty) {
        print('📦 产品单位数据已存在，跳过初始化');
        return;
      }

      final defaultProductUnits = [
        // 可口可乐, 瓶
        UnitProductCompanion.insert(
          id: const Value(1),
          productId: 1,
          unitId: 4,
          conversionRate: 1,
          lastUpdated: Value(DateTime.now()),
        ),
        // 康师傅冰红茶, 瓶
        UnitProductCompanion.insert(
          id: const Value(2),
          productId: 2,
          unitId: 4,
          conversionRate: 1,
          lastUpdated: Value(DateTime.now()),
        ),
        // 农夫山泉, 瓶
        UnitProductCompanion.insert(
          id: const Value(3),
          productId: 3,
          unitId: 4,
          conversionRate: 1,
          lastUpdated: Value(DateTime.now()),
        ),
        // 奥利奥, 包
        UnitProductCompanion.insert(
          id: const Value(4),
          productId: 4,
          unitId: 5,
          conversionRate: 1,
          lastUpdated: Value(DateTime.now()),
        ),
        // 乐事薯片, 包
        UnitProductCompanion.insert(
          id: const Value(5),
          productId: 5,
          unitId: 5,
          conversionRate: 1,
          lastUpdated: Value(DateTime.now()),
        ),
        // 统一老坛酸菜牛肉面, 包
        UnitProductCompanion.insert(
          id: const Value(6),
          productId: 6,
          unitId: 5,
          conversionRate: 1,
          lastUpdated: Value(DateTime.now()),
        ),
        // 清风抽纸, 包
        UnitProductCompanion.insert(
          id: const Value(7),
          productId: 7,
          unitId: 5,
          conversionRate: 1,
          lastUpdated: Value(DateTime.now()),
        ),
        // 高露洁牙膏, 个
        UnitProductCompanion.insert(
          id: const Value(8),
          productId: 8,
          unitId: 1,
          conversionRate: 1,
          lastUpdated: Value(DateTime.now()),
        ),
        // 娃哈哈AD钙奶, 瓶
        UnitProductCompanion.insert(
          id: const Value(9),
          productId: 9,
          unitId: 4,
          conversionRate: 1,
          lastUpdated: Value(DateTime.now()),
        ),
        // 达利园蛋黄派, 包
        UnitProductCompanion.insert(
          id: const Value(10),
          productId: 10,
          unitId: 5,
          conversionRate: 1,
          lastUpdated: Value(DateTime.now()),
        ),
      ];

      await _database.transaction(() async {
        for (final unitProduct in defaultProductUnits) {
          await _database.into(_database.unitProduct).insert(unitProduct);
        }
      });

      print('✅ 成功初始化 ${defaultProductUnits.length} 个默认产品单位');
    } catch (e) {
      print('❌ 初始化默认产品单位失败: $e');
      rethrow;
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
        BarcodeCompanion.insert(unitProductId: 1, barcodeValue: '6901234567890'), // 可口可乐
        BarcodeCompanion.insert(unitProductId: 2, barcodeValue: '6901234567891'), // 康师傅冰红茶
        BarcodeCompanion.insert(unitProductId: 3, barcodeValue: '6901234567892'), // 农夫山泉
        BarcodeCompanion.insert(unitProductId: 4, barcodeValue: '6901234567893'), // 奥利奥
        BarcodeCompanion.insert(unitProductId: 5, barcodeValue: '6901234567894'), // 乐事薯片
        BarcodeCompanion.insert(unitProductId: 6, barcodeValue: '6901234567895'), // 统一老坛酸菜牛肉面
        BarcodeCompanion.insert(unitProductId: 7, barcodeValue: '6901234567896'), // 清风抽纸
        BarcodeCompanion.insert(unitProductId: 8, barcodeValue: '6901234567897'), // 高露洁牙膏
        BarcodeCompanion.insert(unitProductId: 9, barcodeValue: '6901234567898'), // 娃哈哈AD钙奶
        BarcodeCompanion.insert(unitProductId: 10, barcodeValue: '6901234567899'), // 达利园蛋黄派
      ];

      await _database.transaction(() async {
        for (final barcode in defaultBarcodes) {
          await _database.into(_database.barcode).insert(barcode);
        }
      });

      print('✅ 成功初始化 ${defaultBarcodes.length} 个默认条码');
    } catch (e) {
      print('❌ 初始化默认条码失败: $e');
      rethrow;
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
      rethrow;
    }
  }

  /// 重置所有数据（仅用于开发/测试）
  Future<void> resetAllData() async {
    await _database.transaction(() async {
      // 删除销售相关的表数据
      await _database.delete(_database.salesTransactionItem).go();
      await _database.delete(_database.salesTransaction).go();
      await _database.delete(_database.customers).go();

      // 删除业务数据表
      await _database.delete(_database.inboundItem).go();
      await _database.delete(_database.inboundReceipt).go();
      await _database.delete(_database.purchaseOrderItem).go();
      await _database.delete(_database.purchaseOrder).go();
      await _database.delete(_database.inventoryTransaction).go();
      await _database.delete(_database.stock).go();
      await _database.delete(_database.productBatch).go();
      await _database.delete(_database.supplier).go();

      // 删除基础数据表
      await _database.delete(_database.barcode).go();
      await _database.delete(_database.unitProduct).go();
      await _database.delete(_database.product).go();
      await _database.delete(_database.shop).go();
      await _database.delete(_database.category).go();
      await _database.delete(_database.unit).go();
    });

    await initializeAllDefaults();
    print('🔄 数据库已重置并重新初始化');
  }
}
