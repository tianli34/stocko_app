import 'package:freezed_annotation/freezed_annotation.dart';

part 'sales_transaction_item.freezed.dart';
part 'sales_transaction_item.g.dart';

@freezed
abstract class SalesTransactionItem with _$SalesTransactionItem {
  const factory SalesTransactionItem({
    int? id,
    required int salesTransactionId,
    required int productId,
    required int unitId,
    int? batchId,
    required double quantity,
    required double unitPrice,
    required double totalPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _SalesTransactionItem;

  const SalesTransactionItem._();

  factory SalesTransactionItem.fromJson(Map<String, dynamic> json) =>
      _$SalesTransactionItemFromJson(json);
}
