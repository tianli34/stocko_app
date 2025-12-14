import 'package:freezed_annotation/freezed_annotation.dart';

part 'stocktake_item.freezed.dart';
part 'stocktake_item.g.dart';

/// 盘点明细领域模型
@freezed
abstract class StocktakeItemModel with _$StocktakeItemModel {
  const factory StocktakeItemModel({
    int? id,
    required int stocktakeId,
    required int productId,
    int? batchId,
    required int systemQuantity,
    required int actualQuantity,
    @Default(0) int differenceQty,
    String? differenceReason,
    @Default(false) bool isAdjusted,
    DateTime? scannedAt,
    // 关联数据（用于展示）
    String? productName,
    String? productImage,
    String? unitName,
    String? batchNumber,
    DateTime? productionDate,
  }) = _StocktakeItemModel;

  const StocktakeItemModel._();

  factory StocktakeItemModel.fromJson(Map<String, dynamic> json) =>
      _$StocktakeItemModelFromJson(json);

  /// 创建新盘点项
  factory StocktakeItemModel.create({
    required int stocktakeId,
    required int productId,
    required int systemQuantity,
    required int actualQuantity,
    int? batchId,
  }) {
    return StocktakeItemModel(
      stocktakeId: stocktakeId,
      productId: productId,
      batchId: batchId,
      systemQuantity: systemQuantity,
      actualQuantity: actualQuantity,
      differenceQty: actualQuantity - systemQuantity,
      scannedAt: DateTime.now(),
    );
  }

  /// 是否有差异
  bool get hasDifference => differenceQty != 0;

  /// 是否盘盈
  bool get isOverage => differenceQty > 0;

  /// 是否盘亏
  bool get isShortage => differenceQty < 0;

  /// 更新实盘数量
  StocktakeItemModel updateActualQuantity(int quantity) {
    return copyWith(
      actualQuantity: quantity,
      differenceQty: quantity - systemQuantity,
    );
  }

  /// 设置差异原因
  StocktakeItemModel setDifferenceReason(String reason) {
    return copyWith(differenceReason: reason);
  }

  /// 标记为已调整
  StocktakeItemModel markAsAdjusted() {
    return copyWith(isAdjusted: true);
  }
}

/// 盘点汇总
@freezed
abstract class StocktakeSummary with _$StocktakeSummary {
  const factory StocktakeSummary({
    required int totalItems,
    required int checkedItems,
    required int diffItems,
    required int overageItems,
    required int shortageItems,
    required int totalOverageQty,
    required int totalShortageQty,
  }) = _StocktakeSummary;

  const StocktakeSummary._();

  factory StocktakeSummary.fromJson(Map<String, dynamic> json) =>
      _$StocktakeSummaryFromJson(json);

  /// 空汇总
  factory StocktakeSummary.empty() => const StocktakeSummary(
        totalItems: 0,
        checkedItems: 0,
        diffItems: 0,
        overageItems: 0,
        shortageItems: 0,
        totalOverageQty: 0,
        totalShortageQty: 0,
      );

  /// 完成率
  double get completionRate =>
      totalItems > 0 ? checkedItems / totalItems : 0.0;

  /// 差异率
  double get diffRate => checkedItems > 0 ? diffItems / checkedItems : 0.0;
}
