import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:drift/drift.dart' hide JsonKey;
import 'sales_transaction_item.dart';
import 'package:stocko_app/core/database/database.dart';

part 'sales_transaction.freezed.dart';
part 'sales_transaction.g.dart';

enum SalesStatus { preset, credit, settled, cancelled }

@freezed
abstract class SalesTransaction with _$SalesTransaction {
  const factory SalesTransaction({
    int? id,
    required int customerId,
    required int shopId,
    required double totalAmount,
    required double actualAmount,
    @Default(SalesStatus.preset) SalesStatus status,
    @Default(<SalesTransactionItem>[]) List<SalesTransactionItem> items,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _SalesTransaction;

  SalesTransactionCompanion toTableCompanion() {
    print('🔍 [DEBUG] Creating SalesTransactionCompanion with:');
    print('  - id: ${id ?? 0}');
    print('  - customerId: $customerId');
    print('  - shopId: $shopId');
    print('  - totalAmount: $totalAmount');
    print('  - actualAmount: $actualAmount');
    print('  - status: ${status.toString().split('.').last}');
    print('  - remarks: $remarks');

    // 修复：对于新记录，应该让数据库自动生成ID，而不是手动设置为0
    print('🔍 [DEBUG] ID is null: ${id == null}');

    return SalesTransactionCompanion(
      id: id == null ? const Value.absent() : Value(id!),
      customerId: Value(customerId),
      shopId: Value(shopId),
      totalAmount: Value(totalAmount),
      actualAmount: Value(actualAmount),
      status: Value(status.toString().split('.').last),
      remarks: Value(remarks),
    );
  }

  const SalesTransaction._();

  factory SalesTransaction.fromJson(Map<String, dynamic> json) =>
      _$SalesTransactionFromJson(json);

  factory SalesTransaction.fromTableData(
    SalesTransactionData data, {
    List<SalesTransactionItem> items = const [],
  }) {
    return SalesTransaction(
      id: data.id,
      customerId: data.customerId,
      totalAmount: data.totalAmount,
      actualAmount: data.totalAmount, // 假设实际金额等于总金额
      shopId: 0, // 数据库中没有，暂时设为0
      status: SalesStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data.status,
        orElse: () => SalesStatus.preset,
      ),
      remarks: data.remarks,
      items: items,
    );
  }
}
