/// 批次模型
/// 用于批次管理功能的数据模型
class BatchModel {
  /// 主键 - 批次号，无业务意义
  final int? id;
  final int productId;
  /// 仅使用到“日期”粒度（00:00:00），避免时间部分影响唯一性
  final DateTime productionDate;
  final int totalInboundQuantity;
  final int shopId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BatchModel({
    this.id,
    required this.productId,
    required this.productionDate,
    required this.totalInboundQuantity,
    required this.shopId,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(totalInboundQuantity >= 0, 'totalInboundQuantity 不能为负数');

  /// 创建新批次
  factory BatchModel.create({
    required int productId,
    required DateTime productionDate,
    required int totalInboundQuantity,
    required int shopId,
  }) {
    final now = DateTime.now().toUtc();
    return BatchModel(
      productId: productId,
      productionDate: _dateOnlyUtc(productionDate),
      totalInboundQuantity: totalInboundQuantity,
      shopId: shopId,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 复制批次并更新指定字段
  BatchModel copyWith({
    int? id,
    int? productId,
    DateTime? productionDate,
    int? totalInboundQuantity,
    int? shopId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BatchModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productionDate: productionDate != null
          ? _dateOnlyUtc(productionDate)
          : this.productionDate,
      totalInboundQuantity: totalInboundQuantity ?? this.totalInboundQuantity,
      shopId: shopId ?? this.shopId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// JSON 序列化
  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'productionDate': productionDate.toIso8601String(),
        'totalInboundQuantity': totalInboundQuantity,
        'shopId': shopId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory BatchModel.fromJson(Map<String, dynamic> json) => BatchModel(
        id: json['id'] as int?,
        productId: json['productId'] as int,
        productionDate: _dateOnlyUtc(DateTime.parse(json['productionDate'] as String)),
        totalInboundQuantity: json['totalInboundQuantity'] as int,
        shopId: json['shopId'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  @override
  String toString() {
    return 'Batch(id: $id, productId: $productId, productionDate: $productionDate, totalInboundQuantity: $totalInboundQuantity, shopId: $shopId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BatchModel) return false;

    // 若双方均有主键，则以主键判等
    if (id != null && other.id != null) {
      return id == other.id;
    }

    // 否则使用业务唯一键（产品+日期+店铺）判等
    return productId == other.productId &&
        _sameDate(productionDate, other.productionDate) &&
        shopId == other.shopId;
  }

  @override
  int get hashCode {
    if (id != null) return id.hashCode;
    // 业务键哈希：确保与 == 一致
    final d = productionDate.toUtc();
    final dateOnly = DateTime.utc(d.year, d.month, d.day);
    return Object.hash(productId, dateOnly.millisecondsSinceEpoch, shopId);
  }

  // 将任意时间标准化为 UTC 的“日期 00:00:00”
  static DateTime _dateOnlyUtc(DateTime dt) {
    final u = dt.toUtc();
    return DateTime.utc(u.year, u.month, u.day);
  }

  static bool _sameDate(DateTime a, DateTime b) {
    final ua = a.toUtc();
    final ub = b.toUtc();
    return ua.year == ub.year && ua.month == ub.month && ua.day == ub.day;
  }
}
