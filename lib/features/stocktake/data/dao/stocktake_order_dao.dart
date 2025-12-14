import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../core/database/stocktake_orders_table.dart';

part 'stocktake_order_dao.g.dart';

@DriftAccessor(tables: [StocktakeOrder])
class StocktakeOrderDao extends DatabaseAccessor<AppDatabase>
    with _$StocktakeOrderDaoMixin {
  StocktakeOrderDao(super.db);

  /// 插入盘点单
  Future<int> insertOrder(StocktakeOrderCompanion order) {
    return into(stocktakeOrder).insert(order);
  }

  /// 更新盘点单
  Future<bool> updateOrder(StocktakeOrderCompanion order, int id) {
    return (update(stocktakeOrder)..where((t) => t.id.equals(id)))
        .write(order)
        .then((rows) => rows > 0);
  }

  /// 删除盘点单
  Future<int> deleteOrder(int id) {
    return (delete(stocktakeOrder)..where((t) => t.id.equals(id))).go();
  }

  /// 根据ID获取盘点单
  Future<StocktakeOrderData?> getOrderById(int id) {
    return (select(stocktakeOrder)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 根据单号获取盘点单
  Future<StocktakeOrderData?> getOrderByNumber(String orderNumber) {
    return (select(stocktakeOrder)
          ..where((t) => t.orderNumber.equals(orderNumber)))
        .getSingleOrNull();
  }

  /// 获取店铺的盘点单列表
  Future<List<StocktakeOrderData>> getOrdersByShop(int shopId) {
    return (select(stocktakeOrder)
          ..where((t) => t.shopId.equals(shopId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 获取所有盘点单
  Future<List<StocktakeOrderData>> getAllOrders() {
    return (select(stocktakeOrder)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 根据状态获取盘点单
  Future<List<StocktakeOrderData>> getOrdersByStatus(String status) {
    return (select(stocktakeOrder)
          ..where((t) => t.status.equals(status))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 更新盘点单状态
  Future<bool> updateStatus(int id, String status, {DateTime? completedAt, DateTime? auditedAt}) {
    final companion = StocktakeOrderCompanion(
      status: Value(status),
      completedAt: completedAt != null ? Value(completedAt) : const Value.absent(),
      auditedAt: auditedAt != null ? Value(auditedAt) : const Value.absent(),
    );
    return (update(stocktakeOrder)..where((t) => t.id.equals(id)))
        .write(companion)
        .then((rows) => rows > 0);
  }

  /// 监听盘点单列表
  Stream<List<StocktakeOrderData>> watchAllOrders() {
    return (select(stocktakeOrder)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// 监听店铺的盘点单列表
  Stream<List<StocktakeOrderData>> watchOrdersByShop(int shopId) {
    return (select(stocktakeOrder)
          ..where((t) => t.shopId.equals(shopId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }
}
