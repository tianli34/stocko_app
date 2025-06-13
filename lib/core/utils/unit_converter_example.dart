/// 单位换算工具类使用示例
///
/// 这个文件展示了如何使用 UnitConverter 类进行单位换算操作
library;

import 'utils.dart';
import '../../../features/product/domain/model/unit.dart';
import '../../../features/product/domain/model/product_unit.dart';

/// 使用示例类
class UnitConverterExample {
  /// 示例：饮料产品的单位换算
  ///
  /// 假设有一个饮料产品，配置了以下单位：
  /// - 瓶（基础单位）：换算率 1.0
  /// - 箱：换算率 24.0（1箱 = 24瓶）
  /// - 打：换算率 12.0（1打 = 12瓶）
  static void beverageExample() {
    // 创建单位
    final bottleUnit = Unit(id: 'bottle', name: '瓶');
    final caseUnit = Unit(id: 'case', name: '箱');
    final dozenUnit = Unit(id: 'dozen', name: '打');

    // 创建产品单位配置
    final productUnits = [
      ProductUnit(
        productUnitId: 'pu1',
        productId: 'product1',
        unitId: 'bottle',
        conversionRate: 1.0, // 基础单位
      ),
      ProductUnit(
        productUnitId: 'pu2',
        productId: 'product1',
        unitId: 'case',
        conversionRate: 24.0, // 1箱 = 24瓶
      ),
      ProductUnit(
        productUnitId: 'pu3',
        productId: 'product1',
        unitId: 'dozen',
        conversionRate: 12.0, // 1打 = 12瓶
      ),
    ];

    // 创建单位映射
    final unitMap = {
      'bottle': bottleUnit,
      'case': caseUnit,
      'dozen': dozenUnit,
    };

    // 示例1：将2箱换算成基础单位（瓶）
    final baseBeverageStock = UnitConverter.convertToBaseUnit(
      2.0, // 2箱
      caseUnit,
      productUnits,
    );
    print('2箱 = $baseBeverageStock 瓶'); // 输出：2箱 = 48.0 瓶

    // 示例2：将100瓶格式化显示
    final displayStock = UnitConverter.formatStockForDisplay(
      100.0, // 100瓶
      productUnits,
      unitMap,
    );
    print('100瓶格式化显示：$displayStock'); // 输出：4 箱 4 瓶

    // 示例3：获取箱单位的库存数量
    final stockInCases = UnitConverter.getStockInUnit(
      100.0, // 100瓶
      caseUnit,
      productUnits,
    );
    print('100瓶 = $stockInCases 箱'); // 输出：100瓶 = 4.166666666666667 箱
  }

  /// 示例：电子产品的单位换算
  ///
  /// 假设有一个电子产品，配置了以下单位：
  /// - 个（基础单位）：换算率 1.0
  /// - 盒：换算率 10.0（1盒 = 10个）
  /// - 件：换算率 100.0（1件 = 100个）
  static void electronicsExample() {
    // 创建单位
    final pieceUnit = Unit(id: 'piece', name: '个');
    final boxUnit = Unit(id: 'box', name: '盒');
    final packageUnit = Unit(id: 'package', name: '件');

    // 创建产品单位配置
    final productUnits = [
      ProductUnit(
        productUnitId: 'pu1',
        productId: 'product2',
        unitId: 'piece',
        conversionRate: 1.0, // 基础单位
      ),
      ProductUnit(
        productUnitId: 'pu2',
        productId: 'product2',
        unitId: 'box',
        conversionRate: 10.0, // 1盒 = 10个
      ),
      ProductUnit(
        productUnitId: 'pu3',
        productId: 'product2',
        unitId: 'package',
        conversionRate: 100.0, // 1件 = 100个
      ),
    ];

    // 创建单位映射
    final unitMap = {
      'piece': pieceUnit,
      'box': boxUnit,
      'package': packageUnit,
    };

    // 示例：将250个格式化显示
    final displayStock = UnitConverter.formatStockForDisplay(
      250.0, // 250个
      productUnits,
      unitMap,
    );
    print('250个格式化显示：$displayStock'); // 输出：2 件 5 盒

    // 验证配置
    final (isValid, errorMessage) = UnitConverter.validateUnitConfiguration(
      productUnits,
    );
    print('配置是否有效：$isValid'); // 输出：配置是否有效：true
    if (!isValid) {
      print('错误信息：$errorMessage');
    }
  }

