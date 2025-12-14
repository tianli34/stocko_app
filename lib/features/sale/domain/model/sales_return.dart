import 'package:freezed_annotation/freezed_annotation.dart';
import 'sales_return_item.dart';

part 'sales_return.freezed.dart';
part 'sales_return.g.dart';

/// 退货状态
enum SalesReturnStatus {
  pending,    // 待处理
  completed,  // 已完成
  cancelled,  // 已取消
}

/// 销售退货单领域模型
@freezed
abstract class SalesReturnModel with _$SalesReturnModel {
  const factory SalesReturnModel({
    int? id,
    required int salesTransactionId,
    int? customerId,
    required int shopId,
    required double totalAmount,
    @Default(SalesReturnStatus.pending) SalesReturnStatus status,
    String? reason,
    String? remarks,
    @Default(<SalesReturnItemModel>[]) List<SalesReturnItemModel> items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _SalesReturnModel;

  const SalesReturnModel._();

  factory SalesReturnModel.fromJson(Map<String, dynamic> json) =>
      _$SalesReturnModelFromJson(json);

  /// 状态显示名称
  String get statusDisplayName {
    switch (status) {
      case SalesReturnStatus.pending:
        return '待处理';
      case SalesReturnStatus.completed:
        return '已完成';
      case SalesReturnStatus.cancelled:
        return '已取消';
    }
  }

  /// 是否可以取消
  bool get canCancel => status == SalesReturnStatus.pending;

  /// 是否已完成
  bool get isCompleted => status == SalesReturnStatus.completed;
}
