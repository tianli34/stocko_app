import 'package:freezed_annotation/freezed_annotation.dart';

part 'sale_cart_item.freezed.dart';
part 'sale_cart_item.g.dart';

@freezed
abstract class SaleCartItem with _$SaleCartItem {
  const factory SaleCartItem({
    required String id,
    required int productId,
    required String productName,
    required int unitId,
    required String unitName,
    String? batchId,
    required int sellingPriceInCents,
    required double quantity,
    required double amount,
    required int conversionRate,
  }) = _SaleCartItem;

  factory SaleCartItem.fromJson(Map<String, dynamic> json) =>
      _$SaleCartItemFromJson(json);
}