import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/inbound_receipt_items_table.dart';

part 'inbound_item_dao.g.dart';

/// 入库单明细数据访问对象
/// 负责处理入库单明细表的数据库操作
@DriftAccessor(tables: [InboundItem])
class InboundItemDao extends DatabaseAccessor<AppDatabase>
    with _$InboundItemDaoMixin {
  InboundItemDao(super.db);

  /// 插入入库单明细
  Future<int> insertInboundItem(InboundItemCompanion item) async {
    return await into(inboundItem).insert(item);
  }

  /// 批量插入入库单明细
  Future<void> insertMultipleInboundItems(
    List<InboundItemCompanion> items,
  ) async {
    await batch((batch) {
      batch.insertAll(inboundItem, items);
    });
  }

  /// 根据ID获取入库单明细
  Future<InboundItemData?> getInboundItemById(int id) {
    return (select(
      inboundItem,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 根据入库单ID获取所有明细
  Future<List<InboundItemData>> getInboundItemsByReceiptId(int receiptId) {
    return (select(
      inboundItem,
    )..where((t) => t.receiptId.equals(receiptId))).get();
  }

  /// 监听入库单明细变化
  Stream<List<InboundItemData>> watchInboundItemsByReceiptId(int receiptId) {
    return (select(
      inboundItem,
    )..where((t) => t.receiptId.equals(receiptId))).watch();
  }

  /// 更新入库单明细
  Future<bool> updateInboundItem(InboundItemCompanion item) async {
    final result = await (update(
      inboundItem,
    )..where((t) => t.id.equals(item.id.value))).write(item);
    return result > 0;
  }

  /// 删除入库单明细
  Future<int> deleteInboundItem(int id) {
    return (delete(inboundItem)..where((t) => t.id.equals(id))).go();
  }

  /// 删除入库单的所有明细
  Future<int> deleteInboundItemsByReceiptId(int receiptId) {
    return (delete(
      inboundItem,
    )..where((t) => t.receiptId.equals(receiptId))).go();
  }

  /// 根据商品ID获取入库明细
  Future<List<InboundItemData>> getInboundItemsByProductId(int productId) {
    return (select(
      inboundItem,
    )..where((t) => t.productId.equals(productId))).get();
  }

  /// 根据批次号获取入库明细
  Future<List<InboundItemData>> getInboundItemsByBatchNumber(int id) {
    return (select(
      inboundItem,
    )..where((t) => t.id.equals(id))).get();
  }

  /// 获取入库单明细总数
  Future<int> getInboundItemCount(int receiptId) async {
    final result =
        await (selectOnly(inboundItem)
              ..where(inboundItem.receiptId.equals(receiptId))
              ..addColumns([inboundItem.id.count()]))
            .getSingle();
    return result.read(inboundItem.id.count()) ?? 0;
  }

  /// 获取入库单总数量
  Future<double> getInboundTotalQuantity(int receiptId) async {
    final result =
        await (selectOnly(inboundItem)
              ..where(inboundItem.receiptId.equals(receiptId))
              ..addColumns([inboundItem.quantity.sum().cast<double>()]))
            .getSingle();
    return result.read(inboundItem.quantity.sum().cast<double>()) ?? 0.0;
  }

  /// 替换入库单明细（删除旧的，插入新的）
  Future<void> replaceInboundItems(
    int receiptId,
    List<InboundItemCompanion> items,
  ) async {
    await transaction(() async {
      // 删除现有明细
      await deleteInboundItemsByReceiptId(receiptId);
      // 插入新明细
      if (items.isNotEmpty) {
        await insertMultipleInboundItems(items);
      }
    });
  }
}
