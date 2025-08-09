/// 入库单商品项领域模型
/// 表示入库单中的商品明细信息
class InboundItem {
  final String id;
  final int productId;
  final String productName;
  final int unitId;
  final String unitName;
  final double unitPrice;
  final double quantity;
  final double amount;
  final DateTime? productionDate;

  const InboundItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitId,
    required this.unitName,
    required this.unitPrice,
    required this.quantity,
    required this.amount,
    this.productionDate,
  });

  /// 复制并更新入库项
  InboundItem copyWith({
    String? id,
    int? productId,
    String? productName,
    int? unitId,
    String? unitName,
    double? unitPrice,
    double? quantity,
    double? amount,
    DateTime? productionDate,
  }) {
    return InboundItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      amount: amount ?? this.amount,
      productionDate: productionDate ?? this.productionDate,
    );
  }

  /// 创建新的入库项
  factory InboundItem.create({
    required int productId,
    required String productName,
    required int unitId,
    required String unitName,
    required double unitPrice,
    required double quantity,
    DateTime? productionDate,
  }) {
    final now = DateTime.now();
    return InboundItem(
      id: 'item_${now.millisecondsSinceEpoch}',
      productId: productId,
      productName: productName,
      unitId: unitId,
      unitName: unitName,
      unitPrice: unitPrice,
      quantity: quantity,
      amount: unitPrice * quantity,
      productionDate: productionDate,
    );
  }

  /// 更新数量并重新计算金额
  InboundItem updateQuantity(double newQuantity) {
    return copyWith(quantity: newQuantity, amount: unitPrice * newQuantity);
  }

  /// 更新单价并重新计算金额
  InboundItem updateUnitPrice(double newUnitPrice) {
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
    return 'InboundItem(id: $id, productName: $productName, quantity: $quantity, unitPrice: $unitPrice, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InboundItem &&
        other.id == id &&
        other.productId == productId;
  }

  @override
  int get hashCode => Object.hash(id, productId);
}
