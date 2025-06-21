/// 采购单商品项领域模型
/// 表示采购单中的商品明细信息
class PurchaseItem {
  final String id;
  final String productId;
  final String productName;
  final String unitName;
  final double unitPrice;
  final double quantity;
  final double amount;
  final DateTime? productionDate;

  const PurchaseItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitName,
    required this.unitPrice,
    required this.quantity,
    required this.amount,
    this.productionDate,
  });

  /// 复制并更新采购项
  PurchaseItem copyWith({
    String? id,
    String? productId,
    String? productName,
    String? unitName,
    double? unitPrice,
    double? quantity,
    double? amount,
    DateTime? productionDate,
  }) {
    return PurchaseItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitName: unitName ?? this.unitName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      amount: amount ?? this.amount,
      productionDate: productionDate ?? this.productionDate,
    );
  }

  /// 创建新的采购项
  factory PurchaseItem.create({
    required String productId,
    required String productName,
    required String unitName,
    required double unitPrice,
    required double quantity,
    DateTime? productionDate,
  }) {
    final now = DateTime.now();
    return PurchaseItem(
      id: 'item_${now.millisecondsSinceEpoch}',
      productId: productId,
      productName: productName,
      unitName: unitName,
      unitPrice: unitPrice,
      quantity: quantity,
      amount: unitPrice * quantity,
      productionDate: productionDate,
    );
  }

  /// 更新数量并重新计算金额
  PurchaseItem updateQuantity(double newQuantity) {
    return copyWith(quantity: newQuantity, amount: unitPrice * newQuantity);
  }

  /// 更新单价并重新计算金额
  PurchaseItem updateUnitPrice(double newUnitPrice) {
    return copyWith(unitPrice: newUnitPrice, amount: newUnitPrice * quantity);
  }

  /// 是否有生产日期
  bool get hasProductionDate => productionDate != null;

  /// 获取格式化的单价显示
  String get formattedUnitPrice => '¥${unitPrice.toStringAsFixed(2)}';

  /// 获取格式化的金额显示
  String get formattedAmount => '¥${amount.toStringAsFixed(2)}';

  /// 获取格式化的数量显示
  String get formattedQuantity =>
      '${quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 2)}$unitName';

  @override
  String toString() {
    return 'PurchaseItem(id: $id, productName: $productName, quantity: $quantity, unitPrice: $unitPrice, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PurchaseItem &&
        other.id == id &&
        other.productId == productId;
  }

  @override
  int get hashCode => Object.hash(id, productId);
}
