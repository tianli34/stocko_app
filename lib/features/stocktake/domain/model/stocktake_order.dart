import 'package:freezed_annotation/freezed_annotation.dart';
import 'stocktake_status.dart';

part 'stocktake_order.freezed.dart';
part 'stocktake_order.g.dart';

/// 盘点单领域模型
@freezed
abstract class StocktakeOrderModel with _$StocktakeOrderModel {
  const factory StocktakeOrderModel({
    int? id,
    required String orderNumber,
    required int shopId,
    required StocktakeType type,
    @Default(StocktakeStatus.draft) StocktakeStatus status,
    int? categoryId,
    String? remarks,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? auditedAt,
    // 关联数据（用于展示）
    String? shopName,
    String? categoryName,
    int? itemCount,
    int? diffCount,
  }) = _StocktakeOrderModel;

  const StocktakeOrderModel._();

  factory StocktakeOrderModel.fromJson(Map<String, dynamic> json) =>
      _$StocktakeOrderModelFromJson(json);

  /// 创建新盘点单
  factory StocktakeOrderModel.create({
    required int shopId,
    required StocktakeType type,
    int? categoryId,
    String? remarks,
  }) {
    final now = DateTime.now();
    final orderNumber = 'PD${now.millisecondsSinceEpoch}';
    return StocktakeOrderModel(
      orderNumber: orderNumber,
      shopId: shopId,
      type: type,
      status: StocktakeStatus.draft,
      categoryId: categoryId,
      remarks: remarks,
      createdAt: now,
    );
  }

  /// 是否可编辑
  bool get isEditable =>
      status == StocktakeStatus.draft || status == StocktakeStatus.inProgress;

  /// 是否可完成
  bool get canComplete => status == StocktakeStatus.inProgress;

  /// 是否可审核
  bool get canAudit => status == StocktakeStatus.completed;

  /// 开始盘点
  StocktakeOrderModel start() {
    return copyWith(status: StocktakeStatus.inProgress);
  }

  /// 完成盘点
  StocktakeOrderModel complete() {
    return copyWith(
      status: StocktakeStatus.completed,
      completedAt: DateTime.now(),
    );
  }

  /// 审核通过
  StocktakeOrderModel audit() {
    return copyWith(
      status: StocktakeStatus.audited,
      auditedAt: DateTime.now(),
    );
  }
}
