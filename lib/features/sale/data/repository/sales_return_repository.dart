import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../../domain/model/sales_return.dart';
import '../../domain/model/sales_return_item.dart';
import '../../domain/repository/i_sales_return_repository.dart';
import '../dao/sales_return_dao.dart';
import '../dao/sales_return_item_dao.dart';

class SalesReturnRepository implements ISalesReturnRepository {
  final SalesReturnDao _salesReturnDao;
  final SalesReturnItemDao _salesReturnItemDao;

  SalesReturnRepository(this._salesReturnDao, this._salesReturnItemDao);

  @override
  Future<int> addSalesReturn(SalesReturnModel salesReturn) {
    final companion = SalesReturnCompanion(
      salesTransactionId: Value(salesReturn.salesTransactionId),
      customerId: salesReturn.customerId != null 
          ? Value(salesReturn.customerId!) 
          : const Value.absent(),
      shopId: Value(salesReturn.shopId),
      totalAmount: Value(salesReturn.totalAmount),
      status: Value(salesReturn.status.name),
      reason: salesReturn.reason != null 
          ? Value(salesReturn.reason!) 
          : const Value.absent(),
      remarks: salesReturn.remarks != null 
          ? Value(salesReturn.remarks!) 
          : const Value.absent(),
    );
    return _salesReturnDao.insertSalesReturn(companion);
  }

  @override
  Future<int> addSalesReturnItem(SalesReturnItemModel item) {
    final companion = SalesReturnItemCompanion(
      salesReturnId: Value(item.salesReturnId),
      salesTransactionItemId: item.salesTransactionItemId != null
          ? Value(item.salesTransactionItemId!)
          : const Value.absent(),
      productId: Value(item.productId),
      unitId: item.unitId != null ? Value(item.unitId!) : const Value.absent(),
      batchId: item.batchId != null ? Value(item.batchId!) : const Value.absent(),
      quantity: Value(item.quantity),
      priceInCents: Value(item.priceInCents),
    );
    return _salesReturnItemDao.insertSalesReturnItem(companion);
  }

  @override
  Future<SalesReturnModel?> getSalesReturnById(int id) async {
    final data = await _salesReturnDao.findSalesReturnById(id);
    if (data == null) return null;
    
    final items = await _salesReturnItemDao.findItemsBySalesReturnId(id);
    return _mapToModel(data, items);
  }

  @override
  Future<List<SalesReturnModel>> getSalesReturnsByTransactionId(int transactionId) async {
    final dataList = await _salesReturnDao.findSalesReturnsByTransactionId(transactionId);
    final result = <SalesReturnModel>[];
    for (final data in dataList) {
      final items = await _salesReturnItemDao.findItemsBySalesReturnId(data.id);
      result.add(_mapToModel(data, items));
    }
    return result;
  }

  @override
  Future<List<SalesReturnModel>> getSalesReturnsByShopId(int shopId) async {
    final dataList = await _salesReturnDao.findSalesReturnsByShopId(shopId);
    final result = <SalesReturnModel>[];
    for (final data in dataList) {
      final items = await _salesReturnItemDao.findItemsBySalesReturnId(data.id);
      result.add(_mapToModel(data, items));
    }
    return result;
  }

  @override
  Stream<List<SalesReturnModel>> watchAllSalesReturns() {
    return _salesReturnDao.watchAllSalesReturns().asyncMap((dataList) async {
      final result = <SalesReturnModel>[];
      for (final data in dataList) {
        final items = await _salesReturnItemDao.findItemsBySalesReturnId(data.id);
        result.add(_mapToModel(data, items));
      }
      return result;
    });
  }

  @override
  Future<bool> updateSalesReturnStatus(int id, SalesReturnStatus status) {
    return _salesReturnDao.updateSalesReturnStatus(id, status.name);
  }

  @override
  Future<Map<int, int>> getReturnedQuantitiesByTransactionId(int transactionId) {
    return _salesReturnItemDao.getReturnedQuantitiesByTransactionId(transactionId);
  }

  SalesReturnModel _mapToModel(SalesReturnData data, List<SalesReturnItemData> itemsData) {
    return SalesReturnModel(
      id: data.id,
      salesTransactionId: data.salesTransactionId,
      customerId: data.customerId,
      shopId: data.shopId,
      totalAmount: data.totalAmount,
      status: SalesReturnStatus.values.firstWhere(
        (e) => e.name == data.status,
        orElse: () => SalesReturnStatus.pending,
      ),
      reason: data.reason,
      remarks: data.remarks,
      items: itemsData.map((item) => SalesReturnItemModel(
        id: item.id,
        salesReturnId: item.salesReturnId,
        salesTransactionItemId: item.salesTransactionItemId,
        productId: item.productId,
        unitId: item.unitId,
        batchId: item.batchId,
        quantity: item.quantity,
        priceInCents: item.priceInCents,
      )).toList(),
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }
}

final salesReturnRepositoryProvider = Provider<SalesReturnRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SalesReturnRepository(
    SalesReturnDao(db),
    SalesReturnItemDao(db),
  );
});
