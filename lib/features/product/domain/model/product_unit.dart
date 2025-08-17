import 'package:freezed_annotation/freezed_annotation.dart';
part 'product_unit.freezed.dart';
part 'product_unit.g.dart';

@freezed
abstract class UnitProduct with _$UnitProduct {
  const factory UnitProduct({
    int? id, // 主键
    required int productId, // 外键, 指向 Products 表
    required int unitId, // 外键, 指向 Units 表
    required int conversionRate, // 换算率
    int? sellingPriceInCents, // 售价
    int? wholesalePriceInCents, // 批发价
    DateTime? lastUpdated, // 最后更新日期
  }) = _UnitProduct;

  const UnitProduct._();

  factory UnitProduct.fromJson(Map<String, dynamic> json) =>
      _$UnitProductFromJson(json);

  // 将以“分”为单位的价格转换为“元”以供显示
  double get displaySellingPrice => (sellingPriceInCents ?? 0) / 100.0;
  double get displayWholesalePrice => (wholesalePriceInCents ?? 0) / 100.0;

  // 根据数量和换算率计算基础单位数量
  int calculateBaseQuantity(int quantity) {
    return quantity * conversionRate;
  }

  // 根据基础单位数量计算当前单位数量
  int calculateUnitQuantity(int baseQuantity) {
    return baseQuantity ~/ conversionRate;
  }

  // 复制并更新最后更新时间
  UnitProduct updateTimestamp() {
    return copyWith(lastUpdated: DateTime.now());
  }
}
