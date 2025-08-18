import 'package:freezed_annotation/freezed_annotation.dart';

part 'inventory_transaction.freezed.dart';
part 'inventory_transaction.g.dart';

/// 库存流水类型
enum InventoryTransactionType {
  /// 入库
  @JsonValue('in')
  inbound,

  /// 出库
  @JsonValue('out')
  outbound,

  /// 调整
  @JsonValue('adjust')
  adjustment,

  /// 调拨
  @JsonValue('transfer')
  transfer,

  /// 退货
  @JsonValue('return')
  returned,
}

extension InventoryTransactionTypeExtension on InventoryTransactionType {
  String get displayName {
    switch (this) {
      case InventoryTransactionType.inbound:
        return '入库';
      case InventoryTransactionType.outbound:
        return '出库';
      case InventoryTransactionType.adjustment:
        return '调整';
      case InventoryTransactionType.transfer:
        return '调拨';
      case InventoryTransactionType.returned:
        return '退货';
    }
  }

  /// 将枚举映射为数据库字段允许的短码
  String get toDbCode {
    switch (this) {
      case InventoryTransactionType.inbound:
        return 'in';
      case InventoryTransactionType.outbound:
        return 'out';
      case InventoryTransactionType.adjustment:
        return 'adjust';
      case InventoryTransactionType.transfer:
        return 'transfer';
      case InventoryTransactionType.returned:
        return 'return';
    }
  }
}

/// 从数据库短码还原为枚举值
InventoryTransactionType inventoryTransactionTypeFromDbCode(String code) {
  switch (code) {
    case 'in':
      return InventoryTransactionType.inbound;
    case 'out':
      return InventoryTransactionType.outbound;
    case 'adjust':
      return InventoryTransactionType.adjustment;
    case 'transfer':
      return InventoryTransactionType.transfer;
    case 'return':
      return InventoryTransactionType.returned;
    default:
      // 兜底：按入库处理
      return InventoryTransactionType.inbound;
  }
}


/// 库存流水领域模型
/// 表示库存变动的历史记录
@freezed
abstract class InventoryTransactionModel with _$InventoryTransactionModel {
  const factory InventoryTransactionModel({
    int? id,
    required int productId,
    required InventoryTransactionType type,
    required int quantity,
    required int shopId,
    int? batchId, 
    DateTime? createdAt,
  }) = _InventoryTransactionModel;

  const InventoryTransactionModel._();

  factory InventoryTransactionModel.fromJson(Map<String, dynamic> json) =>
      _$InventoryTransactionModelFromJson(json);

  /// 创建入库流水
  factory InventoryTransactionModel.createInbound({
    required int productId,
    required int quantity,
    required int shopId,
    int? batchId,
  }) {
    return InventoryTransactionModel(
      id: null,
      productId: productId,
      type: InventoryTransactionType.inbound,
      quantity: quantity,
      shopId: shopId,
      batchId: batchId,
    );
  }

  /// 创建出库流水
  factory InventoryTransactionModel.createOutbound({
    required int productId,
    required int quantity,
    required int shopId,
    int? batchId,
  }) {
    return InventoryTransactionModel(
      id: null,
      productId: productId,
      type: InventoryTransactionType.outbound,
      quantity: quantity,
      shopId: shopId,
      batchId: batchId,
    );
  }

  /// 创建调整流水
  factory InventoryTransactionModel.createAdjustment({
    required int productId,
    required int quantity,
    required int shopId,
    int? batchId,
  }) {
    return InventoryTransactionModel(
      id: null,
      productId: productId,
      type: InventoryTransactionType.adjustment,
      quantity: quantity,
      shopId: shopId,
      batchId: batchId,
    );
  }

  /// 获取流水类型显示名称
  String get typeDisplayName => type.displayName;

  /// 是否为入库
  bool get isInbound => type == InventoryTransactionType.inbound;

  /// 是否为出库
  bool get isOutbound => type == InventoryTransactionType.outbound;

  /// 是否为调整
  bool get isAdjustment => type == InventoryTransactionType.adjustment;

  /// 是否为调拨
  bool get isTransfer => type == InventoryTransactionType.transfer;

  /// 是否为退货
  bool get isReturn => type == InventoryTransactionType.returned;
}
