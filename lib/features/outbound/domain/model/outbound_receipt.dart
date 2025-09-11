/// 出库单 领域模型（freezed）
/// 对应表: OutboundReceipt (lib/core/database/outbound_receipts_table.dart)
library;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'outbound_item.dart';

part 'outbound_receipt.freezed.dart';
part 'outbound_receipt.g.dart';

@freezed
abstract class OutboundReceiptModel with _$OutboundReceiptModel {
  const OutboundReceiptModel._();

  const factory OutboundReceiptModel({
    /// 主键（草稿阶段可能为空）
    int? id,

    /// 店铺ID（必填）
    required int shopId,

    /// 原因（如：销售出库、调拨、报损等）
    required String reason,

    /// 关联销售单ID（可空）
    int? salesTransactionId,

    /// 创建时间
    required DateTime createdAt,

    /// 备注（领域层可选）
    String? remarks,

    /// 明细列表（仅领域层维护，不对应表字段）
    @Default(<OutboundItemModel>[]) List<OutboundItemModel> items,
  }) = _OutboundReceiptModel;

  factory OutboundReceiptModel.fromJson(Map<String, dynamic> json) =>
      _$OutboundReceiptModelFromJson(json);

  /// 工厂方法：创建新的出库单草稿
  factory OutboundReceiptModel.createDraft({
    required int shopId,
    required String reason,
    int? salesTransactionId,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    return OutboundReceiptModel(
      shopId: shopId,
      reason: reason,
      salesTransactionId: salesTransactionId,
      createdAt: t,
      items: const [],
    );
  }

  /// 合并或新增一条明细（遵循表的唯一性策略）
  OutboundReceiptModel upsertItem(OutboundItemModel item) {
    final map = <String, OutboundItemModel>{
      for (final it in items) it.uniqueKey(overrideReceiptId: id): it
    };
    final key = item.uniqueKey(overrideReceiptId: id);
    if (map.containsKey(key)) {
      map[key] = map[key]!.increase(item.quantity);
    } else {
      map[key] = item;
    }
    return copyWith(items: map.values.toList(growable: false));
  }

  /// 移除一条明细（按唯一键）
  OutboundReceiptModel removeItem(OutboundItemModel item) {
    final key = item.uniqueKey(overrideReceiptId: id);
    final next = items
        .where((e) => e.uniqueKey(overrideReceiptId: id) != key)
        .toList();
    return copyWith(items: next);
  }

  /// 更新某条明细（按唯一键定位）
  OutboundReceiptModel updateItem(OutboundItemModel item) {
    final key = item.uniqueKey(overrideReceiptId: id);
    final next = items
        .map((e) => e.uniqueKey(overrideReceiptId: id) == key ? item : e)
        .toList();
    return copyWith(items: next);
  }

  int get totalQuantity => items.fold(0, (sum, it) => sum + it.quantity);

  @override
  String toString() =>
      'OutboundReceiptModel(id: \'${id?.toString() ?? 'null'}\', shopId: $shopId, reason: $reason, items: ${items.length})';
}
