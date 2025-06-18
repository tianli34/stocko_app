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
          id: 'prod_rice',
          name: '大米',
          barcode: const Value('1234567890123'),
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
          id: 'prod_flour',
          name: '面粉',
          barcode: const Value('1234567890124'),
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
          id: 'prod_cola',
          name: '可乐',
          barcode: const Value('1234567890125'),
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
          id: 'prod_water',
          name: '矿泉水',
          barcode: const Value('1234567890126'),
          categoryId: const Value('cat_beverage'),
          unitId: const Value('unit_bottle'),
          retailPrice: const Value(1.0),
          suggestedRetailPrice: const Value(1.5),
          stockWarningValue: const Value(30),
          shelfLife: const Value(730),
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

  /// 重置所有数据（仅用于开发/测试）
  Future<void> resetAllData() async {
    await _database.transaction(() async {
      await _database.delete(_database.productsTable).go();
      await _database.delete(_database.shopsTable).go();
      await _database.delete(_database.categoriesTable).go();
      await _database.delete(_database.unitsTable).go();
      // 继续删除其他表的数据
    });

    await initializeAllDefaults();
    print('🔄 数据库已重置并重新初始化');
  }
}
