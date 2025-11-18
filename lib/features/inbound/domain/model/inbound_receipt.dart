/// 入库单 领域模型（freezed）
/// 对应表: InboundReceipt (lib/core/database/inbound_receipts_table.dart)
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'inbound_item.dart';

part 'inbound_receipt.freezed.dart';
// part 'inbound_receipt.g.dart';

@freezed
abstract class InboundReceiptModel with _$InboundReceiptModel {
  const InboundReceiptModel._();

  const factory InboundReceiptModel({
    /// 主键（草稿阶段可能为空）
    int? id,

    /// 店铺ID（必填）
    required int shopId,

    /// 来源（如: 手工、新建、来自采购单等）
    required String source,

    /// 关联采购单ID（可空）
    int? purchaseOrderId,

    /// 状态：preset, draft, completed
    @Default(InboundReceiptStatus.preset) String status,

    /// 备注
    String? remarks,

    /// 创建/更新时间
    required DateTime createdAt,
    required DateTime updatedAt,

    /// 明细列表（仅领域层维护，不对应表字段）
    @Default(<InboundItemModel>[]) List<InboundItemModel> items,
  }) = _InboundReceiptModel;

  // JSON serialization is handled by freezed's .freezed.dart file
  // Uncomment the .g.dart part directive above if you need custom JSON serialization

  /// 状态辅助
  bool get isPreset => status == InboundReceiptStatus.preset;
  bool get isDraft => status == InboundReceiptStatus.draft;
  bool get isCompleted => status == InboundReceiptStatus.completed;

  /// 工厂方法：创建空草稿
  factory InboundReceiptModel.createDraft({
    required int shopId,
    required String source,
    int? purchaseOrderId,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    return InboundReceiptModel(
      shopId: shopId,
      source: source,
      purchaseOrderId: purchaseOrderId,
      status: InboundReceiptStatus.preset,
      createdAt: t,
      updatedAt: t,
      items: const [],
    );
  }

  /// 添加或合并明细（遵循表的唯一性约束）
  InboundReceiptModel upsertItem(InboundItemModel item) {
    final map = <String, InboundItemModel>{
      for (final it in items) it.uniqueKey(overrideReceiptId: id): it,
    };
    final key = item.uniqueKey(overrideReceiptId: id);
    if (map.containsKey(key)) {
      map[key] = map[key]!.increase(item.quantity);
    } else {
      map[key] = item;
    }
    return copyWith(items: map.values.toList(growable: false));
  }

  /// 移除明细（按唯一性键）
  InboundReceiptModel removeItem(InboundItemModel item) {
    final key = item.uniqueKey(overrideReceiptId: id);
    final next = items
        .where((e) => e.uniqueKey(overrideReceiptId: id) != key)
        .toList();
    return copyWith(items: next);
  }

  /// 更新某条明细（按唯一性键定位）
  InboundReceiptModel updateItem(InboundItemModel item) {
    final key = item.uniqueKey(overrideReceiptId: id);
    final next = items
        .map((e) => e.uniqueKey(overrideReceiptId: id) == key ? item : e)
        .toList();
    return copyWith(items: next);
  }

  int get totalQuantity => items.fold(0, (sum, it) => sum + it.quantity);

  @override
  String toString() =>
      'InboundReceiptModel(id: ${id?.toString() ?? 'null'}, shopId: $shopId, status: $status, items: ${items.length})';
}

/// 状态常量集中定义，避免硬编码
class InboundReceiptStatus {
  static const String preset = 'preset';
  static const String draft = 'draft';
  static const String completed = 'completed';
}


