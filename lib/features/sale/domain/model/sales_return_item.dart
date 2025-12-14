import 'package:freezed_annotation/freezed_annotation.dart';

part 'sales_return_item.freezed.dart';
part 'sales_return_item.g.dart';

/// 销售退货明细领域模型
@freezed
abstract class SalesReturnItemModel with _$SalesReturnItemModel {
  const factory SalesReturnItemModel({
    int? id,
    required int salesReturnId,
    int? salesTransactionItemId,
    required int productId,
    int? unitId,
    int? batchId,
    required int quantity,
    required int priceInCents,
  }) = _SalesReturnItemModel;

  const SalesReturnItemModel._();

  factory SalesReturnItemModel.fromJson(Map<String, dynamic> json) =>
      _$SalesReturnItemModelFromJson(json);

  /// 计算退货金额（分）
  int get totalPriceInCents => quantity * priceInCents;

  /// 计算退货金额（元）
  double get totalAmount => totalPriceInCents / 100;

  /// 验证数量有效性
  bool get isValidQuantity => quantity > 0;

  /// 验证价格有效性
  bool get isValidPrice => priceInCents > 0;
}
