/// 批次模型
/// 用于批次管理功能的数据模型
class Batch {
  final String batchNumber;
  final int productId;
  final DateTime productionDate;

  /// 初始数量，同一批次可累加
  final int initialQuantity;

  final String shopId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Batch({
    required this.batchNumber,
    required this.productId,
    required this.productionDate,
    required this.initialQuantity,
    required this.shopId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 根据货品ID和生产日期生成批次号
  /// 格式: 货品ID前3位 + YYYYMMDD (如: ABC20250523)
  static String generateBatchNumber(int productId, DateTime productionDate) {
    final productIdStr = productId.toString();
    final productPrefix = productIdStr.length >= 3
        ? productIdStr.substring(0, 3).toUpperCase()
        : productIdStr.padRight(3, '0').toUpperCase();

    final year = productionDate.year.toString();
    final month = productionDate.month.toString().padLeft(2, '0');
    final day = productionDate.day.toString().padLeft(2, '0');
    return '$productPrefix$year$month$day';
  }

  /// 创建新批次
  factory Batch.create({
    required int productId,
    required DateTime productionDate,
    required int initialQuantity,
    required String shopId,
  }) {
    final now = DateTime.now();
    return Batch(
      batchNumber: generateBatchNumber(productId, productionDate),
      productId: productId,
      productionDate: productionDate,
      initialQuantity: initialQuantity,
      shopId: shopId,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 复制批次并更新指定字段
  Batch copyWith({
    String? batchNumber,
    int? productId,
    DateTime? productionDate,
    int? initialQuantity,
    String? shopId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Batch(
      batchNumber: batchNumber ?? this.batchNumber,
      productId: productId ?? this.productId,
      productionDate: productionDate ?? this.productionDate,
      initialQuantity: initialQuantity ?? this.initialQuantity,
      shopId: shopId ?? this.shopId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Batch(batchNumber: $batchNumber, productId: $productId, productionDate: $productionDate, initialQuantity: $initialQuantity, shopId: $shopId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Batch && other.batchNumber == batchNumber;
  }

  @override
  int get hashCode => batchNumber.hashCode;
}
