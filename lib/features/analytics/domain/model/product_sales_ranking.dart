class ProductSalesRanking {
  final int productId;
  final String name;
  final String? sku;
  final int totalQty;
  final int totalAmountInCents;
  // 新增：总利润（以分为单位）
  final int totalProfitInCents;
  // 新增：在计算利润时是否存在无法找到采购成本的销售行（>0 表示存在）
  final int missingCostCount;

  const ProductSalesRanking({
    required this.productId,
    required this.name,
    this.sku,
    required this.totalQty,
    required this.totalAmountInCents,
    required this.totalProfitInCents,
    required this.missingCostCount,
  });

  double get totalAmountYuan => totalAmountInCents / 100.0;
  double get totalProfitYuan => totalProfitInCents / 100.0;
  bool get hasMissingCost => missingCostCount > 0;
}
