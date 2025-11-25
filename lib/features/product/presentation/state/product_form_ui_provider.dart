import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/product_unit.dart';
import '../widgets/multi_variant_input_section.dart';

/// 描述货品表单在 UI 层需要维护的可序列化状态
class ProductFormUiState {
  final int? selectedCategoryId;
  final int? selectedUnitId;
  final String? selectedImagePath;
  final List<UnitProduct>? productUnits;
  final List<Map<String, String>>? auxiliaryUnitBarcodes;
  final String shelfLifeUnit; // days | months | years
  final bool enableBatchManagement;
  final bool hasEnteredAuxUnitPage; // 是否进入过辅单位编辑页面
  final int? selectedGroupId; // 商品组ID
  final String? variantName; // 变体名称（单变体模式）
  final List<VariantInputData> variants; // 多变体列表
  final bool isMultiVariantMode; // 是否为多变体录入模式

  const ProductFormUiState({
    this.selectedCategoryId,
    this.selectedUnitId,
    this.selectedImagePath,
    this.productUnits,
    this.auxiliaryUnitBarcodes,
    this.shelfLifeUnit = 'months',
    this.enableBatchManagement = false,
    this.hasEnteredAuxUnitPage = false,
    this.selectedGroupId,
    this.variantName,
    this.variants = const [],
    this.isMultiVariantMode = false,
  });

  ProductFormUiState copyWith({
    int? selectedCategoryId,
    bool selectedCategoryIdToNull = false,
    int? selectedUnitId,
    bool selectedUnitIdToNull = false,
    String? selectedImagePath,
    bool selectedImagePathToNull = false,
    List<UnitProduct>? productUnits,
    bool productUnitsToNull = false,
    List<Map<String, String>>? auxiliaryUnitBarcodes,
    bool auxiliaryUnitBarcodesToNull = false,
    String? shelfLifeUnit,
    bool? enableBatchManagement,
    bool? hasEnteredAuxUnitPage,
    int? selectedGroupId,
    bool selectedGroupIdToNull = false,
    String? variantName,
    bool variantNameToNull = false,
    List<VariantInputData>? variants,
    bool? isMultiVariantMode,
  }) {
    return ProductFormUiState(
      selectedCategoryId: selectedCategoryIdToNull
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      selectedUnitId: selectedUnitIdToNull
          ? null
          : (selectedUnitId ?? this.selectedUnitId),
      selectedImagePath: selectedImagePathToNull
          ? null
          : (selectedImagePath ?? this.selectedImagePath),
      productUnits: productUnitsToNull
          ? null
          : (productUnits ?? this.productUnits),
      auxiliaryUnitBarcodes: auxiliaryUnitBarcodesToNull
          ? null
          : (auxiliaryUnitBarcodes ?? this.auxiliaryUnitBarcodes),
      shelfLifeUnit: shelfLifeUnit ?? this.shelfLifeUnit,
      enableBatchManagement:
          enableBatchManagement ?? this.enableBatchManagement,
      hasEnteredAuxUnitPage:
          hasEnteredAuxUnitPage ?? this.hasEnteredAuxUnitPage,
      selectedGroupId: selectedGroupIdToNull
          ? null
          : (selectedGroupId ?? this.selectedGroupId),
      variantName: variantNameToNull
          ? null
          : (variantName ?? this.variantName),
      variants: variants ?? this.variants,
      isMultiVariantMode: isMultiVariantMode ?? this.isMultiVariantMode,
    );
  }
}

class ProductFormUiNotifier extends StateNotifier<ProductFormUiState> {
  ProductFormUiNotifier() : super(const ProductFormUiState());

  void setCategoryId(int? id) {
    state = state.copyWith(
      selectedCategoryId: id,
      selectedCategoryIdToNull: id == null,
    );
  }

  void setUnitId(int? id) {
    state = state.copyWith(
      selectedUnitId: id,
      selectedUnitIdToNull: id == null,
    );
  }

  void setImagePath(String? path) {
    state = state.copyWith(
      selectedImagePath: path,
      selectedImagePathToNull: path == null,
    );
  }

  void setProductUnitsAndBarcodes({
    List<UnitProduct>? productUnits,
    List<Map<String, String>>? auxiliaryUnitBarcodes,
  }) {
    state = state.copyWith(
      productUnits: productUnits,
      productUnitsToNull: productUnits == null,
      auxiliaryUnitBarcodes: auxiliaryUnitBarcodes,
      auxiliaryUnitBarcodesToNull: auxiliaryUnitBarcodes == null,
    );
  }

  void setShelfLifeUnit(String unit) {
    state = state.copyWith(shelfLifeUnit: unit);
  }

  void setEnableBatchManagement(bool enable) {
    state = state.copyWith(enableBatchManagement: enable);
  }

  void setHasEnteredAuxUnitPage(bool hasEntered) {
    state = state.copyWith(hasEnteredAuxUnitPage: hasEntered);
  }

  void setGroupId(int? id) {
    state = state.copyWith(
      selectedGroupId: id,
      selectedGroupIdToNull: id == null,
    );
  }

  void setVariantName(String? name) {
    state = state.copyWith(
      variantName: name,
      variantNameToNull: name == null || name.isEmpty,
    );
  }

  void setVariants(List<VariantInputData> variants) {
    state = state.copyWith(variants: variants);
  }

  void setMultiVariantMode(bool isMultiVariant) {
    state = state.copyWith(isMultiVariantMode: isMultiVariant);
  }

  void reset() {
    state = const ProductFormUiState();
  }
}

final productFormUiProvider =
    StateNotifierProvider.autoDispose<
      ProductFormUiNotifier,
      ProductFormUiState
    >((ref) => ProductFormUiNotifier());
