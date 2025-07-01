import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/product/domain/model/product_unit.dart';
import 'package:stocko_app/features/product/data/repository/product_unit_repository.dart';

void main() {
  group('辅单位写入产品单位关联表测试', () {
    late AppDatabase database;
    late ProductUnitRepository repository;

    setUp(() async {
      // 创建内存数据库用于测试
      database = AppDatabase(NativeDatabase.memory());
      repository = ProductUnitRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('验证辅单位是否正确写入产品单位关联表', () async {
      // 准备测试数据
      const productId = 'test_product_001';
      final productUnits = [
        // 基础单位
        ProductUnit(
          productUnitId: '${productId}_base_unit',
          productId: productId,
          unitId: 'unit_piece',
          conversionRate: 1.0,
          sellingPrice: 10.0,
        ),
        // 辅单位1：箱
        ProductUnit(
          productUnitId: '${productId}_aux_box',
          productId: productId,
          unitId: 'unit_box',
          conversionRate: 12.0,
          sellingPrice: 120.0,
        ),
        // 辅单位2：包
        ProductUnit(
          productUnitId: '${productId}_aux_pack',
          productId: productId,
          unitId: 'unit_pack',
          conversionRate: 6.0,
          sellingPrice: 60.0,
        ),
      ];

      // 执行：写入辅单位数据
      await repository.replaceProductUnits(productId, productUnits);

      // 验证：检查数据是否正确写入
      final savedUnits = await repository.getProductUnitsByProductId(productId);

      // 断言：验证写入结果
      expect(savedUnits.length, equals(3), reason: '应该写入3个单位配置');

      // 验证基础单位
      final baseUnit = savedUnits.firstWhere((u) => u.conversionRate == 1.0);
      expect(baseUnit.unitId, equals('unit_piece'));
      expect(baseUnit.sellingPrice, equals(10.0));

      // 验证辅单位1
      final auxUnit1 = savedUnits.firstWhere((u) => u.unitId == 'unit_box');
      expect(auxUnit1.conversionRate, equals(12.0));
      expect(auxUnit1.sellingPrice, equals(120.0));

      // 验证辅单位2
      final auxUnit2 = savedUnits.firstWhere((u) => u.unitId == 'unit_pack');
      expect(auxUnit2.conversionRate, equals(6.0));
      expect(auxUnit2.sellingPrice, equals(60.0));

      print('✅ 辅单位写入验证通过');
      print('📊 写入单位数量: ${savedUnits.length}');
      for (final unit in savedUnits) {
        print(
          '   - 单位ID: ${unit.unitId}, 换算率: ${unit.conversionRate}, 售价: ${unit.sellingPrice}',
        );
      }
    });

    test('验证数据库表结构和约束', () async {
      const productId = 'test_product_002';

      // 测试唯一约束：同一产品的同一单位只能有一个记录
      final duplicateUnits = [
        ProductUnit(
          productUnitId: '${productId}_unit1',
          productId: productId,
          unitId: 'unit_piece',
          conversionRate: 1.0,
        ),
        ProductUnit(
          productUnitId: '${productId}_unit2',
          productId: productId,
          unitId: 'unit_piece', // 重复的单位ID
          conversionRate: 2.0,
        ),
      ];

      // 应该抛出约束违反异常
      expect(
        () => repository.replaceProductUnits(productId, duplicateUnits),
        throwsA(isA<SqliteException>()),
        reason: '重复的产品-单位组合应该违反唯一约束',
      );
    });

    test('验证辅单位数据完整性', () async {
      const productId = 'test_product_003';
      final testUnit = ProductUnit(
        productUnitId: '${productId}_test',
        productId: productId,
        unitId: 'unit_test',
        conversionRate: 5.0,
        sellingPrice: 25.5,
        lastUpdated: DateTime.now(),
      );

      await repository.addProductUnit(testUnit);
      final retrieved = await repository.getProductUnitById(
        testUnit.productUnitId,
      );

      expect(retrieved, isNotNull);
      expect(retrieved!.productId, equals(productId));
      expect(retrieved.unitId, equals('unit_test'));
      expect(retrieved.conversionRate, equals(5.0));
      expect(retrieved.sellingPrice, equals(25.5));
      expect(retrieved.lastUpdated, isNotNull);

      print('✅ 辅单位数据完整性验证通过');
    });
  });
}
