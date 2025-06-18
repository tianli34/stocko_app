import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/inbound_receipt_items_table.dart';

part 'inbound_item_dao.g.dart';

/// 入库单明细数据访问对象
/// 负责处理入库单明细表的数据库操作
@DriftAccessor(tables: [InboundReceiptItemsTable])
class InboundItemDao extends DatabaseAccessor<AppDatabase>
    with _$InboundItemDaoMixin {
  InboundItemDao(super.db);

  /// 插入入库单明细
  Future<int> insertInboundItem(InboundReceiptItemsTableCompanion item) async {
    return await into(inboundReceiptItemsTable).insert(item);
  }

  /// 批量插入入库单明细
  Future<void> insertMultipleInboundItems(
    List<InboundReceiptItemsTableCompanion> items,
  ) async {
    await batch((batch) {
      batch.insertAll(inboundReceiptItemsTable, items);
    });
  }

  /// 根据ID获取入库单明细
  Future<InboundReceiptItemsTableData?> getInboundItemById(String id) {
    return (select(
      inboundReceiptItemsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 根据入库单ID获取所有明细
  Future<List<InboundReceiptItemsTableData>> getInboundItemsByReceiptId(
    String receiptId,
  ) {
    return (select(
      inboundReceiptItemsTable,
    )..where((t) => t.receiptId.equals(receiptId))).get();
  }

  /// 监听入库单明细变化
  Stream<List<InboundReceiptItemsTableData>> watchInboundItemsByReceiptId(
    String receiptId,
  ) {
    return (select(
      inboundReceiptItemsTable,
    )..where((t) => t.receiptId.equals(receiptId))).watch();
  }

  /// 更新入库单明细
  Future<bool> updateInboundItem(InboundReceiptItemsTableCompanion item) async {
    final result = await (update(
      inboundReceiptItemsTable,
    )..where((t) => t.id.equals(item.id.value))).write(item);
    return result > 0;
  }

  /// 删除入库单明细
  Future<int> deleteInboundItem(String id) {
    return (delete(
      inboundReceiptItemsTable,
    )..where((t) => t.id.equals(id))).go();
  }

  /// 删除入库单的所有明细
  Future<int> deleteInboundItemsByReceiptId(String receiptId) {
    return (delete(
      inboundReceiptItemsTable,
    )..where((t) => t.receiptId.equals(receiptId))).go();
  }

  /// 根据商品ID获取入库明细
  Future<List<InboundReceiptItemsTableData>> getInboundItemsByProductId(
    String productId,
  ) {
    return (select(
      inboundReceiptItemsTable,
    )..where((t) => t.productId.equals(productId))).get();
  }

  /// 根据批次号获取入库明细
  Future<List<InboundReceiptItemsTableData>> getInboundItemsByBatchNumber(
    String batchNumber,
  ) {
    return (select(
      inboundReceiptItemsTable,
    )..where((t) => t.batchNumber.equals(batchNumber))).get();
  }

  /// 根据货位ID获取入库明细
  Future<List<InboundReceiptItemsTableData>> getInboundItemsByLocationId(
    String locationId,
  ) {
    return (select(
      inboundReceiptItemsTable,
    )..where((t) => t.locationId.equals(locationId))).get();
  }

  /// 获取入库单明细总数
  Future<int> getInboundItemCount(String receiptId) async {
    final result =
        await (selectOnly(inboundReceiptItemsTable)
              ..where(inboundReceiptItemsTable.receiptId.equals(receiptId))
              ..addColumns([inboundReceiptItemsTable.id.count()]))
            .getSingle();
    return result.read(inboundReceiptItemsTable.id.count()) ?? 0;
  }

  /// 获取入库单总数量
  Future<double> getInboundTotalQuantity(String receiptId) async {
    final result =
        await (selectOnly(inboundReceiptItemsTable)
              ..where(inboundReceiptItemsTable.receiptId.equals(receiptId))
              ..addColumns([inboundReceiptItemsTable.quantity.sum()]))
            .getSingle();
    return result.read(inboundReceiptItemsTable.quantity.sum()) ?? 0.0;
  }

  /// 替换入库单明细（删除旧的，插入新的）
  Future<void> replaceInboundItems(
    String receiptId,
    List<InboundReceiptItemsTableCompanion> items,
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
