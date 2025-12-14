import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../../domain/model/stocktake_order.dart';
import '../../domain/model/stocktake_status.dart';
import '../../domain/repository/i_stocktake_order_repository.dart';
import '../dao/stocktake_order_dao.dart';

class StocktakeOrderRepository implements IStocktakeOrderRepository {
  final StocktakeOrderDao _dao;

  StocktakeOrderRepository(this._dao);

  @override
  Future<int> createOrder(StocktakeOrderModel order) {
    return _dao.insertOrder(_toCompanion(order));
  }

  @override
  Future<bool> updateOrder(StocktakeOrderModel order) {
    if (order.id == null) return Future.value(false);
    return _dao.updateOrder(_toCompanion(order), order.id!);
  }

  @override
  Future<bool> deleteOrder(int id) async {
    final rows = await _dao.deleteOrder(id);
    return rows > 0;
  }

  @override
  Future<StocktakeOrderModel?> getOrderById(int id) async {
    final data = await _dao.getOrderById(id);
    return data != null ? _toModel(data) : null;
  }

  @override
  Future<StocktakeOrderModel?> getOrderByNumber(String orderNumber) async {
    final data = await _dao.getOrderByNumber(orderNumber);
    return data != null ? _toModel(data) : null;
  }

  @override
  Future<List<StocktakeOrderModel>> getOrdersByShop(int shopId) async {
    final dataList = await _dao.getOrdersByShop(shopId);
    return dataList.map(_toModel).toList();
  }

  @override
  Future<List<StocktakeOrderModel>> getAllOrders() async {
    final dataList = await _dao.getAllOrders();
    return dataList.map(_toModel).toList();
  }

  @override
  Future<List<StocktakeOrderModel>> getOrdersByStatus(
      StocktakeStatus status) async {
    final dataList = await _dao.getOrdersByStatus(status.value);
    return dataList.map(_toModel).toList();
  }

  @override
  Future<bool> updateStatus(int id, StocktakeStatus status) {
    DateTime? completedAt;
    DateTime? auditedAt;
    
    if (status == StocktakeStatus.completed) {
      completedAt = DateTime.now();
    } else if (status == StocktakeStatus.audited) {
      auditedAt = DateTime.now();
    }
    
    return _dao.updateStatus(id, status.value,
        completedAt: completedAt, auditedAt: auditedAt);
  }

  @override
  Stream<List<StocktakeOrderModel>> watchAllOrders() {
    return _dao.watchAllOrders().map((list) => list.map(_toModel).toList());
  }

  @override
  Stream<List<StocktakeOrderModel>> watchOrdersByShop(int shopId) {
    return _dao
        .watchOrdersByShop(shopId)
        .map((list) => list.map(_toModel).toList());
  }

  StocktakeOrderModel _toModel(StocktakeOrderData data) {
    return StocktakeOrderModel(
      id: data.id,
      orderNumber: data.orderNumber,
      shopId: data.shopId,
      type: StocktakeType.fromValue(data.type),
      status: StocktakeStatus.fromValue(data.status),
      categoryId: data.categoryId,
      remarks: data.remarks,
      createdAt: data.createdAt,
      completedAt: data.completedAt,
      auditedAt: data.auditedAt,
    );
  }

  StocktakeOrderCompanion _toCompanion(StocktakeOrderModel model) {
    return StocktakeOrderCompanion(
      id: model.id != null ? Value(model.id!) : const Value.absent(),
      orderNumber: Value(model.orderNumber),
      shopId: Value(model.shopId),
      type: Value(model.type.value),
      status: Value(model.status.value),
      categoryId: model.categoryId != null
          ? Value(model.categoryId!)
          : const Value.absent(),
      remarks:
          model.remarks != null ? Value(model.remarks!) : const Value.absent(),
      createdAt: model.createdAt != null
          ? Value(model.createdAt!)
          : const Value.absent(),
      completedAt: model.completedAt != null
          ? Value(model.completedAt!)
          : const Value.absent(),
      auditedAt: model.auditedAt != null
          ? Value(model.auditedAt!)
          : const Value.absent(),
    );
  }
}

/// Provider
final stocktakeOrderDaoProvider = Provider<StocktakeOrderDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return StocktakeOrderDao(db);
});

final stocktakeOrderRepositoryProvider =
    Provider<IStocktakeOrderRepository>((ref) {
  final dao = ref.watch(stocktakeOrderDaoProvider);
  return StocktakeOrderRepository(dao);
});
