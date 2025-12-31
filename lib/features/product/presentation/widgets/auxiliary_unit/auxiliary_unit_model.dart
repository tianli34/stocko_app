import 'package:flutter/material.dart';

import '../../../domain/model/unit.dart';
import '../../../shared/utils/price_converter.dart';

/// 辅单位 UI 模型
/// 
/// 封装辅单位的数据和 UI 控制器
class AuxiliaryUnitModel {
  /// 唯一标识符
  final int id;
  
  /// 关联的单位
  Unit? unit;
  
  /// 换算率
  double conversionRate;

  /// 单位名称控制器
  late final TextEditingController unitController;
  
  /// 条码控制器
  late final TextEditingController barcodeController;
  
  /// 零售价控制器
  late final TextEditingController retailPriceController;
  
  /// 批发价控制器
  late final TextEditingController wholesalePriceController;

  /// 单位名称焦点
  final FocusNode unitFocusNode = FocusNode();
  
  /// 换算率焦点
  final FocusNode conversionRateFocusNode = FocusNode();
  
  /// 零售价焦点
  final FocusNode retailPriceFocusNode = FocusNode();
  
  /// 批发价焦点
  final FocusNode wholesalePriceFocusNode = FocusNode();

  AuxiliaryUnitModel({
    required this.id,
    this.unit,
    required num conversionRate,
    double? initialSellingPrice,
    double? initialWholesalePrice,
  }) : conversionRate = conversionRate.toDouble() {
    unitController = TextEditingController(text: unit?.name ?? '');
    barcodeController = TextEditingController();
    retailPriceController = TextEditingController(
      text: initialSellingPrice != null ? formatPrice(initialSellingPrice) : '',
    );
    wholesalePriceController = TextEditingController(
      text: initialWholesalePrice != null ? formatPrice(initialWholesalePrice) : '',
    );
  }

  /// 释放资源
  void dispose() {
    unitController.dispose();
    barcodeController.dispose();
    retailPriceController.dispose();
    wholesalePriceController.dispose();
    unitFocusNode.dispose();
    conversionRateFocusNode.dispose();
    retailPriceFocusNode.dispose();
    wholesalePriceFocusNode.dispose();
  }
}
