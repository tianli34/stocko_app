import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/barcode_scanner_service.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../domain/model/category.dart';
import '../../domain/model/unit.dart';
import '../../domain/model/product_unit.dart';
import '../../application/provider/unit_providers.dart';
import '../../application/provider/unit_edit_form_providers.dart';
import '../navigation/product_form_coordinator.dart';
import '../state/product_form_ui_provider.dart';
import 'product_add_edit_controller.dart';

class ProductAddEditActions {
  final WidgetRef ref;
  final BuildContext context;
  final int? productId;

  ProductAddEditActions({
    required this.ref,
    required this.context,
    required this.productId,
  });

  /// 扫描条码并更新传入的 TextEditingController
  Future<void> scanBarcode(TextEditingController barcodeController, {
    FocusNode? nextFocus,
  }) async {
    try {
      final String? barcode = await BarcodeScannerService.scanForProduct(context);
      if (barcode != null && barcode.isNotEmpty) {
        barcodeController.text = barcode;
        ToastService.success('✅ 条码扫描成功: $barcode');
        nextFocus?.requestFocus();
      }
    } catch (e) {
      ToastService.error('❌ 扫码失败: $e');
    }
  }

  /// 选择类别
  Future<void> chooseCategory({
    required int? selectedCategoryId,
    required void Function(CategoryModel c) onPicked,
  }) async {
    final CategoryModel? selectedCategory = await ProductFormCoordinator.chooseCategory(
      context,
      ref,
      selectedCategoryId: selectedCategoryId,
    );
    if (selectedCategory != null) {
      onPicked(selectedCategory);
    }
  }

  /// 选择单位（从列表）
  Future<void> chooseUnit({
    required int? selectedUnitId,
    required void Function(Unit u) onPicked,
  }) async {
    final allUnits = ref.read(allUnitsProvider).value ?? [];
    final Unit? selectedUnit = await ProductFormCoordinator.chooseUnit(
      context,
      allUnits,
      selectedUnitId: selectedUnitId,
    );
    if (selectedUnit != null) {
      onPicked(selectedUnit);
    }
  }

  /// 编辑辅单位
  Future<void> editAuxUnits({
    required int? currentUnitId,
    required String currentUnitName,
  }) async {
    // ✅ 标记用户已进入辅单位编辑页面
    ref.read(productFormUiProvider.notifier).setHasEnteredAuxUnitPage(true);
    
    final dynamic result = await ProductFormCoordinator.editAuxiliaryUnits(
      context,
      ref,
      productId: productId,
      currentUnitId: currentUnitId,
      currentUnitName: currentUnitName,
    );

    if (result == null) return;

    List<UnitProduct>? productUnits;
    List<Map<String, String>>? auxiliaryBarcodes;

    if (result is Map<String, dynamic>) {
      productUnits = result['productUnits'] as List<UnitProduct>?;
      auxiliaryBarcodes = result['auxiliaryBarcodes'] as List<Map<String, String>>?;
    } else if (result is List<UnitProduct>) {
      productUnits = result;
    }

    if (productUnits != null && productUnits.isNotEmpty) {
      // 保存到 UI 状态
      ref.read(productFormUiProvider.notifier).setProductUnitsAndBarcodes(
            productUnits: productUnits,
            auxiliaryUnitBarcodes: auxiliaryBarcodes,
          );

      // 找到基础单位
      final List<UnitProduct> units = productUnits; // 非空断言后赋值
      final baseProductUnit = units.firstWhere(
        (unit) => unit.conversionRate == 1.0,
        orElse: () => units.first,
      );
      ref.read(productFormUiProvider.notifier).setUnitId(baseProductUnit.unitId);
    }
  }

