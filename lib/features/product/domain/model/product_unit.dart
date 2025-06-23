import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_unit.freezed.dart';
part 'product_unit.g.dart';

@freezed
abstract class ProductUnit with _$ProductUnit {
  const factory ProductUnit({
    required String productUnitId, // 主键
    required String productId, // 外键, 指向 Products 表
    required String unitId, // 外键, 指向 Units 表
    required double conversionRate, // 换算率
    double? sellingPrice, // 售价
    DateTime? lastUpdated, // 最后更新日期
  }) = _ProductUnit;

  const ProductUnit._();

  factory ProductUnit.fromJson(Map<String, dynamic> json) =>
      _$ProductUnitFromJson(json);

  // 获取格式化的售价显示
  String get formattedSellingPrice {
    if (sellingPrice == null) return '价格待定';
    return '¥${sellingPrice!.toStringAsFixed(2)}';
  }

  // 获取格式化的换算率显示
  String get formattedConversionRate {
    if (conversionRate == 1.0) return '1:1';
    return '1:${conversionRate.toStringAsFixed(2)}';
  }

  // 是否有售价
  bool get hasSellingPrice => sellingPrice != null;

  // 根据数量和换算率计算基础单位数量
  double calculateBaseQuantity(double quantity) {
    return quantity * conversionRate;
  }

  // 根据基础单位数量计算当前单位数量
  double calculateUnitQuantity(double baseQuantity) {
    return baseQuantity / conversionRate;
  }

  // 复制并更新最后更新时间
  ProductUnit updateTimestamp() {
    return copyWith(lastUpdated: DateTime.now());
  }
}
