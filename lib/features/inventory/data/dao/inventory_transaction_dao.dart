import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/inventory_transactions_table.dart';

part 'inventory_transaction_dao.g.dart';

@DriftAccessor(tables: [InventoryTransaction])
class InventoryTransactionDao extends DatabaseAccessor<AppDatabase>
    with _$InventoryTransactionDaoMixin {
  InventoryTransactionDao(super.db);

  /// 插入库存流水记录
  Future<int> insertTransaction(
    InventoryTransactionCompanion transaction,
  ) {
    return into(inventoryTransaction).insert(transaction);
  }

  /// 根据ID获取库存流水
  Future<InventoryTransactionData?> getTransactionById(int id) {
    return (select(
      inventoryTransaction,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 获取所有库存流水
  Future<List<InventoryTransactionData>> getAllTransactions() {
    return (select(
      inventoryTransaction,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  /// 根据产品ID获取流水记录
  Future<List<InventoryTransactionData>> getTransactionsByProduct(
    int productId,
  ) {
    return (select(inventoryTransaction)
          ..where((t) => t.productId.equals(productId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 根据店铺ID获取流水记录
  Future<List<InventoryTransactionData>> getTransactionsByShop(
    String shopId,
  ) {
    return (select(inventoryTransaction)
          ..where((t) => t.shopId.equals(shopId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 根据流水类型获取记录
  Future<List<InventoryTransactionData>> getTransactionsByType(
    String type,
  ) {
    return (select(inventoryTransaction)
          ..where((t) => t.transactionType.equals(type))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 根据产品和店铺获取流水记录
  Future<List<InventoryTransactionData>> getTransactionsByProductAndShop(
    int productId,
    String shopId,
  ) {
    return (select(inventoryTransaction)
          ..where(
            (t) => t.productId.equals(productId) & t.shopId.equals(shopId),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 根据时间范围获取流水记录
  Future<List<InventoryTransactionData>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? shopId,
    int? productId,
  }) {
    var query = select(inventoryTransaction)
      ..where((t) => t.createdAt.isBetweenValues(startDate, endDate));

    if (shopId != null) {
      query = query..where((t) => t.shopId.equals(shopId));
    }

    if (productId != null) {
      query = query..where((t) => t.productId.equals(productId));
    }

    return (query..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  /// 监听所有库存流水变化
  Stream<List<InventoryTransactionData>> watchAllTransactions() {
    return (select(
      inventoryTransaction,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  /// 监听指定产品的流水变化
  Stream<List<InventoryTransactionData>> watchTransactionsByProduct(
    int productId,
  ) {
    return (select(inventoryTransaction)
          ..where((t) => t.productId.equals(productId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// 监听指定店铺的流水变化
  Stream<List<InventoryTransactionData>> watchTransactionsByShop(
    String shopId,
  ) {
    return (select(inventoryTransaction)
          ..where((t) => t.shopId.equals(shopId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// 更新库存流水
  Future<bool> updateTransaction(
    InventoryTransactionCompanion transaction,
  ) async {
    final result = await (update(
      inventoryTransaction,
    )..where((t) => t.id.equals(transaction.id.value))).write(transaction);
    return result > 0;
  }

  /// 删除库存流水记录
  Future<int> deleteTransaction(int id) {
    return (delete(
      inventoryTransaction,
    )..where((t) => t.id.equals(id))).go();
  }

  /// 根据产品删除相关流水
  Future<int> deleteTransactionsByProduct(int productId) {
    return (delete(
      inventoryTransaction,
    )..where((t) => t.productId.equals(productId))).go();
  }

  /// 根据店铺删除相关流水
  Future<int> deleteTransactionsByShop(String shopId) {
    return (delete(
      inventoryTransaction,
    )..where((t) => t.shopId.equals(shopId))).go();
  }

  /// 获取最近的流水记录
  Future<List<InventoryTransactionData>> getRecentTransactions(
    int limit, {
    String? shopId,
    int? productId,
  }) {
    var query = select(inventoryTransaction);

    if (shopId != null) {
      query = query..where((t) => t.shopId.equals(shopId));
    }

    if (productId != null) {
      query = query..where((t) => t.productId.equals(productId));
    }

    return (query
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// 获取流水总数
  Future<int> getTransactionCount({
    String? shopId,
    int? productId,
    String? type,
  }) async {
    var query = selectOnly(inventoryTransaction)
      ..addColumns([inventoryTransaction.id.count()]);

    if (shopId != null) {
      query = query..where(inventoryTransaction.shopId.equals(shopId));
    }

    if (productId != null) {
      query = query
        ..where(inventoryTransaction.productId.equals(productId));
    }

    if (type != null) {
      query = query..where(inventoryTransaction.transactionType.equals(type));
    }

    final result = await query.getSingle();
    return result.read(inventoryTransaction.id.count()) ?? 0;
  }
}
