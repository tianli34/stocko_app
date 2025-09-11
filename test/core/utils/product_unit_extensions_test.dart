import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/product/domain/model/product_unit.dart';
import 'package:stocko_app/core/utils/product_unit_extensions.dart';

void main() {
  group('ProductUnitExtensions', () {
    final base = UnitProduct(productId: 1, unitId: 1, conversionRate: 1);
    final box = UnitProduct(productId: 1, unitId: 2, conversionRate: 12);
  // final pack = UnitProduct(productId: 1, unitId: 3, conversionRate: 6);

    test('isBaseUnit / isLargerUnit / isSmallerUnit 与 sizeRelativeToBase', () {
      expect(base.isBaseUnit, isTrue);
      expect(base.isLargerUnit, isFalse);
      expect(base.isSmallerUnit, isFalse);
      expect(base.sizeRelativeToBase, '基础单位');

      expect(box.isBaseUnit, isFalse);
      expect(box.isLargerUnit, isTrue);
      expect(box.isSmallerUnit, isFalse);
      expect(box.sizeRelativeToBase, '大单位');
    });
  });

  group('ProductUnitListExtensions', () {
    final units = [
      UnitProduct(productId: 1, unitId: 1, conversionRate: 1),
      UnitProduct(productId: 1, unitId: 2, conversionRate: 12),
      UnitProduct(productId: 1, unitId: 3, conversionRate: 6),
    ];

    test('sortedByConversionRateDesc/Asc 排序正确', () {
      final desc = units.sortedByConversionRateDesc;
      expect(desc.map((e) => e.unitId), [2, 3, 1]);

      final asc = units.sortedByConversionRateAsc;
      expect(asc.map((e) => e.unitId), [1, 3, 2]);
    });

    test('baseUnit/largestUnit/smallestUnit 查找正确', () {
      expect(units.baseUnit?.unitId, 1);
      expect(units.largestUnit?.unitId, 2);
      expect(units.smallestUnit?.unitId, 1);
    });

    test('findByUnitId 查找到正确对象', () {
      expect(units.findByUnitId(3)?.conversionRate, 6);
      expect(units.findByUnitId(99), isNull);
    });

    test('isValidConfiguration 和 configurationError', () {
      expect(units.isValidConfiguration, isTrue);
      expect(units.configurationError, isNull);

      final noBase = [
        UnitProduct(productId: 1, unitId: 2, conversionRate: 12),
        UnitProduct(productId: 1, unitId: 3, conversionRate: 6),
      ];
      expect(noBase.isValidConfiguration, isFalse);
      expect(noBase.configurationError, '必须有一个基础单位（换算率为1）');

      final twoBase = [
        UnitProduct(productId: 1, unitId: 1, conversionRate: 1),
        UnitProduct(productId: 1, unitId: 2, conversionRate: 1),
      ];
      expect(twoBase.isValidConfiguration, isFalse);
      expect(twoBase.configurationError, '只能有一个基础单位（换算率为1）');

      final invalidRate = [
        UnitProduct(productId: 1, unitId: 1, conversionRate: 0),
      ];
      expect(invalidRate.isValidConfiguration, isFalse);
      expect(invalidRate.configurationError, '换算率必须大于0');

      expect(<UnitProduct>[].isValidConfiguration, isFalse);
      expect(<UnitProduct>[].configurationError, '至少需要配置一个单位');
    });
  });
}
