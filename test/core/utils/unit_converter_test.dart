import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/product/domain/model/unit.dart';
import 'package:stocko_app/features/product/domain/model/product_unit.dart';
import 'package:stocko_app/core/utils/unit_converter.dart';

void main() {
  group('UnitConverter', () {
    // 测试用例数据
    late Unit baseUnit;
    late Unit packUnit;
    late Unit bottleUnit;
    late List<UnitProduct> allUnits;

    setUp(() {
      baseUnit = Unit(id: 1, name: '瓶');
      packUnit = Unit(id: 2, name: '箱');
      bottleUnit = Unit(id: 3, name: '瓶');

      allUnits = [
        UnitProduct(productId: 1, unitId: 1, conversionRate: 1), // 瓶 (基础)
        UnitProduct(productId: 1, unitId: 2, conversionRate: 12), // 12瓶/箱
      ];
    });

    group('convertToBaseUnit', () {
      test('正确转换单位到基础单位', () {
        // 1箱 = 12瓶
        final result = UnitConverter.convertToBaseUnit(1, packUnit, allUnits);
        expect(result, equals(12));
      });

      test('相同单位转换返回原数量', () {
        // 5瓶 = 5瓶
        final result = UnitConverter.convertToBaseUnit(5, baseUnit, allUnits);
        expect(result, equals(5));
      });

      test('找不到单位配置时抛出异常', () {
        final unknownUnit = Unit(id: 999, name: '未知');
        expect(
          () => UnitConverter.convertToBaseUnit(1, unknownUnit, allUnits),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('处理不同的换算率', () {
        final tenUnit = Unit(id: 10, name: '十瓶');
        final unitsWithTen = [
          ...allUnits,
          UnitProduct(productId: 1, unitId: 10, conversionRate: 10),
        ];

        final result = UnitConverter.convertToBaseUnit(2, tenUnit, unitsWithTen);
        expect(result, equals(20)); // 2 * 10 = 20
      });
    });

    group('getStockInUnit', () {
      test('正确获取指定单位的库存数量', () {
        final result = UnitConverter.getStockInUnit(24, packUnit, allUnits);
        expect(result, equals(2)); // 24瓶 = 2箱
      });

      test('找不到单位配置时抛出异常', () {
        final unknownUnit = Unit(id: 999, name: '未知');
        expect(
          () => UnitConverter.getStockInUnit(10, unknownUnit, allUnits),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('基础单位返回原数量', () {
        final result = UnitConverter.getStockInUnit(10, baseUnit, allUnits);
        expect(result, equals(10));
      });
    });

    group('validateUnitConfiguration', () {
      test('有效配置返回成功结果', () {
        final (isValid, errorMessage) = UnitConverter.validateUnitConfiguration(allUnits);
        expect(isValid, isTrue);
        expect(errorMessage, isNull);
      });

      test('空配置列表返回错误', () {
        final (isValid, errorMessage) = UnitConverter.validateUnitConfiguration([]);
        expect(isValid, isFalse);
        expect(errorMessage, contains('至少需要配置一个单位'));
      });

      test('缺少基础单位返回错误', () {
        final unitsWithoutBase = [
          UnitProduct(productId: 1, unitId: 2, conversionRate: 12),
        ];
        final (isValid, errorMessage) = UnitConverter.validateUnitConfiguration(unitsWithoutBase);
        expect(isValid, isFalse);
        expect(errorMessage, contains('必须有一个基础单位'));
      });

      test('多个基础单位返回错误', () {
        final unitsWithMultipleBases = [
          UnitProduct(productId: 1, unitId: 1, conversionRate: 1),
          UnitProduct(productId: 1, unitId: 2, conversionRate: 1), // 另一个基础单位
        ];
        final (isValid, errorMessage) = UnitConverter.validateUnitConfiguration(unitsWithMultipleBases);
        expect(isValid, isFalse);
        expect(errorMessage, contains('只能有一个基础单位'));
      });

      test('换算率为零返回错误', () {
        final unitsWithZeroRate = [
          UnitProduct(productId: 1, unitId: 1, conversionRate: 0),
        ];
        final (isValid, errorMessage) = UnitConverter.validateUnitConfiguration(unitsWithZeroRate);
        expect(isValid, isFalse);
        expect(errorMessage, contains('换算率必须大于0'));
      });

      test('负换算率返回错误', () {
        final unitsWithNegativeRate = [
          UnitProduct(productId: 1, unitId: 1, conversionRate: -1),
        ];
        final (isValid, errorMessage) = UnitConverter.validateUnitConfiguration(unitsWithNegativeRate);
        expect(isValid, isFalse);
        expect(errorMessage, contains('换算率必须大于0'));
      });
    });

    group('findBaseUnit', () {
      test('成功查找基础单位', () {
        final baseUnitFound = UnitConverter.findBaseUnit(allUnits);
        expect(baseUnitFound.conversionRate, equals(1));
        expect(baseUnitFound.unitId, equals(1));
      });

      test('多个基础单位抛出异常', () {
        final unitsWithMultipleBases = [
          UnitProduct(productId: 1, unitId: 1, conversionRate: 1),
          UnitProduct(productId: 1, unitId: 2, conversionRate: 1),
        ];
        expect(
          () => UnitConverter.findBaseUnit(unitsWithMultipleBases),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('没有基础单位抛出异常', () {
        final unitsWithoutBase = [
          UnitProduct(productId: 1, unitId: 2, conversionRate: 2),
        ];
        expect(
          () => UnitConverter.findBaseUnit(unitsWithoutBase),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('compareUnits', () {
      test('比较不同大小的单位', () {
        final result = UnitConverter.compareUnits(packUnit, baseUnit, allUnits);
        expect(result, greaterThan(0)); // 箱 > 瓶
      });

      test('基础单位和非基础单位比较', () {
        final result = UnitConverter.compareUnits(baseUnit, packUnit, allUnits);
        expect(result, lessThan(0)); // 瓶 < 箱
      });

      test('找不到单位配置时抛出异常', () {
        final unknownUnit = Unit(id: 999, name: '未知');
        expect(
          () => UnitConverter.compareUnits(unknownUnit, baseUnit, allUnits),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('相同单位返回零', () {
        final sameUnit = Unit(id: 1, name: '瓶');
        final result = UnitConverter.compareUnits(sameUnit, baseUnit, allUnits);
        expect(result, equals(0));
      });
    });
  });
}