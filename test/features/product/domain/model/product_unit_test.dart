import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/product/domain/model/product_unit.dart';
import 'package:stocko_app/features/product/domain/model/unit.dart';

void main() {
  group('UnitProduct', () {
    late UnitProduct productUnit;

    setUp(() {
      productUnit = UnitProduct(
        id: 1,
        productId: 100,
        unitId: 1,
        conversionRate: 12,
        sellingPriceInCents: 15000, // 150元
        wholesalePriceInCents: 12000, // 120元
      );
    });

    group('displaySellingPrice getter', () {
      test('正确转换售价从分到元', () {
        expect(productUnit.displaySellingPrice, equals(150.0));
      });

      test('处理空价格', () {
        final unitWithoutPrice = UnitProduct(
          productId: 100,
          unitId: 1,
          conversionRate: 12,
        );
        expect(unitWithoutPrice.displaySellingPrice, equals(0.0));
      });
    });

    group('displayWholesalePrice getter', () {
      test('正确转换批发价从分到元', () {
        expect(productUnit.displayWholesalePrice, equals(120.0));
      });

      test('处理空价格', () {
        final unitWithoutPrice = UnitProduct(
          productId: 100,
          unitId: 1,
          conversionRate: 12,
        );
        expect(unitWithoutPrice.displayWholesalePrice, equals(0.0));
      });
    });

    group('calculateBaseQuantity', () {
      test('正确计算基础单位数量', () {
        final result = productUnit.calculateBaseQuantity(2);
        expect(result, equals(24)); // 2 * 12 = 24
      });

      test('处理零数量', () {
        final result = productUnit.calculateBaseQuantity(0);
        expect(result, equals(0));
      });

      test('处理大数量', () {
        final result = productUnit.calculateBaseQuantity(100);
        expect(result, equals(1200));
      });
    });

    group('calculateUnitQuantity', () {
      test('正确计算单位数量（向下取整）', () {
        final result = productUnit.calculateUnitQuantity(25);
        expect(result, equals(2)); // 25 ~/ 12 = 2
      });

      test('处理精确整除', () {
        final result = productUnit.calculateUnitQuantity(24);
        expect(result, equals(2)); // 24 ~/ 12 = 2
      });

      test('处理零数量', () {
        final result = productUnit.calculateUnitQuantity(0);
        expect(result, equals(0));
      });

      test('处理小于换算率的数量', () {
        final result = productUnit.calculateUnitQuantity(5);
        expect(result, equals(0)); // 5 ~/ 12 = 0
      });
    });

    group('updateTimestamp', () {
      test('更新时间戳并返回新实例', () {
        final oldTimestamp = productUnit.lastUpdated;
        final updatedUnit = productUnit.updateTimestamp();

        // 验证时间戳已更新
        expect(updatedUnit.lastUpdated, isNotNull);
        expect(updatedUnit.lastUpdated != oldTimestamp, isTrue);

        // 验证其他字段保持不变
        expect(updatedUnit.id, equals(productUnit.id));
        expect(updatedUnit.productId, equals(productUnit.productId));
        expect(updatedUnit.unitId, equals(productUnit.unitId));
        expect(updatedUnit.conversionRate, equals(productUnit.conversionRate));
        expect(updatedUnit.sellingPriceInCents, equals(productUnit.sellingPriceInCents));
        expect(updatedUnit.wholesalePriceInCents, equals(productUnit.wholesalePriceInCents));
      });

      test('原始对象未被修改', () {
        final originalTimestamp = productUnit.lastUpdated;
        final updatedUnit = productUnit.updateTimestamp();

        // 原始对象的 lastUpdated 仍为null或旧值
        expect(productUnit.lastUpdated, equals(originalTimestamp));
      });
    });

    group('Factory constructors and validation', () {
      test('创建含所有字段的对象', () {
        final fullUnit = UnitProduct(
          id: 5,
          productId: 200,
          unitId: 2,
          conversionRate: 6,
          sellingPriceInCents: 8000,
          wholesalePriceInCents: 6000,
          lastUpdated: DateTime(2023, 1, 1),
        );

        expect(fullUnit.id, equals(5));
        expect(fullUnit.productId, equals(200));
        expect(fullUnit.unitId, equals(2));
        expect(fullUnit.conversionRate, equals(6));
        expect(fullUnit.sellingPriceInCents, equals(8000));
        expect(fullUnit.wholesalePriceInCents, equals(6000));
        expect(fullUnit.lastUpdated, equals(DateTime(2023, 1, 1)));
      });

      test('创建最小必要字段的对象', () {
        final minimalUnit = UnitProduct(
          productId: 300,
          unitId: 3,
          conversionRate: 1,
        );

        expect(minimalUnit.id, isNull);
        expect(minimalUnit.productId, equals(300));
        expect(minimalUnit.unitId, equals(3));
        expect(minimalUnit.conversionRate, equals(1));
        expect(minimalUnit.sellingPriceInCents, isNull);
        expect(minimalUnit.wholesalePriceInCents, isNull);
        expect(minimalUnit.lastUpdated, isNull);
      });

      test('copyWith 方法正常工作', () {
        final copied = productUnit.copyWith(conversionRate: 24, sellingPriceInCents: 16000);
        expect(copied.conversionRate, equals(24));
        expect(copied.sellingPriceInCents, equals(16000));
        // 其他字段保持不变
        expect(copied.productId, equals(productUnit.productId));
        expect(copied.unitId, equals(productUnit.unitId));
      });
    });

    group('JSON serialization', () {
      test('fromJson 创建对象的正确性', () {
        final json = {
          'id': 2,
          'productId': 50,
          'unitId': 5,
          'conversionRate': 10,
          'sellingPriceInCents': 5000,
          'wholesalePriceInCents': 4000,
          'lastUpdated': '2023-01-01T12:00:00.000Z',
        };

        final unit = UnitProduct.fromJson(json);
        expect(unit.id, equals(2));
        expect(unit.productId, equals(50));
        expect(unit.unitId, equals(5));
        expect(unit.conversionRate, equals(10));
        expect(unit.sellingPriceInCents, equals(5000));
        expect(unit.wholesalePriceInCents, equals(4000));
      });

      test('toJson 序列化的正确性', () {
        final unit = UnitProduct(
          id: 7,
          productId: 123,
          unitId: 4,
          conversionRate: 8,
          sellingPriceInCents: 3000,
          wholesalePriceInCents: 2500,
          lastUpdated: DateTime(2023, 6, 15, 10, 30, 0),
        );

        final json = unit.toJson();
        expect(json['id'], equals(7));
        expect(json['productId'], equals(123));
        expect(json['unitId'], equals(4));
        expect(json['conversionRate'], equals(8));
        expect(json['sellingPriceInCents'], equals(3000));
        expect(json['wholesalePriceInCents'], equals(2500));
        expect(json['lastUpdated'], isNotNull);
      });
    });

    group('Edge cases', () {
      test('处理极小换算率', () {
        final unitWithSmallRate = UnitProduct(
          productId: 100,
          unitId: 1,
          conversionRate: 1,
        );

        final result = unitWithSmallRate.calculateBaseQuantity(5);
        expect(result, equals(5));
      });

      test('处理特大数量', () {
        const largeQuantity = 1000000;
        final result = productUnit.calculateBaseQuantity(largeQuantity);
        expect(result, equals(largeQuantity * 12));
      });

      test('处理边界值', () {
        final boundaryUnit = UnitProduct(
          productId: 100,
          unitId: 1,
          conversionRate: 2,
        );

        expect(boundaryUnit.calculateUnitQuantity(1), equals(0)); // 1 ~/ 2 = 0
        expect(boundaryUnit.calculateUnitQuantity(2), equals(1)); // 2 ~/ 2 = 1
        expect(boundaryUnit.calculateUnitQuantity(3), equals(1)); // 3 ~/ 2 = 1
        expect(boundaryUnit.calculateUnitQuantity(4), equals(2)); // 4 ~/ 2 = 2
      });
    });
  });
}