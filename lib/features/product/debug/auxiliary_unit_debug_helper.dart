// 辅单位调试助手
// 用于排查辅单位没有写入产品单位关联表的问题

import 'package:flutter/foundation.dart';
import '../domain/model/product_unit.dart';

class AuxiliaryUnitDebugHelper {
  static const String _tag = '🔍 [辅单位调试]';

  /// 调试辅单位数据构建过程
  static void debugProductUnitsBuild({
    required String? productId,
    required String? baseUnitId,
    required String? baseUnitName,
    required List<dynamic> auxiliaryUnits,
    required List<ProductUnit> result,
  }) {
    if (!kDebugMode) return;

    print('$_tag ==================== 开始调试产品单位构建 ====================');
    print('$_tag 产品ID: $productId');
    print('$_tag 基本单位ID: $baseUnitId');
    print('$_tag 基本单位名称: $baseUnitName');
    print('$_tag 辅单位数量: ${auxiliaryUnits.length}');

    // 调试每个辅单位
    for (int i = 0; i < auxiliaryUnits.length; i++) {
      final aux = auxiliaryUnits[i];
      print('$_tag --- 辅单位 ${i + 1} ---');

      // 使用反射或动态访问来获取属性
      try {
        final unit = aux.unit;
        final conversionRate = aux.conversionRate;
        final unitController = aux.unitController;
        final barcodeController = aux.barcodeController;
        final retailPriceController = aux.retailPriceController;

        print('$_tag   单位对象: ${unit?.toString()}');
        print('$_tag   单位ID: ${unit?.id}');
        print('$_tag   单位名称: ${unit?.name}');
        print('$_tag   换算率: $conversionRate');
        print('$_tag   单位输入框文本: ${unitController?.text}');
        print('$_tag   条码输入框文本: ${barcodeController?.text}');
        print('$_tag   零售价输入框文本: ${retailPriceController?.text}');

        // 检查数据有效性
        if (unit == null) {
          print('$_tag   ❌ 警告: 单位对象为null');
        }
        if (conversionRate <= 0) {
          print('$_tag   ❌ 警告: 换算率无效 ($conversionRate)');
        }
        if (unit?.id == null || unit!.id.isEmpty) {
          print('$_tag   ❌ 警告: 单位ID为空');
        }
      } catch (e) {
        print('$_tag   ❌ 错误: 无法访问辅单位属性 - $e');
      }
    }

    // 调试构建结果
    print('$_tag --- 构建结果 ---');
    print('$_tag 构建的产品单位数量: ${result.length}');

    for (int i = 0; i < result.length; i++) {
      final productUnit = result[i];
      print('$_tag 产品单位 ${i + 1}:');
      print('$_tag   产品单位ID: ${productUnit.productUnitId}');
      print('$_tag   产品ID: ${productUnit.productId}');
      print('$_tag   单位ID: ${productUnit.unitId}');
      print('$_tag   换算率: ${productUnit.conversionRate}');
      print('$_tag   销售价格: ${productUnit.sellingPrice}');
      print('$_tag   最后更新: ${productUnit.lastUpdated}');

      // 标识基本单位和辅单位
      if (productUnit.conversionRate == 1.0) {
        print('$_tag   类型: 基本单位');
      } else {
        print('$_tag   类型: 辅单位');
      }
    }

    print('$_tag ==================== 产品单位构建调试结束 ====================');
  }

  /// 调试产品单位保存过程
  static void debugProductUnitsSave({
    required String productId,
    required List<ProductUnit>? inputUnits,
    required List<ProductUnit> finalUnits,
  }) {
    if (!kDebugMode) return;

    print('$_tag ==================== 开始调试产品单位保存 ====================');
    print('$_tag 产品ID: $productId');
    print('$_tag 输入单位数量: ${inputUnits?.length ?? 0}');
    print('$_tag 最终保存单位数量: ${finalUnits.length}');

    if (inputUnits != null) {
      print('$_tag --- 输入的单位 ---');
      for (int i = 0; i < inputUnits.length; i++) {
        final unit = inputUnits[i];
        print(
          '$_tag 输入单位 ${i + 1}: ${unit.productUnitId} (换算率: ${unit.conversionRate})',
        );
      }
    }

    print('$_tag --- 最终保存的单位 ---');
    for (int i = 0; i < finalUnits.length; i++) {
      final unit = finalUnits[i];
      print(
        '$_tag 保存单位 ${i + 1}: ${unit.productUnitId} (换算率: ${unit.conversionRate})',
      );
    }

    print('$_tag ==================== 产品单位保存调试结束 ====================');
  }

  /// 验证产品单位数据完整性
  static List<String> validateProductUnits(List<ProductUnit> productUnits) {
    final List<String> issues = [];

    if (productUnits.isEmpty) {
      issues.add('产品单位列表为空');
      return issues;
    }

    // 检查是否有基本单位
    final baseUnits = productUnits
        .where((pu) => pu.conversionRate == 1.0)
        .toList();
    if (baseUnits.isEmpty) {
      issues.add('缺少基本单位（换算率为1.0的单位）');
    } else if (baseUnits.length > 1) {
      issues.add('存在多个基本单位');
    }

    // 检查产品单位ID的唯一性
    final ids = productUnits.map((pu) => pu.productUnitId).toList();
    final uniqueIds = ids.toSet();
    if (ids.length != uniqueIds.length) {
      issues.add('存在重复的产品单位ID');
    }

    // 检查每个产品单位的数据完整性
    for (int i = 0; i < productUnits.length; i++) {
      final pu = productUnits[i];
      final prefix = '产品单位${i + 1}';

      if (pu.productUnitId.isEmpty) {
        issues.add('$prefix: 产品单位ID为空');
      }
      if (pu.productId.isEmpty) {
        issues.add('$prefix: 产品ID为空');
      }
      if (pu.unitId.isEmpty) {
        issues.add('$prefix: 单位ID为空');
      }
      if (pu.conversionRate <= 0) {
        issues.add('$prefix: 换算率无效 (${pu.conversionRate})');
      }
    }

    return issues;
  }

  /// 打印验证结果
  static void printValidationResult(List<ProductUnit> productUnits) {
    if (!kDebugMode) return;

    final issues = validateProductUnits(productUnits);

    print('$_tag ==================== 产品单位数据验证 ====================');
    if (issues.isEmpty) {
      print('$_tag ✅ 数据验证通过，没有发现问题');
    } else {
      print('$_tag ❌ 发现 ${issues.length} 个问题:');
      for (int i = 0; i < issues.length; i++) {
        print('$_tag   ${i + 1}. ${issues[i]}');
      }
    }
    print('$_tag ==================== 数据验证结束 ====================');
  }
}
