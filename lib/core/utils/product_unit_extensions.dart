import '../../../features/product/domain/model/product_unit.dart';

/// UnitProduct 的扩展方法
extension ProductUnitExtensions on UnitProduct {
  /// 判断是否为基础单位
  bool get isBaseUnit => conversionRate == 1.0;

  /// 判断是否为大单位（换算率大于1）
  bool get isLargerUnit => conversionRate > 1.0;

  /// 判断是否为小单位（换算率小于1）
  bool get isSmallerUnit => conversionRate < 1.0;

  /// 获取相对于基础单位的大小关系描述
  String get sizeRelativeToBase {
    if (isBaseUnit) return '基础单位';
    if (isLargerUnit) return '大单位';
    return '小单位';
  }
}

/// List<UnitProduct> 的扩展方法
extension ProductUnitListExtensions on List<UnitProduct> {
  /// 按换算率从大到小排序
  List<UnitProduct> get sortedByConversionRateDesc {
    final sorted = List<UnitProduct>.from(this);
    sorted.sort((a, b) => b.conversionRate.compareTo(a.conversionRate));
    return sorted;
  }

  /// 按换算率从小到大排序
  List<UnitProduct> get sortedByConversionRateAsc {
    final sorted = List<UnitProduct>.from(this);
    sorted.sort((a, b) => a.conversionRate.compareTo(b.conversionRate));
    return sorted;
  }

  /// 查找基础单位
  UnitProduct? get baseUnit {
    try {
      return firstWhere((unit) => unit.isBaseUnit);
    } catch (e) {
      return null;
    }
  }

  /// 查找最大单位（换算率最大）
  UnitProduct? get largestUnit {
    if (isEmpty) return null;
    return reduce((a, b) => a.conversionRate > b.conversionRate ? a : b);
  }

  /// 查找最小单位（换算率最小）
  UnitProduct? get smallestUnit {
    if (isEmpty) return null;
    return reduce((a, b) => a.conversionRate < b.conversionRate ? a : b);
  }

  /// 根据单位ID查找ProductUnit
  UnitProduct? findByUnitId(int unitId) {
    try {
      return firstWhere((pu) => pu.unitId == unitId);
    } catch (e) {
      return null;
    }
  }

  /// 验证单位配置是否有效
  bool get isValidConfiguration {
    if (isEmpty) return false;

    // 必须有且只有一个基础单位
    final baseUnits = where((unit) => unit.isBaseUnit).toList();
    if (baseUnits.length != 1) return false;

    // 所有换算率必须大于0
    return every((unit) => unit.conversionRate > 0);
  }

  /// 获取配置验证错误信息
  String? get configurationError {
    if (isEmpty) return '至少需要配置一个单位';

    final baseUnits = where((unit) => unit.isBaseUnit).toList();
    if (baseUnits.isEmpty) return '必须有一个基础单位（换算率为1）';
    if (baseUnits.length > 1) return '只能有一个基础单位（换算率为1）';

    final invalidRates = where((unit) => unit.conversionRate <= 0);
    if (invalidRates.isNotEmpty) return '换算率必须大于0';

    return null;
  }
}
