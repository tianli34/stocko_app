import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/utils/unit_converter.dart';
import 'package:stocko_app/features/product/domain/model/unit.dart';
import 'package:stocko_app/features/product/domain/model/product_unit.dart';

void main() {
  final unitBase = Unit(id: 1, name: '瓶');
  final unitBox = Unit(id: 2, name: '箱');
  final units = [
    UnitProduct(productId: 1, unitId: 1, conversionRate: 1),
    UnitProduct(productId: 1, unitId: 2, conversionRate: 12),
  ];

  group('UnitConverter 额外边界用例', () {
    test('convertToBaseUnit 找不到单位配置抛出异常', () {
      expect(
        () => UnitConverter.convertToBaseUnit(1, Unit(id: 99, name: '未知'), units),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('formatStockForDisplay 为0或负数返回 0', () {
      final map = {1: unitBase, 2: unitBox}.map((key, value) => MapEntry(key.toString(), value));
      expect(UnitConverter.formatStockForDisplay(0, units, map), '0');
      expect(UnitConverter.formatStockForDisplay(-5, units, map), '0');
    });

    test('compareUnits 找不到配置抛出异常', () {
      expect(
        () => UnitConverter.compareUnits(unitBase, Unit(id: 99, name: '未知'), units),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('validateUnitConfiguration 多个基础单位或无基础单位', () {
      final none = [UnitProduct(productId: 1, unitId: 2, conversionRate: 12)];
      expect(UnitConverter.validateUnitConfiguration(none).$1, isFalse);

      final two = [
        UnitProduct(productId: 1, unitId: 1, conversionRate: 1),
        UnitProduct(productId: 1, unitId: 2, conversionRate: 1),
      ];
      expect(UnitConverter.validateUnitConfiguration(two).$1, isFalse);
    });
  });
}
