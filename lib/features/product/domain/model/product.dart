import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

@freezed
abstract class Product with _$Product {
  const factory Product({
    required String id, // ID现在是必需的
    required String name, // 名称必须
    String? sku,
    String? image, // 图片
    String? categoryId, // 类别ID (关联分类表)
    String? unitId, // 单位ID (关联单位表)
    String? specification, // 型号/规格
    String? brand, // 品牌
    double? suggestedRetailPrice, // 建议零售价
    double? retailPrice, // 零售价
    double? promotionalPrice, // 促销价
    int? stockWarningValue, // 库存预警值
    int? shelfLife, // 保质期(天数) - 修复：添加了缺失的换行符
    @Default('months') String shelfLifeUnit, // 保质期单位 (days, months, years)
    @Default(false) bool enableBatchManagement, // 批量管理开关，默认为false
    @Default('active') String status, // 状态，默认为 'active'
    String? remarks, // 备注
    DateTime? lastUpdated, // 最后更新日期
  }) = _Product;

  const Product._();

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);

  // 获取有效价格（促销价 > 零售价 > 建议零售价）
  double? get effectivePrice {
    return promotionalPrice ?? retailPrice ?? suggestedRetailPrice;
  }

  // 是否有促销价
  bool get hasPromotionalPrice => promotionalPrice != null;

  // 是否需要库存预警
  bool isStockWarning(int currentStock) {
    return stockWarningValue != null && currentStock <= stockWarningValue!;
  }

  // 是否有效（状态为活跃）
  bool get isActive => status == 'active';

  // 是否已过期（如果有保质期）
  bool get isExpired {
    if (shelfLife == null || lastUpdated == null) return false;

    Duration duration;
    switch (shelfLifeUnit.toLowerCase()) {
      case 'days':
        duration = Duration(days: shelfLife!);
        break;
      case 'months':
        duration = Duration(days: shelfLife! * 30); // 近似计算
        break;
      case 'years':
        duration = Duration(days: shelfLife! * 365); // 近似计算
        break;
      default:
        duration = Duration(days: shelfLife!);
    }

    final expiryDate = lastUpdated!.add(duration);
    return DateTime.now().isAfter(expiryDate);
  }

  // 获取格式化的价格显示
  String get formattedPrice {
    final price = effectivePrice;
    if (price == null) return '价格待定';
    return '¥${price.toStringAsFixed(2)}';
  }

  // 复制并更新最后更新时间
  Product updateTimestamp() {
    return copyWith(lastUpdated: DateTime.now());
  }
}
