import '../../domain/repository/i_inventory_transaction_repository.dart';
import '../../domain/model/inventory_transaction.dart';
import '../../../../core/database/database.dart';
import '../dao/inventory_transaction_dao.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 库存流水仓储实现类
/// 基于本地数据库的库存流水数据访问层实现
class InventoryTransactionRepository
    implements IInventoryTransactionRepository {
  final InventoryTransactionDao _transactionDao;

  InventoryTransactionRepository(AppDatabase database)
    : _transactionDao = database.inventoryTransactionDao;

  @override
  Future<int> addTransaction(InventoryTransaction transaction) async {
    try {
      print('📋 仓储层：添加库存流水记录，ID: ${transaction.id}');
      return await _transactionDao.insertTransaction(
        _transactionToCompanion(transaction),
      );
    } catch (e) {
      print('📋 仓储层：添加库存流水记录失败: $e');
      rethrow;
    }
  }

  @override
  Future<InventoryTransaction?> getTransactionById(String id) async {
    try {
      final data = await _transactionDao.getTransactionById(id);
      return data != null ? _dataToTransaction(data) : null;
    } catch (e) {
      print('📋 仓储层：根据ID获取库存流水失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<InventoryTransaction>> getAllTransactions() async {
    try {
      final dataList = await _transactionDao.getAllTransactions();
      return dataList.map(_dataToTransaction).toList();
    } catch (e) {
      print('📋 仓储层：获取所有库存流水失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<InventoryTransaction>> getTransactionsByProduct(
    int productId,
  ) async {
    try {
      final dataList = await _transactionDao.getTransactionsByProduct(
        productId,
      );
      return dataList.map(_dataToTransaction).toList();
    } catch (e) {
      print('📋 仓储层：根据产品获取库存流水失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<InventoryTransaction>> getTransactionsByShop(
    String shopId,
  ) async {
    try {
      final dataList = await _transactionDao.getTransactionsByShop(shopId);
      return dataList.map(_dataToTransaction).toList();
    } catch (e) {
      print('📋 仓储层：根据店铺获取库存流水失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<InventoryTransaction>> getTransactionsByType(String type) async {
    try {
      final dataList = await _transactionDao.getTransactionsByType(type);
      return dataList.map(_dataToTransaction).toList();
    } catch (e) {
      print('📋 仓储层：根据类型获取库存流水失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<InventoryTransaction>> getTransactionsByProductAndShop(
    int productId,
    String shopId,
  ) async {
    try {
      final dataList = await _transactionDao.getTransactionsByProductAndShop(
        productId,
        shopId,
      );
      return dataList.map(_dataToTransaction).toList();
    } catch (e) {
      print('📋 仓储层：根据产品和店铺获取库存流水失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<InventoryTransaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? shopId,
    int? productId,
  }) async {
    try {
      final dataList = await _transactionDao.getTransactionsByDateRange(
        startDate,
        endDate,
        shopId: shopId,
        productId: productId,
      );
      return dataList.map(_dataToTransaction).toList();
    } catch (e) {
      print('📋 仓储层：根据时间范围获取库存流水失败: $e');
      rethrow;
    }
  }

  @override
  Stream<List<InventoryTransaction>> watchAllTransactions() {
    try {
      return _transactionDao.watchAllTransactions().map(
        (dataList) => dataList.map(_dataToTransaction).toList(),
      );
    } catch (e) {
      print('📋 仓储层：监听所有库存流水失败: $e');
      rethrow;
    }
  }

  @override
  Stream<List<InventoryTransaction>> watchTransactionsByProduct(
    int productId,
  ) {
    try {
      return _transactionDao
          .watchTransactionsByProduct(productId)
          .map((dataList) => dataList.map(_dataToTransaction).toList());
    } catch (e) {
      print('📋 仓储层：监听产品库存流水失败: $e');
      rethrow;
    }
  }

  @override
  Stream<List<InventoryTransaction>> watchTransactionsByShop(String shopId) {
    try {
      return _transactionDao
          .watchTransactionsByShop(shopId)
          .map((dataList) => dataList.map(_dataToTransaction).toList());
    } catch (e) {
      print('📋 仓储层：监听店铺库存流水失败: $e');
      rethrow;
    }
  }

  @override
  Future<bool> updateTransaction(InventoryTransaction transaction) async {
    try {
      print('📋 仓储层：更新库存流水，ID: ${transaction.id}');
      return await _transactionDao.updateTransaction(
        _transactionToCompanion(transaction),
      );
    } catch (e) {
      print('📋 仓储层：更新库存流水失败: $e');
      rethrow;
    }
  }

  @override
  Future<int> deleteTransaction(String id) async {
    try {
      print('📋 仓储层：删除库存流水记录，ID: $id');
      return await _transactionDao.deleteTransaction(id);
    } catch (e) {
      print('📋 仓储层：删除库存流水记录失败: $e');
      rethrow;
    }
  }

  @override
  Future<int> deleteTransactionsByProduct(int productId) async {
    try {
      return await _transactionDao.deleteTransactionsByProduct(productId);
    } catch (e) {
      print('📋 仓储层：删除产品相关库存流水失败: $e');
      rethrow;
    }
  }

  @override
  Future<int> deleteTransactionsByShop(String shopId) async {
    try {
      return await _transactionDao.deleteTransactionsByShop(shopId);
    } catch (e) {
      print('📋 仓储层：删除店铺相关库存流水失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<InventoryTransaction>> getInboundTransactions({
    String? shopId,
    int? productId,
  }) async {
    return getTransactionsByType(InventoryTransaction.typeIn);
  }

  @override
  Future<List<InventoryTransaction>> getOutboundTransactions({
    String? shopId,
    int? productId,
  }) async {
    return getTransactionsByType(InventoryTransaction.typeOut);
  }

  @override
  Future<List<InventoryTransaction>> getAdjustmentTransactions({
    String? shopId,
    int? productId,
  }) async {
    return getTransactionsByType(InventoryTransaction.typeAdjust);
  }

  @override
  Future<Map<String, double>> getTransactionSummaryByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? shopId,
    int? productId,
  }) async {
    try {
      final transactions = await getTransactionsByDateRange(
        startDate,
        endDate,
        shopId: shopId,
        productId: productId,
      );

      final summary = <String, double>{};
      for (final transaction in transactions) {
        summary[transaction.type] =
            (summary[transaction.type] ?? 0.0) + transaction.quantity;
      }

      return summary;
    } catch (e) {
      print('📋 仓储层：获取库存流水汇总失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<InventoryTransaction>> getRecentTransactions(
    int limit, {
    String? shopId,
    int? productId,
  }) async {
    try {
      final dataList = await _transactionDao.getRecentTransactions(
        limit,
        shopId: shopId,
        productId: productId,
      );
      return dataList.map(_dataToTransaction).toList();
    } catch (e) {
      print('📋 仓储层：获取最近库存流水失败: $e');
      rethrow;
    }
  }

  @override
  Future<int> getTransactionCount({
    String? shopId,
    int? productId,
    String? type,
  }) async {
    try {
      return await _transactionDao.getTransactionCount(
        shopId: shopId,
        productId: productId,
        type: type,
      );
    } catch (e) {
      print('📋 仓储层：获取库存流水数量失败: $e');
      rethrow;
    }
  }

  /// 将InventoryTransaction模型转换为数据库Companion对象
  InventoryTransactionsTableCompanion _transactionToCompanion(
    InventoryTransaction transaction,
  ) {
    return InventoryTransactionsTableCompanion(
      id: Value(transaction.id),
      productId: Value(transaction.productId),
      type: Value(transaction.type),
      quantity: Value(transaction.quantity),
      shopId: Value(transaction.shopId),
      time: Value(transaction.time),
      createdAt: transaction.createdAt != null
          ? Value(transaction.createdAt!)
          : const Value.absent(),
    );
  }

  /// 将数据库数据转换为InventoryTransaction模型
  InventoryTransaction _dataToTransaction(InventoryTransactionsTableData data) {
    return InventoryTransaction(
      id: data.id,
      productId: data.productId,
      type: data.type,
      quantity: data.quantity,
      shopId: data.shopId,
      time: data.time,
      createdAt: data.createdAt,
    );
  }
}

/// InventoryTransaction Repository Provider
final inventoryTransactionRepositoryProvider =
    Provider<IInventoryTransactionRepository>((ref) {
      final database = ref.watch(appDatabaseProvider);
      return InventoryTransactionRepository(database);
    });
