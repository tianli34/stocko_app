/// 出库单明细 领域模型（freezed）
/// 对应表: OutboundItem (lib/core/database/outbound_receipt_items_table.dart)
library;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'outbound_item.freezed.dart';
part 'outbound_item.g.dart';

@freezed
abstract class OutboundItemModel with _$OutboundItemModel {
  const OutboundItemModel._();

  @Assert('quantity > 0', 'quantity must be > 0')
  const factory OutboundItemModel({
    /// 可能尚未持久化，因而为可空
    int? id,

    /// 所属出库单ID（新建时可能为空，保存后回填）
    int? receiptId,

    /// 产品单位ID（必填）
    required int unitProductId,

    /// 批次号（可空，空批次与有批次的唯一性策略不同）
    int? batchId,

    /// 数量（> 0）
    required int quantity,
  }) = _OutboundItemModel;

  factory OutboundItemModel.fromJson(Map<String, dynamic> json) =>
      _$OutboundItemModelFromJson(json);

  /// 生成用于判定同一出库单中的“唯一性键”
  /// 与表约束一致：
  /// - 当 batchId 非空：唯一键 = (receiptId, unitProductId, batchId)
  /// - 当 batchId 为空：唯一键 = (receiptId, unitProductId)
  String uniqueKey({int? overrideReceiptId}) {
    final rid = overrideReceiptId ?? receiptId;
    final batchKey = batchId?.toString() ?? 'null';
    return '${rid ?? 'null'}#$unitProductId#$batchKey';
  }

  /// 增加数量，返回新实例
  OutboundItemModel increase(int delta) {
    assert(delta > 0, 'delta must be > 0');
    return copyWith(quantity: quantity + delta);
  }

  /// 设置/回填所属出库单ID
  OutboundItemModel attachToReceipt(int rid) => copyWith(receiptId: rid);
}
