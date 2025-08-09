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
    required int unitId,
    String? batchId,
    required int quantity,
    required double unitPrice,
    required double totalPrice,
  }) = _SalesTransactionItem;

  const SalesTransactionItem._();

  /// 验证产品ID的有效性
  bool get isValidProductId => productId > 0;

  /// 验证单位ID的有效性
  bool get isValidUnitId => unitId > 0;

  /// 验证批次ID的有效性（如果提供了批次ID）
  bool get isValidBatchId => batchId == null || batchId!.isNotEmpty;

  /// 验证数量的有效性
  bool get isValidQuantity => quantity > 0;

  /// 验证单位价格的有效性
  bool get isValidUnitPrice => unitPrice > 0;

  /// 验证总价的有效性
  bool get isValidTotalPrice => totalPrice > 0;

  /// 验证总价是否等于数量乘以单位价格
  bool get isValidPriceCalculation {
    const epsilon = 0.001; // 定义一个小的容差值
    return (totalPrice - (quantity * unitPrice)).abs() < epsilon;
  }

  /// 验证所有必填字段的有效性
  bool get isValid =>
      isValidSalesTransactionId &&
      isValidProductId &&
      isValidUnitId &&
      isValidBatchId &&
      isValidQuantity &&
      isValidUnitPrice &&
      isValidTotalPrice &&
      isValidPriceCalculation;

  /// 验证销售交易ID的有效性
  bool get isValidSalesTransactionId => salesTransactionId > 0;

  /// 批次引用关系验证 - 检查是否为批次相关商品
  bool get isBatchRelated => batchId != null && batchId!.isNotEmpty;

  /// 获取验证错误信息列表
  List<String> get validationErrors {
    final errors = <String>[];

    if (!isValidSalesTransactionId) {
      errors.add('销售交易ID必须大于0');
    }

    if (!isValidProductId) {
      errors.add('产品ID必须大于0');
    }

    if (!isValidUnitId) {
      errors.add('单位ID不能为空');
    }

    if (!isValidBatchId && batchId != null) {
      errors.add('批次ID不能为空字符串');
    }

    if (!isValidQuantity) {
      errors.add('数量必须大于0');
    }

    if (!isValidUnitPrice) {
      errors.add('单位价格必须大于0');
    }

    if (!isValidTotalPrice) {
      errors.add('总价必须大于0');
    }

    if (!isValidPriceCalculation) {
      errors.add('总价必须等于数量 × 单位价格');
    }

    return errors;
  }

  SalesTransactionItemsTableCompanion toTableCompanion(int transactionId) {
    print('🔍 [DEBUG] Creating SalesTransactionItemsTableCompanion with:');
    print('  - id: ${id ?? "null"} (type: ${id?.runtimeType})');
    print('  - salesTransactionId: $transactionId (type: ${transactionId.runtimeType})');
    print('  - productId: $productId (type: ${productId.runtimeType})');
    print('  - unitId: $unitId (type: ${unitId.runtimeType})');
    print('  - batchId: ${batchId ?? "null"} (type: ${batchId?.runtimeType})');
    print('  - quantity: $quantity (type: ${quantity.runtimeType})');
    print('  - unitPrice: $unitPrice (type: ${unitPrice.runtimeType})');
    print('  - totalPrice: $totalPrice (type: ${totalPrice.runtimeType})');

    // 修复：对于新记录，应该让数据库自动生成ID，而不是手动设置为null
    print('🔍 [DEBUG] ID is null: ${id == null}');
    print('🔍 [DEBUG] batchId is null: ${batchId == null}');
    
    // 检查类型转换
    if (id != null && id is! int) {
      print('🔍 [ERROR] ID type mismatch: expected int, got ${id.runtimeType}');
    }
    
    if (batchId != null && batchId is! String) {
      print('🔍 [ERROR] batchId type mismatch: expected String, got ${batchId.runtimeType}');
    }

    try {
      return SalesTransactionItemsTableCompanion(
        id: id == null ? const Value.absent() : Value(id as int),
        salesTransactionId: Value(transactionId),
        productId: Value(productId),
        unitId: Value(unitId),
        batchId: batchId != null ? Value(batchId!) : const Value.absent(),
        quantity: Value(quantity),
        unitPrice: Value(unitPrice),
        totalPrice: Value(totalPrice),
      );
    } catch (e) {
      print('🔍 [ERROR] Failed to create SalesTransactionItemsTableCompanion: $e');
      rethrow;
    }
  }

  factory SalesTransactionItem.fromJson(Map<String, dynamic> json) =>
      _$SalesTransactionItemFromJson(json);

  factory SalesTransactionItem.fromTableData(
    SalesTransactionItemsTableData data,
  ) {
    return SalesTransactionItem(
      id: data.id,
      salesTransactionId: data.salesTransactionId,
      productId: data.productId,
      unitId: data.unitId,
      batchId: data.batchId,
      quantity: data.quantity,
      unitPrice: data.unitPrice,
      totalPrice: data.totalPrice,
    );
  }

  /// 创建带有数据验证的实例
  /// 使用此方法确保所有数据验证通过
  static SalesTransactionItem createWithValidation({
    int? id,
    required int salesTransactionId,
    required int productId,
    required int unitId,
    String? batchId,
    required int quantity,
    required double unitPrice,
    required double totalPrice,
  }) {
    final item = SalesTransactionItem(
      id: id,
      salesTransactionId: salesTransactionId,
      productId: productId,
      unitId: unitId,
      batchId: batchId,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
    );

    if (!item.isValid) {
      throw ArgumentError('数据验证失败: ${item.validationErrors.join(", ")}');
    }

    return item;
  }
}
