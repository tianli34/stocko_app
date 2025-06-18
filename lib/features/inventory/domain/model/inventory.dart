import 'package:freezed_annotation/freezed_annotation.dart';

part 'inventory.freezed.dart';
part 'inventory.g.dart';

/// 库存领域模型
/// 表示产品在店铺的库存信息
@freezed
abstract class Inventory with _$Inventory {
  const factory Inventory({
    required String id,
    required String productId,
    required double quantity,
    required String shopId,
    required String batchNumber, // 批次号（外键）
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Inventory;

  const Inventory._();
  factory Inventory.fromJson(Map<String, dynamic> json) =>
      _$InventoryFromJson(json);

  /// 创建新库存记录
  factory Inventory.create({
    required String productId,
    required double quantity,
    required String shopId,
    required String batchNumber,
  }) {
    final now = DateTime.now();
    return Inventory(
      id: 'inventory_${now.millisecondsSinceEpoch}',
      productId: productId,
      quantity: quantity,
      shopId: shopId,
      batchNumber: batchNumber,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 更新库存数量
  Inventory updateQuantity(double newQuantity) {
    return copyWith(quantity: newQuantity, updatedAt: DateTime.now());
  }

  /// 增加库存
  Inventory addQuantity(double amount) {
    return updateQuantity(quantity + amount);
  }

  /// 减少库存
  Inventory subtractQuantity(double amount) {
    return updateQuantity(quantity - amount);
  }

  /// 是否库存不足
  bool isLowStock(int warningLevel) {
    return quantity <= warningLevel;
  }

  /// 是否库存为零
  bool get isOutOfStock => quantity <= 0;

  /// 是否来自同一批次
  bool isSameBatch(String otherBatchNumber) {
    return batchNumber == otherBatchNumber;
  }

  /// 根据批次号生成库存ID
  /// 格式：inventory_批次号_时间戳
  static String generateInventoryIdWithBatch(String batchNumber) {
    final now = DateTime.now();
    return 'inventory_${batchNumber}_${now.millisecondsSinceEpoch}';
  }
}