  /// 提交表单
  Future<void> submitForm({
    required GlobalKey<FormState> formKey,
    required TextEditingController nameController,
    required TextEditingController categoryController,
    required TextEditingController unitController,
    required TextEditingController barcodeController,
    required TextEditingController retailPriceController,
    required TextEditingController promotionalPriceController,
    required TextEditingController suggestedRetailPriceController,
    required TextEditingController stockWarningValueController,
    required TextEditingController shelfLifeController,
    required void Function() onSuccess,
    required void Function(String message) onError,
  }) async {
    if (!formKey.currentState!.validate()) return;

    final ui = ref.read(productFormUiProvider);

    // 多变体模式验证
    if (ui.isMultiVariantMode && productId == null) {
      // 检查是否选择了商品组
      if (ui.selectedGroupId == null) {
        onError('❌ 多变体模式需要选择商品组');
        return;
      }
      // 检查是否有有效的变体
      final validVariants = ui.variants.where((v) => v.variantName.trim().isNotEmpty).toList();
      if (validVariants.isEmpty) {
        onError('❌ 请至少添加一个变体');
        return;
      }
    }

    // 基本单位校验
    if (unitController.text.trim().isEmpty) {
      onError('❌ 基本单位不能为空');
      return;
    }

    // 辅单位换算率校验
    final formState = ref.read(unitEditFormProvider);
    if (formState.auxiliaryUnits.isNotEmpty) {
      for (final auxUnit in formState.auxiliaryUnits) {
        if (auxUnit.unitName.trim().isNotEmpty && auxUnit.conversionRate <= 0) {
          onError('❌ 辅单位换算率不能为空');
          return;
        }
      }
    }

    // 批次开关推导
    final shelfLife = int.tryParse(shelfLifeController.text.trim());
    final enableBatch = shelfLife != null && shelfLife > 0;
    ref.read(productFormUiProvider.notifier).setEnableBatchManagement(enableBatch);

    // 重新读取UI状态（因为上面可能有修改）
    final uiState = ref.read(productFormUiProvider);
    List<AuxiliaryUnitBarcodeData>? auxiliaryBarcodeData;
    if (uiState.auxiliaryUnitBarcodes != null && uiState.auxiliaryUnitBarcodes!.isNotEmpty) {
      auxiliaryBarcodeData = uiState.auxiliaryUnitBarcodes!
          .map((item) => AuxiliaryUnitBarcodeData(
                // 某些临时ID可能包含下划线等非数字字符，例如 "1757666934778_8"，
                // 为避免 int.parse 抛出异常，这里先移除非数字字符再尝试解析，失败则置为 0。
                id: int.tryParse(
                      (item['id'] ?? '')
                          .replaceAll(RegExp(r'[^0-9]'), ''),
                    ) ??
                    0,
                barcode: item['barcode'] ?? '',
              ))
          .toList();
    }

    // 转换多变体数据
    final variantFormDataList = uiState.variants
        .where((v) => v.variantName.trim().isNotEmpty)
        .map((v) => VariantFormData(
              variantName: v.variantName.trim(),
              barcode: v.barcode.trim(),
            ))
        .toList();

    final formData = ProductFormData(
      productId: productId,
      name: nameController.text.trim(),
      selectedCategoryId: uiState.selectedCategoryId,
      newCategoryName: categoryController.text.trim(),
      selectedUnitId: uiState.selectedUnitId,
      newUnitName: unitController.text.trim(),
      imagePath: uiState.selectedImagePath,
      barcode: barcodeController.text.trim(),
      retailPriceInCents: double.tryParse(retailPriceController.text.trim()),
      promotionalPriceInCents: double.tryParse(promotionalPriceController.text.trim()),
      suggestedRetailPriceInCents: double.tryParse(suggestedRetailPriceController.text.trim()),
      stockWarningValue: int.tryParse(stockWarningValueController.text.trim()) ?? 5,
      shelfLife: int.tryParse(shelfLifeController.text.trim()),
      shelfLifeUnit: uiState.shelfLifeUnit,
      enableBatchManagement: uiState.enableBatchManagement,
      productUnits: uiState.productUnits,
      auxiliaryUnitBarcodes: auxiliaryBarcodeData,
      groupId: uiState.selectedGroupId,
      variantName: uiState.variantName,
      isMultiVariantMode: uiState.isMultiVariantMode,
      variants: variantFormDataList,
    );

    try {
      final controller = ref.read(productAddEditControllerProvider);
      final result = await controller.submitForm(formData);
      if (result.success) {
        ToastService.success('✅ ${result.message ?? '操作成功'}');
        // 提交成功，清空辅单位临时表单状态，避免下次进入串数据
        ref.read(unitEditFormProvider.notifier).resetUnitEditForm();
        onSuccess();
      } else {
        onError('❌ ${result.message ?? '操作失败'}');
      }
    } catch (e) {
      onError('❌ 操作失败: $e');
    }
  }
}
