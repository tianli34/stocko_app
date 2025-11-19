import 'package:drift/drift.dart' hide JsonKey;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stocko_app/core/database/database.dart';

part 'purchase_order_item.freezed.dart';
part 'purchase_order_item.g.dart';

@freezed
abstract class PurchaseOrderItemModel with _$PurchaseOrderItemModel {
  const factory PurchaseOrderItemModel({
    int? id,
    required int purchaseOrderId,
    required int unitProductId,
    required int unitPriceInCents,
    required int quantity,
    DateTime? productionDate,
  }) = _PurchaseOrderItemModel;

  const PurchaseOrderItemModel._();

  // --- 简单校验 ---
  bool get isValidOrderId => purchaseOrderId > 0;
  bool get isValidUnitProductId => unitProductId > 0;
  bool get isValidQuantity => quantity > 0;
  bool get isValidUnitPrice => unitPriceInCents >= 0; // 单价允许0（赠品场景）

  bool get isValid =>
      isValidOrderId &&
      isValidUnitProductId &&
      isValidQuantity &&
      isValidUnitPrice;

  List<String> get validationErrors {
    final errors = <String>[];
    if (!isValidOrderId) errors.add('采购订单ID必须大于0');
    if (!isValidUnitProductId) errors.add('单位产品ID必须大于0');
    if (!isValidQuantity) errors.add('数量必须大于0');
    if (!isValidUnitPrice) errors.add('单价不能为负数');
    return errors;
  }

  /// 转为 Drift Companion（插入/更新用）
  /// 在创建整单时通常先拿到 orderId，再传入此方法统一设置外键
  PurchaseOrderItemCompanion toTableCompanion(int orderId) {
    return PurchaseOrderItemCompanion(
      id: id == null ? const Value.absent() : Value(id!),
      purchaseOrderId: Value(orderId),
      unitProductId: Value(unitProductId),
      unitPriceInCents: Value(unitPriceInCents),
      quantity: Value(quantity),
      productionDate:
          productionDate != null ? Value(productionDate) : const Value.absent(),
    );
  }

  factory PurchaseOrderItemModel.fromJson(Map<String, dynamic> json) =>
      _$PurchaseOrderItemModelFromJson(json);

  factory PurchaseOrderItemModel.fromTableData(
    PurchaseOrderItemData data,
  ) {
    return PurchaseOrderItemModel(
      id: data.id,
      purchaseOrderId: data.purchaseOrderId,
      unitProductId: data.unitProductId,
      unitPriceInCents: data.unitPriceInCents,
      quantity: data.quantity,
      productionDate: data.productionDate,
    );
  }

  /// 工厂方法：带校验创建
  static PurchaseOrderItemModel createWithValidation({
    int? id,
    required int purchaseOrderId,
    required int unitProductId,
    required int unitPriceInCents,
    required int quantity,
    DateTime? productionDate,
  }) {
    final item = PurchaseOrderItemModel(
      id: id,
      purchaseOrderId: purchaseOrderId,
      unitProductId: unitProductId,
      unitPriceInCents: unitPriceInCents,
      quantity: quantity,
      productionDate: productionDate,
    );
    if (!item.isValid) {
      throw ArgumentError('数据验证失败: ${item.validationErrors.join(', ')}');
    }
    return item;
  }
}
