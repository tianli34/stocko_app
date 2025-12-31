// lib/features/product/presentation/models/product_form_data.dart

import '../../domain/model/product_unit.dart';

/// 辅单位条码数据
class AuxiliaryUnitBarcodeData {
  final int id;
  final String barcode;

  const AuxiliaryUnitBarcodeData({required this.id, required this.barcode});
}

/// 变体数据（用于批量创建）
class VariantFormData {
  final String variantName;
  final String barcode;

  const VariantFormData({
    required this.variantName,
    this.barcode = '',
  });
}

/// 表单数据封装
class ProductFormData {
  final int? productId;
  final String name;
  final int? selectedCategoryId;
  final String newCategoryName;
  final int? selectedUnitId;
  final String newUnitName;
  final String? imagePath;
  final String barcode;
  // 价格（元）
  final double? costInCents;
  final double? retailPriceInCents;
  final double? promotionalPriceInCents;
  final double? suggestedRetailPriceInCents;
  final int? stockWarningValue;
  final int? shelfLife;
  final String shelfLifeUnit;
  final bool enableBatchManagement;
  final String? remarks;
  final List<UnitProduct>? productUnits;
  final List<AuxiliaryUnitBarcodeData>? auxiliaryUnitBarcodes;
  // 商品组相关
  final int? groupId;
  final String? variantName;
  // 多变体模式
  final bool isMultiVariantMode;
  final List<VariantFormData> variants;

  const ProductFormData({
    this.productId,
    required this.name,
    this.selectedCategoryId,
    this.newCategoryName = '',
    this.selectedUnitId,
    this.newUnitName = '',
    this.imagePath,
    this.barcode = '',
    this.costInCents,
    this.retailPriceInCents,
    this.promotionalPriceInCents,
    this.suggestedRetailPriceInCents,
    this.stockWarningValue,
    this.shelfLife,
    this.shelfLifeUnit = 'months',
    this.enableBatchManagement = false,
    this.remarks,
    this.productUnits,
    this.auxiliaryUnitBarcodes,
    this.groupId,
    this.variantName,
    this.isMultiVariantMode = false,
    this.variants = const [],
  });

  /// 是否为编辑模式
  bool get isEditMode => productId != null;

  /// 是否为新增模式
  bool get isCreateMode => productId == null;
}
