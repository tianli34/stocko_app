import 'package:equatable/equatable.dart';
import 'package:stocko_app/features/product/domain/model/product.dart';

/// 扫码得到并在页面间传递的货品数据
class ScannedProductPayload extends Equatable {
  final ProductModel product;
  final String barcode;
  final int unitId;
  final String unitName;
  final int conversionRate;
  final int? sellingPriceInCents;
  final int? wholesalePriceInCents;
  final int? averageUnitPriceInCents;

  const ScannedProductPayload({
    required this.product,
    required this.barcode,
    required this.unitId,
    required this.unitName,
    required this.conversionRate,
    this.sellingPriceInCents,
    this.wholesalePriceInCents,
    this.averageUnitPriceInCents,
  });

  @override
  List<Object?> get props => [
        product.id,
        barcode,
        unitId,
        unitName,
        conversionRate,
        sellingPriceInCents,
        wholesalePriceInCents,
        averageUnitPriceInCents,
      ];
}
