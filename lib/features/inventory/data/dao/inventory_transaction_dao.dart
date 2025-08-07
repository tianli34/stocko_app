import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/inventory_transactions_table.dart';

part 'inventory_transaction_dao.g.dart';

@DriftAccessor(tables: [InventoryTransactionsTable])
class InventoryTransactionDao extends DatabaseAccessor<AppDatabase>
    with _$InventoryTransactionDaoMixin {
  InventoryTransactionDao(super.db);

  /// 插入库存流水记录
  Future<int> insertTransaction(
    InventoryTransactionsTableCompanion transaction,
  ) {
    return into(inventoryTransactionsTable).insert(transaction);
  }

  /// 根据ID获取库存流水
  Future<InventoryTransactionsTableData?> getTransactionById(String id) {
    return (select(
      inventoryTransactionsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 获取所有库存流水
  Future<List<InventoryTransactionsTableData>> getAllTransactions() {
    return (select(
      inventoryTransactionsTable,
    )..orderBy([(t) => OrderingTerm.desc(t.time)])).get();
  }

  /// 根据产品ID获取流水记录
  Future<List<InventoryTransactionsTableData>> getTransactionsByProduct(
    int productId,
  ) {
    return (select(inventoryTransactionsTable)
          ..where((t) => t.productId.equals(productId))
          ..orderBy([(t) => OrderingTerm.desc(t.time)]))
        .get();
  }

  /// 根据店铺ID获取流水记录
  Future<List<InventoryTransactionsTableData>> getTransactionsByShop(
    String shopId,
  ) {
    return (select(inventoryTransactionsTable)
          ..where((t) => t.shopId.equals(shopId))
          ..orderBy([(t) => OrderingTerm.desc(t.time)]))
        .get();
  }

  /// 根据流水类型获取记录
  Future<List<InventoryTransactionsTableData>> getTransactionsByType(
    String type,
  ) {
    return (select(inventoryTransactionsTable)
          ..where((t) => t.type.equals(type))
          ..orderBy([(t) => OrderingTerm.desc(t.time)]))
        .get();
  }

  /// 根据产品和店铺获取流水记录
  Future<List<InventoryTransactionsTableData>> getTransactionsByProductAndShop(
    int productId,
    String shopId,
  ) {
    return (select(inventoryTransactionsTable)
          ..where(
            (t) => t.productId.equals(productId) & t.shopId.equals(shopId),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.time)]))
        .get();
  }

  /// 根据时间范围获取流水记录
  Future<List<InventoryTransactionsTableData>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? shopId,
    int? productId,
  }) {
    var query = select(inventoryTransactionsTable)
      ..where((t) => t.time.isBetweenValues(startDate, endDate));

    if (shopId != null) {
      query = query..where((t) => t.shopId.equals(shopId));
    }

    if (productId != null) {
      query = query..where((t) => t.productId.equals(productId));
    }

    return (query..orderBy([(t) => OrderingTerm.desc(t.time)])).get();
  }

  /// 监听所有库存流水变化
  Stream<List<InventoryTransactionsTableData>> watchAllTransactions() {
    return (select(
      inventoryTransactionsTable,
    )..orderBy([(t) => OrderingTerm.desc(t.time)])).watch();
  }

  /// 监听指定产品的流水变化
  Stream<List<InventoryTransactionsTableData>> watchTransactionsByProduct(
    int productId,
  ) {
    return (select(inventoryTransactionsTable)
          ..where((t) => t.productId.equals(productId))
          ..orderBy([(t) => OrderingTerm.desc(t.time)]))
        .watch();
  }

  /// 监听指定店铺的流水变化
  Stream<List<InventoryTransactionsTableData>> watchTransactionsByShop(
    String shopId,
  ) {
    return (select(inventoryTransactionsTable)
          ..where((t) => t.shopId.equals(shopId))
          ..orderBy([(t) => OrderingTerm.desc(t.time)]))
        .watch();
  }

  /// 更新库存流水
  Future<bool> updateTransaction(
    InventoryTransactionsTableCompanion transaction,
  ) async {
    final result = await (update(
      inventoryTransactionsTable,
    )..where((t) => t.id.equals(transaction.id.value))).write(transaction);
    return result > 0;
  }

  /// 删除库存流水记录
  Future<int> deleteTransaction(String id) {
    return (delete(
      inventoryTransactionsTable,
    )..where((t) => t.id.equals(id))).go();
  }

  /// 根据产品删除相关流水
  Future<int> deleteTransactionsByProduct(int productId) {
    return (delete(
      inventoryTransactionsTable,
    )..where((t) => t.productId.equals(productId))).go();
  }

  /// 根据店铺删除相关流水
  Future<int> deleteTransactionsByShop(String shopId) {
    return (delete(
      inventoryTransactionsTable,
    )..where((t) => t.shopId.equals(shopId))).go();
  }

  /// 获取最近的流水记录
  Future<List<InventoryTransactionsTableData>> getRecentTransactions(
    int limit, {
    String? shopId,
    int? productId,
  }) {
    var query = select(inventoryTransactionsTable);

    if (shopId != null) {
      query = query..where((t) => t.shopId.equals(shopId));
    }

    if (productId != null) {
      query = query..where((t) => t.productId.equals(productId));
    }

    return (query
          ..orderBy([(t) => OrderingTerm.desc(t.time)])
          ..limit(limit))
        .get();
  }

  /// 获取流水总数
  Future<int> getTransactionCount({
    String? shopId,
    int? productId,
    String? type,
  }) async {
    var query = selectOnly(inventoryTransactionsTable)
      ..addColumns([inventoryTransactionsTable.id.count()]);

    if (shopId != null) {
      query = query..where(inventoryTransactionsTable.shopId.equals(shopId));
    }

    if (productId != null) {
      query = query
        ..where(inventoryTransactionsTable.productId.equals(productId));
    }

    if (type != null) {
      query = query..where(inventoryTransactionsTable.type.equals(type));
    }

    final result = await query.getSingle();
    return result.read(inventoryTransactionsTable.id.count()) ?? 0;
  }
}
