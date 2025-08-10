/// 销售单商品项领域模型
/// 表示销售单中的商品明细信息
class SaleItem {
  final String id;
  final int productId;
  final String productName;
  final int unitId;
  final String unitName;
  final String? batchId;
  final int sellingPriceInCents; // 从 unitPrice 改为 sellingPriceInCents
  final int quantity;
  final double amount;
  const SaleItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitId,
    required this.unitName,
    this.batchId,
    required this.sellingPriceInCents,
    required this.quantity,
    required this.amount,
  });

  /// 复制并更新销售项
  SaleItem copyWith({
    String? id,
    int? productId,
    String? productName,
    int? unitId,
    String? unitName,
    String? batchId,
    int? sellingPriceInCents,
    int? quantity,
    double? amount,
  }) {
    return SaleItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      batchId: batchId ?? this.batchId,
      sellingPriceInCents: sellingPriceInCents ?? this.sellingPriceInCents,
      quantity: quantity ?? this.quantity,
      amount: amount ?? this.amount,
    );
  }

  /// 创建新的销售项
  factory SaleItem.create({
    required int productId,
    required String productName,
    required int unitId,
    required String unitName,
    String? batchId,
    required int sellingPriceInCents,
    required int quantity,
  }) {
    final now = DateTime.now();
    return SaleItem(
      id: 'item_${now.millisecondsSinceEpoch}',
      productId: productId,
      productName: productName,
      unitId: unitId,
      unitName: unitName,
      batchId: batchId,
      sellingPriceInCents: sellingPriceInCents,
      quantity: quantity,
      amount: sellingPriceInCents/100 * quantity,
    );
  }

  /// 更新数量并重新计算金额
  SaleItem updateQuantity(int newQuantity) {
    return copyWith(quantity: newQuantity, amount: sellingPriceInCents/100 * newQuantity);
  }

  /// 更新销售价并重新计算金额
  SaleItem updateSellingPrice(double newSellingPrice) {
    return copyWith(sellingPriceInCents: (newSellingPrice * 100).toInt(), amount: newSellingPrice * quantity);
  }

  /// 获取格式化的销售价显示
  String get formattedSellingPrice => '¥${sellingPriceInCents.toStringAsFixed(2)}';

  /// 获取格式化的金额显示
  String get formattedAmount => '¥${amount.toStringAsFixed(2)}';

  /// 获取格式化的数量显示
  String get formattedQuantity =>
      '${quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 2)}$unitName';

  @override
  String toString() {
    return 'SaleItem(id: $id, productName: $productName, quantity: $quantity, sellingPriceInCents: $sellingPriceInCents, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SaleItem &&
        other.id == id &&
        other.productId == productId;
  }

  @override
  int get hashCode => Object.hash(id, productId);
}