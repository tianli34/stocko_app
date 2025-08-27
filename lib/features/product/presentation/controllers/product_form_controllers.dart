import 'package:flutter/material.dart';

import '../../domain/model/product.dart';

/// 负责管理 Product 表单的 TextEditingController 与 FocusNode。
/// 将初始化/回填与资源释放从页面中抽离，页面只做 UI 组装与事件转发。
class ProductFormControllers {
  // 文本控制器
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  late final TextEditingController nameController;
  late final TextEditingController barcodeController;
  late final TextEditingController retailPriceController;
  late final TextEditingController promotionalPriceController;
  late final TextEditingController suggestedRetailPriceController;
  late final TextEditingController stockWarningValueController;
  late final TextEditingController shelfLifeController;
  late final TextEditingController remarksController;

  // 焦点节点
  final FocusNode nameFocusNode = FocusNode();
  final FocusNode unitFocusNode = FocusNode();
  final FocusNode categoryFocusNode = FocusNode();
  final FocusNode retailPriceFocusNode = FocusNode();
  final FocusNode shelfLifeFocusNode = FocusNode();
  final FocusNode stockWarningValueFocusNode = FocusNode();

  /// 根据传入的 [product] 初始化各输入框，空值使用页面默认值保持一致。
  void init(ProductModel? product) {
    nameController = TextEditingController(text: product?.name ?? '');
    barcodeController = TextEditingController(text: ''); // 条码异步加载

    retailPriceController = TextEditingController(
      text: product?.retailPrice != null
          ? product!.retailPrice!.yuan.toStringAsFixed(2)
          : '',
    );

    promotionalPriceController = TextEditingController(
      text: product?.promotionalPrice != null
          ? product!.promotionalPrice!.yuan.toStringAsFixed(2)
          : '',
    );

    suggestedRetailPriceController = TextEditingController(
      text: product?.suggestedRetailPrice != null
          ? product!.suggestedRetailPrice!.yuan.toStringAsFixed(2)
          : '',
    );

    stockWarningValueController = TextEditingController(
      text: product?.stockWarningValue?.toString() ?? '',
    );

    shelfLifeController = TextEditingController(
      text: product?.shelfLife?.toString() ?? '',
    );

    remarksController = TextEditingController(text: product?.remarks ?? '');

    // categoryController 与 unitController 初始文本由页面选择逻辑/回填决定
  }

  void dispose() {
    // 文本控制器
    nameController.dispose();
    barcodeController.dispose();
    retailPriceController.dispose();
    promotionalPriceController.dispose();
    suggestedRetailPriceController.dispose();
    stockWarningValueController.dispose();
    shelfLifeController.dispose();
    remarksController.dispose();
    categoryController.dispose();
    unitController.dispose();

    // 焦点节点
    nameFocusNode.dispose();
    unitFocusNode.dispose();
    categoryFocusNode.dispose();
    retailPriceFocusNode.dispose();
    shelfLifeFocusNode.dispose();
    stockWarningValueFocusNode.dispose();
  }
}
