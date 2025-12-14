import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/inventory/application/inventory_service.dart';
import '../../data/repository/sales_return_repository.dart';
import '../../data/repository/sales_transaction_repository.dart';
import '../../domain/repository/i_sales_transaction_repository.dart';
import '../../domain/model/sales_return.dart';
import '../../domain/model/sales_return_item.dart';

/// 退货明细输入模型
class SalesReturnItemInput {
  final int salesTransactionItemId;
  final int productId;
  final int unitId;
  final int? batchId;
  final int quantity;
  final int priceInCents;
  final int conversionRate;

  SalesReturnItemInput({
    required this.salesTransactionItemId,
    required this.productId,
    required this.unitId,
    this.batchId,
    required this.quantity,
    required this.priceInCents,
    this.conversionRate = 1,
  });
}

/// 销售退货服务
class SalesReturnService {
  final Ref ref;
  final SalesReturnRepository _salesReturnRepository;
  final ISalesTransactionRepository _salesTransactionRepository;
  final InventoryService _inventoryService;

  SalesReturnService({
    required this.ref,
    required SalesReturnRepository salesReturnRepository,
    required ISalesTransactionRepository salesTransactionRepository,
    required InventoryService inventoryService,
  })  : _salesReturnRepository = salesReturnRepository,
        _salesTransactionRepository = salesTransactionRepository,
        _inventoryService = inventoryService;

  /// 处理销售退货
  Future<String> processSalesReturn({
    required int salesTransactionId,
    required int shopId,
    required List<SalesReturnItemInput> returnItems,
    int? customerId,
    String? reason,
    String? remarks,
  }) async {
    final db = ref.read(appDatabaseProvider);

    return await db.transaction<String>(() async {
      // 1. 验证原销售单
      final originalTransaction = await _salesTransactionRepository.getSalesTransactionById(salesTransactionId);
      if (originalTransaction == null) {
        throw StateError('原销售单不存在: $salesTransactionId');
      }

      // 2. 验证退货数量不超过可退数量
      final returnedQuantities = await _salesReturnRepository.getReturnedQuantitiesByTransactionId(salesTransactionId);
      for (final item in returnItems) {
        final alreadyReturned = returnedQuantities[item.salesTransactionItemId] ?? 0;
        final originalItem = originalTransaction.items.firstWhere(
          (i) => i.id == item.salesTransactionItemId,
          orElse: () => throw StateError('原销售明细不存在: ${item.salesTransactionItemId}'),
        );
        
        if (item.quantity + alreadyReturned > originalItem.quantity) {
          throw StateError('退货数量超过可退数量: 商品${item.productId}');
        }
      }

      // 3. 计算退货总金额
      final totalAmount = returnItems.fold<double>(
        0,
        (sum, item) => sum + (item.quantity * item.priceInCents / 100),
      );

      // 4. 创建退货单
      final salesReturn = SalesReturnModel(
        salesTransactionId: salesTransactionId,
        customerId: customerId ?? originalTransaction.customerId,
        shopId: shopId,
        totalAmount: totalAmount,
        status: SalesReturnStatus.completed,
        reason: reason,
        remarks: remarks,
      );
      final returnId = await _salesReturnRepository.addSalesReturn(salesReturn);

      // 5. 创建退货明细并入库
      for (final item in returnItems) {
        // 添加退货明细
        final returnItem = SalesReturnItemModel(
          salesReturnId: returnId,
          salesTransactionItemId: item.salesTransactionItemId,
          productId: item.productId,
          unitId: item.unitId,
          batchId: item.batchId,
          quantity: item.quantity,
          priceInCents: item.priceInCents,
        );
        await _salesReturnRepository.addSalesReturnItem(returnItem);

        // 库存入库（退货）
        final baseUnitQuantity = item.quantity * item.conversionRate;
        final ok = await _inventoryService.inbound(
          productId: item.productId,
          shopId: shopId,
          quantity: baseUnitQuantity,
          batchId: item.batchId,
        );
        if (!ok) {
          throw StateError('库存入库失败: 商品${item.productId}');
        }
      }

      final receiptNumber = 'RETURN-${DateTime.now().millisecondsSinceEpoch}';
      return receiptNumber;
    });
  }

  /// 获取退货单详情
  Future<SalesReturnModel?> getSalesReturnById(int id) {
    return _salesReturnRepository.getSalesReturnById(id);
  }

  /// 获取原销售单的退货记录
  Future<List<SalesReturnModel>> getSalesReturnsByTransactionId(int transactionId) {
    return _salesReturnRepository.getSalesReturnsByTransactionId(transactionId);
  }

  /// 获取店铺的退货单列表
  Future<List<SalesReturnModel>> getSalesReturnsByShopId(int shopId) {
    return _salesReturnRepository.getSalesReturnsByShopId(shopId);
  }

  /// 监听所有退货单
  Stream<List<SalesReturnModel>> watchAllSalesReturns() {
    return _salesReturnRepository.watchAllSalesReturns();
  }

  /// 获取原销售单的可退货商品信息
  Future<List<ReturnableItem>> getReturnableItems(int salesTransactionId) async {
    final transaction = await _salesTransactionRepository.getSalesTransactionById(salesTransactionId);
    if (transaction == null) return [];

    final returnedQuantities = await _salesReturnRepository.getReturnedQuantitiesByTransactionId(salesTransactionId);

    return transaction.items.map((item) {
      final returned = returnedQuantities[item.id] ?? 0;
      final returnable = item.quantity - returned;
      return ReturnableItem(
        salesTransactionItemId: item.id!,
        productId: item.productId,
        unitId: item.unitId,
        batchId: item.batchId,
        originalQuantity: item.quantity,
        returnedQuantity: returned,
        returnableQuantity: returnable,
        priceInCents: item.priceInCents,
      );
    }).where((item) => item.returnableQuantity > 0).toList();
  }

  /// 取消退货单
  Future<bool> cancelSalesReturn(int returnId) async {
    final salesReturn = await _salesReturnRepository.getSalesReturnById(returnId);
    if (salesReturn == null || !salesReturn.canCancel) {
      return false;
    }
    return _salesReturnRepository.updateSalesReturnStatus(returnId, SalesReturnStatus.cancelled);
  }
}

/// 可退货商品信息
class ReturnableItem {
  final int salesTransactionItemId;
  final int productId;
  final int unitId;
  final int? batchId;
  final int originalQuantity;
  final int returnedQuantity;
  final int returnableQuantity;
  final int priceInCents;

  ReturnableItem({
    required this.salesTransactionItemId,
    required this.productId,
    required this.unitId,
    this.batchId,
    required this.originalQuantity,
    required this.returnedQuantity,
    required this.returnableQuantity,
    required this.priceInCents,
  });
}

final salesReturnServiceProvider = Provider<SalesReturnService>((ref) {
  final salesReturnRepository = ref.watch(salesReturnRepositoryProvider);
  final salesTransactionRepository = ref.watch(salesTransactionRepositoryProvider);
  final inventoryService = ref.watch(inventoryServiceProvider);
  return SalesReturnService(
    ref: ref,
    salesReturnRepository: salesReturnRepository,
    salesTransactionRepository: salesTransactionRepository,
    inventoryService: inventoryService,
  );
});
