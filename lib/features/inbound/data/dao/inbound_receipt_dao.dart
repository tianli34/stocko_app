import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/inbound_receipts_table.dart';

part 'inbound_receipt_dao.g.dart';

/// 入库单数据访问对象
/// 负责处理入库单表的数据库操作
@DriftAccessor(tables: [InboundReceiptsTable])
class InboundReceiptDao extends DatabaseAccessor<AppDatabase>
    with _$InboundReceiptDaoMixin {
  InboundReceiptDao(super.db);

  /// 插入入库单
  Future<int> insertInboundReceipt(
    InboundReceiptsTableCompanion receipt,
  ) async {
    return await into(inboundReceiptsTable).insert(receipt);
  }

  /// 根据ID获取入库单
  Future<InboundReceiptsTableData?> getInboundReceiptById(String id) {
    return (select(
      inboundReceiptsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 根据入库单号获取入库单
  Future<InboundReceiptsTableData?> getInboundReceiptByNumber(
    String receiptNumber,
  ) {
    return (select(
      inboundReceiptsTable,
    )..where((t) => t.receiptNumber.equals(receiptNumber))).getSingleOrNull();
  }

  /// 获取所有入库单
  Future<List<InboundReceiptsTableData>> getAllInboundReceipts() {
    return select(inboundReceiptsTable).get();
  }

  /// 根据店铺ID获取入库单
  Future<List<InboundReceiptsTableData>> getInboundReceiptsByShop(
    String shopId,
  ) {
    return (select(
      inboundReceiptsTable,
    )..where((t) => t.shopId.equals(shopId))).get();
  }

  /// 根据状态获取入库单
  Future<List<InboundReceiptsTableData>> getInboundReceiptsByStatus(
    String status,
  ) {
    return (select(
      inboundReceiptsTable,
    )..where((t) => t.status.equals(status))).get();
  }

  /// 监听所有入库单变化
  Stream<List<InboundReceiptsTableData>> watchAllInboundReceipts() {
    return select(inboundReceiptsTable).watch();
  }

  /// 监听指定店铺的入库单变化
  Stream<List<InboundReceiptsTableData>> watchInboundReceiptsByShop(
    String shopId,
  ) {
    return (select(
      inboundReceiptsTable,
    )..where((t) => t.shopId.equals(shopId))).watch();
  }

  /// 更新入库单
  Future<bool> updateInboundReceipt(
    InboundReceiptsTableCompanion receipt,
  ) async {
    final result = await (update(
      inboundReceiptsTable,
    )..where((t) => t.id.equals(receipt.id.value))).write(receipt);
    return result > 0;
  }

  /// 删除入库单
  Future<int> deleteInboundReceipt(String id) {
    return (delete(inboundReceiptsTable)..where((t) => t.id.equals(id))).go();
  }

  /// 生成新的入库单号
  /// 格式：RCT + YYYYMMDD + 4位序号
  Future<String> generateReceiptNumber(DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10).replaceAll('-', '');
    final prefix = 'RCT$dateStr';

    // 获取当天已有的入库单数量
    final count =
        await (selectOnly(inboundReceiptsTable)
              ..where(inboundReceiptsTable.receiptNumber.like('$prefix%'))
              ..addColumns([inboundReceiptsTable.id.count()]))
            .getSingle();

    final sequence = (count.read(inboundReceiptsTable.id.count()) ?? 0) + 1;
    final seqStr = sequence.toString().padLeft(4, '0');

    return '$prefix$seqStr';
  }

  /// 检查入库单号是否已存在
  Future<bool> isReceiptNumberExists(String receiptNumber) async {
    final result = await (select(
      inboundReceiptsTable,
    )..where((t) => t.receiptNumber.equals(receiptNumber))).getSingleOrNull();
    return result != null;
  }

  /// 获取入库单总数
  Future<int> getInboundReceiptCount() async {
    final result = await (selectOnly(
      inboundReceiptsTable,
    )..addColumns([inboundReceiptsTable.id.count()])).getSingle();
    return result.read(inboundReceiptsTable.id.count()) ?? 0;
  }

  /// 根据日期范围获取入库单
  Future<List<InboundReceiptsTableData>> getInboundReceiptsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return (select(
      inboundReceiptsTable,
    )..where((t) => t.createdAt.isBetweenValues(startDate, endDate))).get();
  }
}
