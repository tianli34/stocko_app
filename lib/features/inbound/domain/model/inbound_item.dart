/// 入库单明细领域模型
/// 表示入库单中的商品明细信息
class InboundItem {
  final String id;
  final String receiptId;
  final String productId;
  final String productName;
  final String productSpec; // 规格，如"红色S码"
  final String? productImage;
  final double quantity; // 本次入库数量
  /// 入库数量的别名，用于兼容 UI 代码
  double get inboundQuantity => quantity;

  final String unitId; // 入库单位ID
  final DateTime? productionDate; // 生产日期

  /// 是否要求生产日期（根据商品类型判断）
  bool get requiresProductionDate => productionDate != null;
  final String? locationId; // 入库位置ID
  final String? locationName; // 入库位置名称
  final double? purchaseQuantity; // 采购数量
  final String? purchaseOrderId; // 采购单ID
  final String? batchNumber; // 批次号
  final DateTime createdAt;
  final DateTime updatedAt;

  const InboundItem({
    required this.id,
    required this.receiptId,
    required this.productId,
    required this.productName,
    required this.productSpec,
    this.productImage,
    required this.quantity,
    required this.unitId,
    this.productionDate,
    this.locationId,
    this.locationName,
    this.purchaseQuantity,
    this.purchaseOrderId,
    this.batchNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 复制并更新入库单明细
  InboundItem copyWith({
    String? id,
    String? receiptId,
    String? productId,
    String? productName,
    String? productSpec,
    String? productImage,
    double? quantity,
    String? unitId,
    DateTime? productionDate,
    String? locationId,
    String? locationName,
    double? purchaseQuantity,
    String? purchaseOrderId,
    String? batchNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InboundItem(
      id: id ?? this.id,
      receiptId: receiptId ?? this.receiptId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSpec: productSpec ?? this.productSpec,
      productImage: productImage ?? this.productImage,
      quantity: quantity ?? this.quantity,
      unitId: unitId ?? this.unitId,
      productionDate: productionDate ?? this.productionDate,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      purchaseQuantity: purchaseQuantity ?? this.purchaseQuantity,
      purchaseOrderId: purchaseOrderId ?? this.purchaseOrderId,
      batchNumber: batchNumber ?? this.batchNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 是否有生产日期
  bool get hasProductionDate => productionDate != null;

  /// 是否有货位
  bool get hasLocation => locationId != null && locationId!.isNotEmpty;

  /// 是否有采购单关联
  bool get hasPurchaseOrder =>
      purchaseOrderId != null && purchaseOrderId!.isNotEmpty;

  /// 是否有批次号
  bool get hasBatch => batchNumber != null && batchNumber!.isNotEmpty;

  /// 采购数量与入库数量的差异
  double get quantityDifference {
    if (purchaseQuantity == null) return 0.0;
    return quantity - purchaseQuantity!;
  }

  /// 是否完全入库（入库数量等于采购数量）
  bool get isFullyReceived {
    if (purchaseQuantity == null) return true;
    return quantity >= purchaseQuantity!;
  }

  /// 创建新的入库单明细
  factory InboundItem.create({
    required String receiptId,
    required String productId,
    required String productName,
    required String productSpec,
    String? productImage,
    required double quantity,
    required String unitId,
    DateTime? productionDate,
    String? locationId,
    String? locationName,
    double? purchaseQuantity,
    String? purchaseOrderId,
  }) {
    final now = DateTime.now();
    return InboundItem(
      id: 'item_${now.millisecondsSinceEpoch}',
      receiptId: receiptId,
      productId: productId,
      productName: productName,
      productSpec: productSpec,
      productImage: productImage,
      quantity: quantity,
      unitId: unitId,
      productionDate: productionDate,
      locationId: locationId,
      locationName: locationName,
      purchaseQuantity: purchaseQuantity,
      purchaseOrderId: purchaseOrderId,
      createdAt: now,
      updatedAt: now,
    );
  }
}
