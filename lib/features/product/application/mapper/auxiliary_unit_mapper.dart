import '../../domain/model/auxiliary_unit_data.dart';
import '../../domain/model/product_unit.dart';
import '../../domain/model/unit.dart';
import '../../presentation/widgets/auxiliary_unit/auxiliary_unit_model.dart';
import '../../shared/utils/price_converter.dart';

/// 辅单位数据映射器
/// 
/// 负责 AuxiliaryUnitModel、AuxiliaryUnitData、UnitProduct 之间的转换
class AuxiliaryUnitMapper {
  const AuxiliaryUnitMapper._();

  /// 从 AuxiliaryUnitModel 转换为 AuxiliaryUnitData
  /// 
  /// 用于保存表单数据到 Provider
  static AuxiliaryUnitData toAuxiliaryUnitData(AuxiliaryUnitModel model) {
    final retailPriceInCents = yuanToCents(model.retailPriceController.text);
    final wholesalePriceInCents = yuanToCents(model.wholesalePriceController.text);

    return AuxiliaryUnitData(
      id: model.id,
      unitId: model.unit?.id,
      unitName: model.unitController.text.trim(),
      conversionRate: model.conversionRate.toInt(),
      barcode: model.barcodeController.text.trim(),
      retailPriceInCents: retailPriceInCents?.toString() ?? '',
      wholesalePriceInCents: wholesalePriceInCents?.toString() ?? '',
    );
  }

  /// 从 AuxiliaryUnitData 转换为 AuxiliaryUnitModel
  /// 
  /// [data] 辅单位数据
  /// [unit] 关联的单位对象（可选）
  static AuxiliaryUnitModel toAuxiliaryUnitModel(
    AuxiliaryUnitData data, {
    Unit? unit,
  }) {
    final model = AuxiliaryUnitModel(
      id: data.id,
      unit: unit,
      conversionRate: data.conversionRate,
      initialSellingPrice: parseCentsStringToYuan(data.retailPriceInCents),
      initialWholesalePrice: parseCentsStringToYuan(data.wholesalePriceInCents),
    );

    model.unitController.text = data.unitName;
    model.barcodeController.text = data.barcode;

    return model;
  }

  /// 从 AuxiliaryUnitModel 转换为 UnitProduct
  /// 
  /// [model] 辅单位模型
  /// [productId] 产品ID
  /// 返回 null 如果单位无效
  static UnitProduct? toUnitProduct(AuxiliaryUnitModel model, int productId) {
    final unitId = model.unit?.id;
    if (unitId == null || model.conversionRate <= 0) {
      return null;
    }

    final sellingPriceInCents = yuanToCents(model.retailPriceController.text);
    final wholesalePriceInCents = yuanToCents(model.wholesalePriceController.text);

    return UnitProduct(
      productId: productId,
      unitId: unitId,
      conversionRate: model.conversionRate.toInt(),
      sellingPriceInCents: sellingPriceInCents,
      wholesalePriceInCents: wholesalePriceInCents,
      lastUpdated: DateTime.now(),
    );
  }

  /// 从 UnitProduct 转换为 AuxiliaryUnitModel
  /// 
  /// [unitProduct] 产品单位数据
  /// [unit] 关联的单位对象
  /// [id] 模型ID
  static AuxiliaryUnitModel fromUnitProduct(
    UnitProduct unitProduct,
    Unit unit,
    int id,
  ) {
    final model = AuxiliaryUnitModel(
      id: id,
      unit: unit,
      conversionRate: unitProduct.conversionRate,
      initialSellingPrice: centsToYuan(unitProduct.sellingPriceInCents),
      initialWholesalePrice: centsToYuan(unitProduct.wholesalePriceInCents),
    );

    model.unitController.text = unit.name;

    return model;
  }

  /// 批量转换 AuxiliaryUnitModel 列表为 AuxiliaryUnitData 列表
  static List<AuxiliaryUnitData> toAuxiliaryUnitDataList(
    List<AuxiliaryUnitModel> models,
  ) {
    return models.map(toAuxiliaryUnitData).toList();
  }

  /// 构建产品单位列表
  /// 
  /// [auxiliaryUnits] 辅单位模型列表
  /// [productId] 产品ID
  /// [baseUnitId] 基本单位ID
  /// 返回包含基本单位和所有有效辅单位的列表
  static List<UnitProduct> buildProductUnits({
    required List<AuxiliaryUnitModel> auxiliaryUnits,
    required int productId,
    required int baseUnitId,
  }) {
    final List<UnitProduct> productUnits = [];

    // 添加基本单位
    productUnits.add(UnitProduct(
      productId: productId,
      unitId: baseUnitId,
      conversionRate: 1,
    ));

    // 添加辅单位
    for (final aux in auxiliaryUnits) {
      final unitProduct = toUnitProduct(aux, productId);
      if (unitProduct != null) {
        productUnits.add(unitProduct);
      }
    }

    return productUnits;
  }

  /// 构建辅单位条码映射
  /// 
  /// [auxiliaryUnits] 辅单位模型列表
  /// [productId] 产品ID（可选，用于生成唯一标识）
  static List<Map<String, String>> buildAuxiliaryUnitBarcodes(
    List<AuxiliaryUnitModel> auxiliaryUnits, {
    int? productId,
  }) {
    final List<Map<String, String>> barcodes = [];

    for (final aux in auxiliaryUnits) {
      final unitId = aux.unit?.id;
      if (unitId != null && aux.barcodeController.text.trim().isNotEmpty) {
        barcodes.add({
          'id': '${productId ?? 'new'}_$unitId',
          'barcode': aux.barcodeController.text.trim(),
        });
      }
    }

    return barcodes;
  }
}
