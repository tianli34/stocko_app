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
  Future<int> addTransaction(InventoryTransactionModel transaction) async {
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
  Future<InventoryTransactionModel?> getTransactionById(int id) async {
    try {
      final data = await _transactionDao.getTransactionById(id);
      return data != null ? _dataToTransaction(data) : null;
    } catch (e) {
      print('📋 仓储层：根据ID获取库存流水失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<InventoryTransactionModel>> getAllTransactions() async {
    try {
      final dataList = await _transactionDao.getAllTransactions();
      return dataList.map(_dataToTransaction).toList();
    } catch (e) {
      print('📋 仓储层：获取所有库存流水失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<InventoryTransactionModel>> getTransactionsByProduct(
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
  Future<List<InventoryTransactionModel>> getTransactionsByShop(
    int shopId,
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
  Future<List<InventoryTransactionModel>> getTransactionsByType(String type) async {
    try {
      final dataList = await _transactionDao.getTransactionsByType(
        _normalizeTypeToDbCode(type),
      );
      return dataList.map(_dataToTransaction).toList();
    } catch (e) {
      print('📋 仓储层：根据类型获取库存流水失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<InventoryTransactionModel>> getTransactionsByProductAndShop(
    int productId,
    int shopId,
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
  Future<List<InventoryTransactionModel>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int? shopId,
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
  Stream<List<InventoryTransactionModel>> watchAllTransactions() {
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
  Stream<List<InventoryTransactionModel>> watchTransactionsByProduct(
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
  Stream<List<InventoryTransactionModel>> watchTransactionsByShop(int shopId) {
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
  Future<bool> updateTransaction(InventoryTransactionModel transaction) async {
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
  Future<int> deleteTransaction(int id) async {
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
  Future<int> deleteTransactionsByShop(int shopId) async {
    try {
      return await _transactionDao.deleteTransactionsByShop(shopId);
    } catch (e) {
      print('📋 仓储层：删除店铺相关库存流水失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<InventoryTransactionModel>> getInboundTransactions({
    int? shopId,
    int? productId,
  }) async {
  // 使用数据库短码，避免 name 与 DB 存储不一致
  return getTransactionsByType(InventoryTransactionType.inbound.toDbCode);
  }

  @override
  Future<List<InventoryTransactionModel>> getOutboundTransactions({
    int? shopId,
    int? productId,
  }) async {
  return getTransactionsByType(InventoryTransactionType.outbound.toDbCode);
  }

  @override
  Future<List<InventoryTransactionModel>> getAdjustmentTransactions({
    int? shopId,
    int? productId,
  }) async {
  return getTransactionsByType(InventoryTransactionType.adjustment.toDbCode);
  }

  @override
  Future<Map<String, double>> getTransactionSummaryByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int? shopId,
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
        summary[transaction.type.name] =
            (summary[transaction.type.name] ?? 0.0) + transaction.quantity;
      }

      return summary;
    } catch (e) {
      print('📋 仓储层：获取库存流水汇总失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<InventoryTransactionModel>> getRecentTransactions(
    int limit, {
    int? shopId,
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
    int? shopId,
    int? productId,
    String? type,
  }) async {
    try {
      return await _transactionDao.getTransactionCount(
        shopId: shopId,
        productId: productId,
  type: type == null ? null : _normalizeTypeToDbCode(type),
      );
    } catch (e) {
      print('📋 仓储层：获取库存流水数量失败: $e');
      rethrow;
    }
  }

  /// 将InventoryTransaction模型转换为数据库Companion对象
  InventoryTransactionCompanion _transactionToCompanion(
    InventoryTransactionModel transaction,
  ) {
    return InventoryTransactionCompanion(
      id: transaction.id == null ? const Value.absent() : Value(transaction.id!),
      productId: Value(transaction.productId),
    // 数据库存的 type 字段使用短码（in/out/adjust/transfer/return）
    transactionType: Value(transaction.type.toDbCode),
      quantity: Value(transaction.quantity),
      shopId: Value(transaction.shopId),
    batchId: transaction.batchId != null
      ? Value(transaction.batchId!)
      : const Value.absent(),
      createdAt: transaction.createdAt != null
          ? Value(transaction.createdAt!)
          : const Value.absent(),
    );
  }

  /// 将数据库数据转换为InventoryTransaction模型
  InventoryTransactionModel _dataToTransaction(InventoryTransactionData data) {
    return InventoryTransactionModel(
      id: data.id,
      productId: data.productId,
  type: inventoryTransactionTypeFromDbCode(data.transactionType),
      quantity: data.quantity,
      shopId: data.shopId,
  batchId: data.batchId,
      createdAt: data.createdAt,
    );
  }

  /// 将外部传入的类型字符串标准化为数据库短码
  /// 支持传入 enum.name（如 'inbound'）或已是短码（如 'in'）
  String _normalizeTypeToDbCode(String type) {
    final t = type.toLowerCase();
    switch (t) {
      case 'in':
      case 'inbound':
        return 'in';
      case 'out':
      case 'outbound':
        return 'out';
      case 'adjust':
      case 'adjustment':
        return 'adjust';
      case 'transfer':
        return 'transfer';
      case 'return':
      case 'returned':
        return 'return';
      default:
        return t;
    }
  }
}

/// InventoryTransaction Repository Provider
final inventoryTransactionRepositoryProvider =
    Provider<IInventoryTransactionRepository>((ref) {
      final database = ref.watch(appDatabaseProvider);
      return InventoryTransactionRepository(database);
    });
