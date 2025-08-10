import '../../../features/product/domain/model/unit.dart';
import '../../../features/product/domain/model/product_unit.dart';

/// 单位换算工具类
///
/// 提供以下功能：
/// 1. 将任意单位的数量换算成基础单位数量
/// 2. 将基础单位的库存量格式化成用户友好的字符串
class UnitConverter {
  /// 将任意单位的数量换算成基础单位数量
  ///
  /// [quantity] 输入的数量
  /// [unit] 输入数量对应的单位
  /// [allUnits] 产品的所有单位配置列表
  ///
  /// 返回换算后的基础单位数量
  /// 如果找不到对应的单位配置，返回原数量
  static int convertToBaseUnit(
    int quantity,
    Unit unit,
    List<ProductUnit> allUnits,
  ) {
    // 查找对应的产品单位配置
    final productUnit = allUnits.firstWhere(
      (pu) => pu.unitId == unit.id,
      orElse: () => throw ArgumentError('找不到单位配置: ${unit.name}'),
    );

    // 使用换算率计算基础单位数量
    return productUnit.calculateBaseQuantity(quantity);
  }

  /// 将基础单位的库存量格式化成用户友好的字符串
  ///
  /// [stockInBaseUnit] 基础单位的库存数量
  /// [allUnits] 产品的所有单位配置列表，应按换算率从大到小排序
  /// [unitMap] 单位ID到单位对象的映射
  ///
  /// 返回格式化的字符串，如 "1 箱 5 瓶" 或 "15 瓶"
  static String formatStockForDisplay(
    int stockInBaseUnit,
    List<ProductUnit> allUnits,
    Map<String, Unit> unitMap,
  ) {
    if (stockInBaseUnit <= 0) {
      return '0';
    }

    // 按换算率从大到小排序（确保从大单位开始计算）
    final sortedUnits = List<ProductUnit>.from(allUnits)
      ..sort((a, b) => b.conversionRate.compareTo(a.conversionRate));

    final List<String> parts = [];
    int remainingStock = stockInBaseUnit;

    for (int i = 0; i < sortedUnits.length; i++) {
      final productUnit = sortedUnits[i];
      final unit = unitMap[productUnit.unitId];

      if (unit == null) continue;

      // 计算当前单位可以表示的数量
      final unitQuantity = productUnit.calculateUnitQuantity(remainingStock);

      // 如果是最后一个单位，直接使用剩余数量
      if (i == sortedUnits.length - 1) {
        if (unitQuantity > 0) {
          parts.add('${_formatNumber(unitQuantity)} ${unit.name}');
        }
        break;
      }

      // 对于非最后一个单位，取整数部分
      final wholeUnits = unitQuantity.floor();
      if (wholeUnits > 0) {
        parts.add('$wholeUnits ${unit.name}');
        // 计算剩余的基础单位数量
        remainingStock -= productUnit.calculateBaseQuantity(
          wholeUnits,
        );
      }
    }

    return parts.isEmpty ? '0' : parts.join(' ');
  }

  /// 获取指定单位的库存数量
  ///
  /// [stockInBaseUnit] 基础单位的库存数量
  /// [targetUnit] 目标单位
  /// [allUnits] 产品的所有单位配置列表
  ///
  /// 返回目标单位的库存数量
  static int getStockInUnit(
    int stockInBaseUnit,
    Unit targetUnit,
    List<ProductUnit> allUnits,
  ) {
    final productUnit = allUnits.firstWhere(
      (pu) => pu.unitId == targetUnit.id,
      orElse: () => throw ArgumentError('找不到单位配置: ${targetUnit.name}'),
    );

    return productUnit.calculateUnitQuantity(stockInBaseUnit);
  }

  /// 验证单位换算配置是否合理
  ///
  /// [allUnits] 产品的所有单位配置列表
  ///
  /// 返回验证结果和错误信息
  static (bool isValid, String? errorMessage) validateUnitConfiguration(
    List<ProductUnit> allUnits,
  ) {
    if (allUnits.isEmpty) {
      return (false, '至少需要配置一个单位');
    }

    // 检查是否有基础单位（换算率为1的单位）
    final baseUnits = allUnits.where((unit) => unit.conversionRate == 1.0);
    if (baseUnits.isEmpty) {
      return (false, '必须有一个基础单位（换算率为1）');
    }

    if (baseUnits.length > 1) {
      return (false, '只能有一个基础单位（换算率为1）');
    }

    // 检查换算率是否都大于0
    final invalidRates = allUnits.where((unit) => unit.conversionRate <= 0);
    if (invalidRates.isNotEmpty) {
      return (false, '换算率必须大于0');
    }

    return (true, null);
  }

  /// 格式化数字显示（去除不必要的小数点）
  static String _formatNumber(int number) {
    if (number == number.truncateToDouble()) {
      return number.truncate().toString();
    } else {
      return number.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    }
  }

  /// 查找基础单位
  ///
  /// [allUnits] 产品的所有单位配置列表
  ///
  /// 返回基础单位，如果找不到则抛出异常
  static ProductUnit findBaseUnit(List<ProductUnit> allUnits) {
    return allUnits.firstWhere(
      (unit) => unit.conversionRate == 1.0,
      orElse: () => throw ArgumentError('找不到基础单位'),
    );
  }

  /// 比较两个单位的大小关系
  ///
  /// [unit1] 第一个单位
  /// [unit2] 第二个单位
  /// [allUnits] 产品的所有单位配置列表
  ///
  /// 返回比较结果：
  /// - 正数：unit1 比 unit2 大
  /// - 负数：unit1 比 unit2 小
  /// - 0：unit1 和 unit2 相等
  static int compareUnits(Unit unit1, Unit unit2, List<ProductUnit> allUnits) {
    final productUnit1 = allUnits.firstWhere(
      (pu) => pu.unitId == unit1.id,
      orElse: () => throw ArgumentError('找不到单位配置: ${unit1.name}'),
    );

    final productUnit2 = allUnits.firstWhere(
      (pu) => pu.unitId == unit2.id,
      orElse: () => throw ArgumentError('找不到单位配置: ${unit2.name}'),
    );

    return productUnit1.conversionRate.compareTo(productUnit2.conversionRate);
  }
}
