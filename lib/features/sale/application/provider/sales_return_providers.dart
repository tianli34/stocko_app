import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../../data/dao/sales_return_dao.dart';
import '../../data/dao/sales_return_item_dao.dart';
import '../service/sales_return_service.dart';

/// SalesReturnDao Provider
final salesReturnDaoProvider = Provider<SalesReturnDao>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return SalesReturnDao(database);
});

/// SalesReturnItemDao Provider
final salesReturnItemDaoProvider = Provider<SalesReturnItemDao>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return SalesReturnItemDao(database);
});

/// 监听所有退货单
final salesReturnsProvider = StreamProvider<List<SalesReturnData>>((ref) {
  final dao = ref.watch(salesReturnDaoProvider);
  return dao.watchAllSalesReturns();
});

/// 获取可退货商品列表
final returnableItemsProvider = FutureProvider.family<List<ReturnableItem>, int>((ref, transactionId) {
  final service = ref.watch(salesReturnServiceProvider);
  return service.getReturnableItems(transactionId);
});

/// 获取原销售单的退货记录
final salesReturnsByTransactionProvider = FutureProvider.family<List<dynamic>, int>((ref, transactionId) {
  final service = ref.watch(salesReturnServiceProvider);
  return service.getSalesReturnsByTransactionId(transactionId);
});
