import 'package:freezed_annotation/freezed_annotation.dart';

part 'inventory_transaction.freezed.dart';
part 'inventory_transaction.g.dart';

/// 库存流水领域模型
/// 表示库存变动的历史记录
@freezed
abstract class InventoryTransaction with _$InventoryTransaction {
  const factory InventoryTransaction({
    required String id,
    required int productId,
    required String type,
    required int quantity,
    required String shopId,
    required DateTime time,
    String? batchId, // 批次号（外键）
    DateTime? createdAt,
  }) = _InventoryTransaction;

  const InventoryTransaction._();

  factory InventoryTransaction.fromJson(Map<String, dynamic> json) =>
      _$InventoryTransactionFromJson(json);

  /// 流水类型常量
  static const String typeIn = 'in'; // 入库
  static const String typeOut = 'out'; // 出库
  static const String typeAdjust = 'adjust'; // 调整
  static const String typeTransfer = 'transfer'; // 调拨
  static const String typeReturn = 'return'; // 退货

  /// 流水类型显示名称映射
  static const Map<String, String> typeNames = {
    typeIn: '入库',
    typeOut: '出库',
    typeAdjust: '调整',
    typeTransfer: '调拨',
    typeReturn: '退货',
  };

  /// 创建入库流水
  factory InventoryTransaction.createInbound({
    required int productId,
    required int quantity,
    required String shopId,
    DateTime? time,
    String? batchId,
  }) {
    final now = DateTime.now();
    return InventoryTransaction(
      id: 'transaction_${now.millisecondsSinceEpoch}',
      productId: productId,
      type: typeIn,
      quantity: quantity,
      shopId: shopId,
      time: time ?? now,
      batchId: batchId,
      createdAt: now,
    );
  }

  /// 创建出库流水
  factory InventoryTransaction.createOutbound({
    required int productId,
    required int quantity,
    required String shopId,
    DateTime? time,
    String? batchId,
  }) {
    final now = DateTime.now();
    return InventoryTransaction(
      id: 'transaction_${now.millisecondsSinceEpoch}',
      productId: productId,
      type: typeOut,
      quantity: quantity,
      shopId: shopId,
      time: time ?? now,
      batchId: batchId,
      createdAt: now,
    );
  }

  /// 创建调整流水
  factory InventoryTransaction.createAdjustment({
    required int productId,
    required int quantity,
    required String shopId,
    DateTime? time,
    String? batchId,
  }) {
    final now = DateTime.now();
    return InventoryTransaction(
      id: 'transaction_${now.millisecondsSinceEpoch}',
      productId: productId,
      type: typeAdjust,
      quantity: quantity,
      shopId: shopId,
      time: time ?? now,
      batchId: batchId,
      createdAt: now,
    );
  }

  /// 获取流水类型显示名称
  String get typeDisplayName => typeNames[type] ?? type;

  /// 是否为入库
  bool get isInbound => type == typeIn;

  /// 是否为出库
  bool get isOutbound => type == typeOut;

  /// 是否为调整
  bool get isAdjustment => type == typeAdjust;

  /// 是否为调拨
  bool get isTransfer => type == typeTransfer;

  /// 是否为退货
  bool get isReturn => type == typeReturn;
}
