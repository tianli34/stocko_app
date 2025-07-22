import 'package:freezed_annotation/freezed_annotation.dart';
import 'sales_transaction_item.dart';

part 'sales_transaction.freezed.dart';
part 'sales_transaction.g.dart';

enum SalesStatus { pending, completed, cancelled }

@freezed
abstract class SalesTransaction with _$SalesTransaction {
  const factory SalesTransaction({
    int? id,
    int? customerId,
    required int shopId,
    required DateTime transactionDate,
    required double totalAmount,
    required double actualAmount,
    @Default(SalesStatus.completed) SalesStatus status,
    @Default([]) List<SalesTransactionItem> items,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _SalesTransaction;

  const SalesTransaction._();

  factory SalesTransaction.fromJson(Map<String, dynamic> json) =>
      _$SalesTransactionFromJson(json);
}
