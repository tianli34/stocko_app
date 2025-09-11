import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/inbound_receipts_table.dart';

part 'inbound_receipt_dao.g.dart';

/// 入库单数据访问对象
/// 负责处理入库单表的数据库操作
@DriftAccessor(tables: [InboundReceipt])
class InboundReceiptDao extends DatabaseAccessor<AppDatabase>
    with _$InboundReceiptDaoMixin {
  InboundReceiptDao(super.db);

  /// 插入入库单
  Future<int> insertInboundReceipt(InboundReceiptCompanion receipt) async {
    return await into(inboundReceipt).insert(receipt);
  }

  /// 根据ID获取入库单
  Future<InboundReceiptData?> getInboundReceiptById(int id) {
    return (select(
      inboundReceipt,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  // /// 根据入库单号获取入库单
  // Future<InboundReceiptData?> getInboundReceiptByNumber(
  //   String receiptNumber,
  // ) {
  //   return (select(
  //     inboundReceipt,
  //   )..where((t) => t.receiptNumber.equals(receiptNumber))).getSingleOrNull();
  // }

  /// 获取所有入库单
  Future<List<InboundReceiptData>> getAllInboundReceipts() {
    return select(inboundReceipt).get();
  }

  /// 根据店铺ID获取入库单
  Future<List<InboundReceiptData>> getInboundReceiptsByShop(int shopId) {
    return (select(
      inboundReceipt,
    )..where((t) => t.shopId.equals(shopId))).get();
  }

  /// 根据状态获取入库单
  Future<List<InboundReceiptData>> getInboundReceiptsByStatus(String status) {
    return (select(
      inboundReceipt,
    )..where((t) => t.status.equals(status))).get();
  }

  /// 监听所有入库单变化
  Stream<List<InboundReceiptData>> watchAllInboundReceipts() {
    return select(inboundReceipt).watch();
  }

  /// 监听指定店铺的入库单变化
  Stream<List<InboundReceiptData>> watchInboundReceiptsByShop(int shopId) {
    return (select(
      inboundReceipt,
    )..where((t) => t.shopId.equals(shopId))).watch();
  }

  /// 更新入库单
  Future<bool> updateInboundReceipt(InboundReceiptCompanion receipt) async {
    final result = await (update(
      inboundReceipt,
    )..where((t) => t.id.equals(receipt.id.value))).write(receipt);
    return result > 0;
  }

  /// 删除入库单
  Future<int> deleteInboundReceipt(int id) {
    return (delete(inboundReceipt)..where((t) => t.id.equals(id))).go();
  }

  /// 获取入库单总数
  Future<int> getInboundReceiptCount() async {
    final result = await (selectOnly(
      inboundReceipt,
    )..addColumns([inboundReceipt.id.count()])).getSingle();
    return result.read(inboundReceipt.id.count()) ?? 0;
  }

  /// 根据日期范围获取入库单
  Future<List<InboundReceiptData>> getInboundReceiptsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return (select(
      inboundReceipt,
    )..where((t) => t.createdAt.isBetweenValues(startDate, endDate))).get();
  }
}