  /// 示例：使用扩展方法
  static void extensionExample() {
    final productUnits = [
      ProductUnit(
        productUnitId: 'pu1',
        productId: 'product1',
        unitId: 'bottle',
        conversionRate: 1.0,
      ),
      ProductUnit(
        productUnitId: 'pu2',
        productId: 'product1',
        unitId: 'case',
        conversionRate: 24.0,
      ),
    ];

    // 使用扩展方法
    final baseUnit = productUnits.baseUnit;
    print('基础单位：${baseUnit?.unitId}'); // 输出：基础单位：bottle

    final isValid = productUnits.isValidConfiguration;
    print('配置是否有效：$isValid'); // 输出：配置是否有效：true

    final sorted = productUnits.sortedByConversionRateDesc;
    print(
      '按换算率降序排列：${sorted.map((u) => '${u.unitId}:${u.conversionRate}').join(', ')}',
    );
    // 输出：按换算率降序排列：case:24.0, bottle:1.0
  }

  /// 错误处理示例
  static void errorHandlingExample() {
    // 空配置
    final emptyUnits = <ProductUnit>[];
    final (isValid, errorMessage) = UnitConverter.validateUnitConfiguration(
      emptyUnits,
    );
    print('空配置验证：$isValid, 错误：$errorMessage');
    // 输出：空配置验证：false, 错误：至少需要配置一个单位

    // 没有基础单位的配置
    final noBaseUnits = [
      ProductUnit(
        productUnitId: 'pu1',
        productId: 'product1',
        unitId: 'case',
        conversionRate: 24.0,
      ),
    ];
    final (isValid2, errorMessage2) = UnitConverter.validateUnitConfiguration(
      noBaseUnits,
    );
    print('无基础单位配置验证：$isValid2, 错误：$errorMessage2');
    // 输出：无基础单位配置验证：false, 错误：必须有一个基础单位（换算率为1）
  }
}

/// 常见的单位换算场景
class CommonUnitScenarios {
  /// 重量相关单位
  static List<ProductUnit> weightUnits(String productId) => [
    ProductUnit(
      productUnitId: '${productId}_g',
      productId: productId,
      unitId: 'gram',
      conversionRate: 1.0, // 克（基础单位）
    ),
    ProductUnit(
      productUnitId: '${productId}_kg',
      productId: productId,
      unitId: 'kilogram',
      conversionRate: 1000.0, // 千克
    ),
    ProductUnit(
      productUnitId: '${productId}_ton',
      productId: productId,
      unitId: 'ton',
      conversionRate: 1000000.0, // 吨
    ),
  ];

  /// 长度相关单位
  static List<ProductUnit> lengthUnits(String productId) => [
    ProductUnit(
      productUnitId: '${productId}_mm',
      productId: productId,
      unitId: 'millimeter',
      conversionRate: 1.0, // 毫米（基础单位）
    ),
    ProductUnit(
      productUnitId: '${productId}_cm',
      productId: productId,
      unitId: 'centimeter',
      conversionRate: 10.0, // 厘米
    ),
    ProductUnit(
      productUnitId: '${productId}_m',
      productId: productId,
      unitId: 'meter',
      conversionRate: 1000.0, // 米
    ),
  ];

  /// 包装相关单位
  static List<ProductUnit> packagingUnits(String productId) => [
    ProductUnit(
      productUnitId: '${productId}_piece',
      productId: productId,
      unitId: 'piece',
      conversionRate: 1.0, // 个（基础单位）
    ),
    ProductUnit(
      productUnitId: '${productId}_box',
      productId: productId,
      unitId: 'box',
      conversionRate: 12.0, // 盒
    ),
    ProductUnit(
      productUnitId: '${productId}_case',
      productId: productId,
      unitId: 'case',
      conversionRate: 144.0, // 箱（12盒）
    ),
  ];
}
