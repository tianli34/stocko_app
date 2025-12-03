import 'package:freezed_annotation/freezed_annotation.dart';

part 'aggregated_inventory.freezed.dart';
part 'aggregated_inventory.g.dart';

/// 聚合后的库存项
/// 用于在未筛选店铺时展示同一货品的汇总信息
@freezed
abstract class AggregatedInventoryItem with _$AggregatedInventoryItem {
  const factory AggregatedInventoryItem({
    required int productId,
    required String productName,
    String? productImage,
    required int totalQuantity,
    required String unit,
    int? categoryId,
    required String categoryName,
    required List<InventoryDetail> details,
    required double totalValue, // 总价值（元）
  }) = _AggregatedInventoryItem;

  const AggregatedInventoryItem._();

  factory AggregatedInventoryItem.fromJson(Map<String, dynamic> json) =>
      _$AggregatedInventoryItemFromJson(json);

  /// 从原始库存数据列表创建聚合项
  ///
  /// [inventoryItems] 相同货品的所有库存记录
  factory AggregatedInventoryItem.fromInventoryList(
    List<Map<String, dynamic>> inventoryItems,
  ) {
    if (inventoryItems.isEmpty) {
      throw ArgumentError('库存列表不能为空');
    }

    final firstItem = inventoryItems.first;

    // 计算总库存数量
    final totalQuantity = inventoryItems.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int? ?? 0),
    );

    // 计算总价值（数量 × 进货价格，价格从丝转换为元，1元 = 100,000丝）
    final totalValue = inventoryItems.fold<double>(
      0,
      (sum, item) =>
          sum +
          (item['quantity'] as num? ?? 0) *
              (item['purchasePrice'] as num? ?? 0) /
              100000,
    );

    // 构建详细记录列表
    final details = inventoryItems
        .map((item) => InventoryDetail.fromMap(item))
        .toList();

    return AggregatedInventoryItem(
      productId: firstItem['productId'] as int,
      productName: firstItem['productName'] as String,
      productImage: firstItem['productImage'] as String?,
      totalQuantity: totalQuantity,
      unit: firstItem['unit'] as String? ?? '个',
      categoryId: firstItem['categoryId'] as int?,
      categoryName: firstItem['categoryName'] as String? ?? '未分类',
      details: details,
      totalValue: totalValue,
    );
  }

  /// 获取最短剩余保质期（天数）
  /// 如果没有保质期信息，返回null
  int? get minRemainingDays {
    final daysWithShelfLife = details
        .where((d) => d.remainingDays != null)
        .map((d) => d.remainingDays!)
        .toList();

    if (daysWithShelfLife.isEmpty) return null;

    return daysWithShelfLife.reduce((a, b) => a < b ? a : b);
  }

  /// 是否有即将过期的批次（剩余保质期 <= 30天）
  bool get hasExpiringSoon {
    final minDays = minRemainingDays;
    return minDays != null && minDays <= 30;
  }

  /// 是否有已过期的批次
  bool get hasExpired {
    final minDays = minRemainingDays;
    return minDays != null && minDays <= 0;
  }

  /// 是否可展开（判断是否有多条记录）
  /// 仅当有2条或以上记录时才需要展开/收起功能
  bool get isExpandable => details.length > 1;
}

/// 库存详细信息
/// 表示单个店铺-批次组合的库存记录
@freezed
abstract class InventoryDetail with _$InventoryDetail {
  const factory InventoryDetail({
    required int stockId,
    required int shopId,
    required String shopName,
    required int quantity,
    int? batchId,
    String? batchNumber,
    DateTime? productionDate,
    int? shelfLifeDays,
    String? shelfLifeUnit,
    int? remainingDays,
    int? purchasePrice, // 进货价格（分）
  }) = _InventoryDetail;

  const InventoryDetail._();

  factory InventoryDetail.fromJson(Map<String, dynamic> json) =>
      _$InventoryDetailFromJson(json);

  /// 从原始库存数据Map创建详细记录
  factory InventoryDetail.fromMap(Map<String, dynamic> map) {
    // 计算剩余保质期天数
    int? remainingDays;
    if (map['productionDate'] != null && map['shelfLifeDays'] != null) {
      try {
        final productionDate = map['productionDate'] is String
            ? DateTime.parse(map['productionDate'] as String)
            : map['productionDate'] as DateTime;

        final shelfLifeValue = map['shelfLifeDays'] as int;
        final shelfLifeUnit = map['shelfLifeUnit'] as String?;
        
        // 根据单位将保质期转换为天数
        int shelfLifeInDays;
        if (shelfLifeUnit == 'years') {
          shelfLifeInDays = shelfLifeValue * 365;
        } else if (shelfLifeUnit == 'months') {
          shelfLifeInDays = shelfLifeValue * 30;
        } else {
          // 默认为天
          shelfLifeInDays = shelfLifeValue;
        }
        
        final expiryDate = productionDate.add(Duration(days: shelfLifeInDays));

        // 计算剩余天数：将当前日期和过期日期都归零到午夜，然后计算天数差
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final expiry = DateTime(
          expiryDate.year,
          expiryDate.month,
          expiryDate.day,
        );
        remainingDays = expiry.difference(today).inDays;
      } catch (e) {
        // 如果日期解析失败，保持为null
        remainingDays = null;
      }
    }

    return InventoryDetail(
      stockId: map['id'] as int,
      shopId: map['shopId'] as int,
      shopName: map['shopName'] as String? ?? '未知店铺',
      quantity: map['quantity'] as int? ?? 0,
      batchId: map['batchNumber'] as int?,
      batchNumber: map['batchNumber']?.toString(),
      productionDate: map['productionDate'] != null
          ? (map['productionDate'] is String
                ? DateTime.tryParse(map['productionDate'] as String)
                : map['productionDate'] as DateTime?)
          : null,
      shelfLifeDays: map['shelfLifeDays'] as int?,
      shelfLifeUnit: map['shelfLifeUnit'] as String?,
      remainingDays: remainingDays,
      purchasePrice: map['purchasePrice'] as int?,
    );
  }

  /// 获取生产日期显示文本
  String get batchDisplayText {
    if (productionDate != null) {
      return _formatDate(productionDate!);
    }
    return '-';
  }

  /// 获取剩余保质期显示文本
  String get remainingDaysDisplayText {
    if (remainingDays == null) return '-';

    if (remainingDays! < 0) {
      return '已过期${-remainingDays!}天';
    } else if (remainingDays! == 0) {
      return '今天过期';
    } else {
      return '剩余$remainingDays天';
    }
  }

  /// 获取保质期状态颜色
  /// 返回颜色代码：red(已过期), orange(7天内), yellow(30天内), green(正常)
  String get shelfLifeColorStatus {
    if (remainingDays == null) return 'normal';

    if (remainingDays! <= 0) {
      return 'expired'; // 红色
    } else if (remainingDays! <= 7) {
      return 'critical'; // 橙色
    } else if (remainingDays! <= 30) {
      return 'warning'; // 黄色
    } else {
      return 'normal'; // 绿色/正常
    }
  }

  /// 是否即将过期（30天内）
  bool get isExpiringSoon {
    return remainingDays != null && remainingDays! > 0 && remainingDays! <= 30;
  }

  /// 是否已过期
  bool get isExpired {
    return remainingDays != null && remainingDays! <= 0;
  }

  /// 格式化日期为 yyyy-MM-dd
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
