import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/product_unit.dart';

/// 描述货品表单在 UI 层需要维护的可序列化状态
class ProductFormUiState {
  final int? selectedCategoryId;
  final int? selectedUnitId;
  final String? selectedImagePath;
  final List<UnitProduct>? productUnits;
  final List<Map<String, String>>? auxiliaryUnitBarcodes;
  final String shelfLifeUnit; // days | months | years
  final bool enableBatchManagement;

  const ProductFormUiState({
    this.selectedCategoryId,
    this.selectedUnitId,
    this.selectedImagePath,
    this.productUnits,
    this.auxiliaryUnitBarcodes,
    this.shelfLifeUnit = 'months',
    this.enableBatchManagement = false,
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
  }) {
    return ProductFormUiState(
      selectedCategoryId: selectedCategoryIdToNull
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      selectedUnitId:
          selectedUnitIdToNull ? null : (selectedUnitId ?? this.selectedUnitId),
      selectedImagePath: selectedImagePathToNull
          ? null
          : (selectedImagePath ?? this.selectedImagePath),
      productUnits:
          productUnitsToNull ? null : (productUnits ?? this.productUnits),
      auxiliaryUnitBarcodes: auxiliaryUnitBarcodesToNull
          ? null
          : (auxiliaryUnitBarcodes ?? this.auxiliaryUnitBarcodes),
      shelfLifeUnit: shelfLifeUnit ?? this.shelfLifeUnit,
      enableBatchManagement:
          enableBatchManagement ?? this.enableBatchManagement,
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

  void reset() {
    state = const ProductFormUiState();
  }
}

final productFormUiProvider =
    StateNotifierProvider.autoDispose<ProductFormUiNotifier, ProductFormUiState>(
  (ref) => ProductFormUiNotifier(),
);
