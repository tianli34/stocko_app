/// 入库单明细 领域模型（freezed）
/// 对应表: InboundItem (lib/core/database/inbound_receipt_items_table.dart)
library;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'inbound_item.freezed.dart';
part 'inbound_item.g.dart';

@freezed
abstract class InboundItemModel with _$InboundItemModel {
  const InboundItemModel._();

  @Assert('quantity > 0', 'quantity must be > 0')
  const factory InboundItemModel({
    /// 可能尚未持久化，因而为可空
    int? id,

    /// 所属入库单ID（新建时可能为空，保存后回填）
    int? receiptId,

    /// 商品ID（必填）
    required int productId,



    /// 批次号（可空，空批次与有批次的唯一性策略不同）
    int? batchId,

    /// 数量（> 0）
    required int quantity,
  }) = _InboundItemModel;

  factory InboundItemModel.fromJson(Map<String, dynamic> json) =>
      _$InboundItemModelFromJson(json);

  /// 生成用于判定同一入库单中的“唯一性键”
  /// 唯一性与表约束一致：
  /// - 当 id 非空：唯一键 = (receiptId, productId, unitId, id)
  /// - 当 id 为空：唯一键 = (receiptId, productId, unitId, null)
  String uniqueKey({int? overrideReceiptId}) {
    final rid = overrideReceiptId ?? receiptId;
    return '${rid ?? 'null'}#$productId#${id ?? 'null'}';
  }

  /// 增加数量，返回新实例
  InboundItemModel increase(int delta) {
    assert(delta > 0, 'delta must be > 0');
  return copyWith(quantity: quantity + delta);
  }

  /// 设置/回填所属入库单ID
  InboundItemModel attachToReceipt(int rid) => copyWith(receiptId: rid);
}
