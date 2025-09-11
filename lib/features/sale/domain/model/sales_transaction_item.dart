import 'package:drift/drift.dart' hide JsonKey;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stocko_app/core/database/database.dart';

part 'sales_transaction_item.freezed.dart';
part 'sales_transaction_item.g.dart';

@freezed
abstract class SalesTransactionItem with _$SalesTransactionItem {
  const factory SalesTransactionItem({
    int? id,
    required int salesTransactionId,
    required int productId,
    int? batchId,
    required int quantity,
    required int priceInCents,
  }) = _SalesTransactionItem;

  const SalesTransactionItem._();

  /// 验证产品ID的有效性
  bool get isValidProductId => productId > 0;

  /// 验证批次ID的有效性（如果提供了批次ID）
  bool get isValidBatchId => batchId == null;

  /// 验证数量的有效性
  bool get isValidQuantity => quantity > 0;

  /// 验证单位价格的有效性
  bool get isValidPrice => priceInCents > 0;

  /// 验证所有必填字段的有效性
  bool get isValid =>
      isValidSalesTransactionId &&
      isValidProductId &&
      isValidBatchId &&
      isValidQuantity &&
      isValidPrice;

  /// 验证销售交易ID的有效性
  bool get isValidSalesTransactionId => salesTransactionId > 0;

  /// 批次引用关系验证 - 检查是否为批次相关商品
  bool get isBatchRelated => id != null;

  /// 获取验证错误信息列表
  List<String> get validationErrors {
    final errors = <String>[];

    if (!isValidSalesTransactionId) {
      errors.add('销售交易ID必须大于0');
    }

    if (!isValidProductId) {
      errors.add('产品ID必须大于0');
    }

    if (!isValidBatchId && batchId != null) {
      errors.add('批次ID不能为空字符串');
    }

    if (!isValidQuantity) {
      errors.add('数量必须大于0');
    }

    if (!isValidPrice) {
      errors.add('单位价格必须大于0');
    }

    return errors;
  }

  SalesTransactionItemCompanion toTableCompanion(int transactionId) {
    print('🔍 [DEBUG] Creating SalesTransactionItemCompanion with:');
    print('  - id: ${id ?? "null"} (type: ${id?.runtimeType})');
    print(
      '  - salesTransactionId: $transactionId (type: ${transactionId.runtimeType})',
    );
    print('  - productId: $productId (type: ${productId.runtimeType})');
    print('  - batchId: ${batchId ?? "null"} (type: ${batchId?.runtimeType})');
    print('  - quantity: $quantity (type: ${quantity.runtimeType})');
    print(
      '  - priceInCents: $priceInCents (type: ${priceInCents.runtimeType})',
    );

    // 修复：对于新记录，应该让数据库自动生成ID，而不是手动设置为null
    print('🔍 [DEBUG] ID is null: ${id == null}');
    print('🔍 [DEBUG] id is null: ${id == null}');

    // 检查类型转换
    if (id != null && id is! int) {
      print('🔍 [ERROR] ID type mismatch: expected int, got ${id.runtimeType}');
    }

    try {
      return SalesTransactionItemCompanion(
        id: id == null ? const Value.absent() : Value(id as int),
        salesTransactionId: Value(transactionId),
        productId: Value(productId),
        batchId: batchId != null ? Value(batchId!) : const Value.absent(),
        quantity: Value(quantity),
        priceInCents: Value(priceInCents),
      );
    } catch (e) {
      print('🔍 [ERROR] Failed to create SalesTransactionItemCompanion: $e');
      rethrow;
    }
  }

  factory SalesTransactionItem.fromJson(Map<String, dynamic> json) =>
      _$SalesTransactionItemFromJson(json);

  factory SalesTransactionItem.fromTableData(SalesTransactionItemData data) {
    return SalesTransactionItem(
      id: data.id,
      salesTransactionId: data.salesTransactionId,
      productId: data.productId,
      batchId: data.batchId,
      quantity: data.quantity,
      priceInCents: data.priceInCents.toInt(),
    );
  }

  /// 创建带有数据验证的实例
  /// 使用此方法确保所有数据验证通过
  static SalesTransactionItem createWithValidation({
    int? id,
    required int salesTransactionId,
    required int productId,
    int? batchId,
    required int quantity,
    required int priceInCents,
  }) {
    final item = SalesTransactionItem(
      id: id,
      salesTransactionId: salesTransactionId,
      productId: productId,
      batchId: batchId,
      quantity: quantity,
      priceInCents: priceInCents,
    );

    if (!item.isValid) {
      throw ArgumentError('数据验证失败: ${item.validationErrors.join(", ")}');
    }

    return item;
  }
}
