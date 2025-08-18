import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stocko_app/features/inventory/application/inventory_service.dart';
import 'package:stocko_app/features/sale/data/repository/sales_transaction_repository.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:drift/drift.dart' as drift;

import '../../domain/model/sale_cart_item.dart';
import '../../domain/model/sales_transaction.dart';
import '../../domain/model/sales_transaction_item.dart';
import '../../domain/repository/i_sales_transaction_repository.dart';

class SaleService {
  SaleService({
    required this.ref,
    required this.salesTransactionRepository,
    required this.inventoryService,
  });

  final Ref ref;
  final ISalesTransactionRepository salesTransactionRepository;
  final InventoryService inventoryService;

  Future<String> processOneClickSale({
    required int salesOrderNo,
    required int shopId,
    required List<SaleCartItem> saleItems,
    String? remarks,
    required bool isSaleMode,
    int? customerId,
    String? customerName,
    SalesStatus status = SalesStatus.preset,
  }) async {
    final now = DateTime.now();
    final totalAmount = saleItems.fold(0.0, (sum, item) => sum + item.amount);

    final transactionItems = saleItems.map((item) {
      return SalesTransactionItem(
        salesTransactionId: 0, // Will be replaced later
        productId: item.productId,
        batchId: item.batchId != null ? int.tryParse(item.batchId!) : null,
        quantity: item.quantity.toInt(),
        priceInCents: item.sellingPriceInCents,
      );
    }).toList();

    final transaction = SalesTransaction(
      shopId: shopId,
      totalAmount: totalAmount,
      actualAmount: totalAmount,
      remarks: remarks,
      customerId: customerId ?? 0,
      items: transactionItems,
      status: status,
    );

    await salesTransactionRepository.addSalesTransaction(transaction);

    // 写入出库单与明细（仅销售模式）
    if (isSaleMode) {
      final db = ref.read(appDatabaseProvider);

      // 1) 创建出库单
      final receiptId = await db.outboundReceiptDao.insertOutboundReceipt(
        OutboundReceiptCompanion(
          shopId: drift.Value(shopId),
          reason: const drift.Value('销售出库'),
          // salesTransactionId 暂无法获取（仓储未返回ID），保留为空
        ),
      );

      // 2) 合并明细，避免唯一键冲突（receipt_id, product_id, batch_id）
      final Map<(int, int?), int> merged = {};
      for (final item in saleItems) {
        final key = (item.productId, item.batchId != null ? int.tryParse(item.batchId!) : null);
        merged.update(key, (q) => q + item.quantity.toInt(), ifAbsent: () => item.quantity.toInt());
      }

      // 3) 批量写入出库明细
      final companions = merged.entries.map((e) {
        final pid = e.key.$1;
        final bid = e.key.$2;
        final qty = e.value;
        return OutboundItemCompanion(
          receiptId: drift.Value(receiptId),
          productId: drift.Value(pid),
          quantity: drift.Value(qty),
          batchId: bid != null ? drift.Value(bid) : const drift.Value.absent(),
        );
      }).toList(growable: false);

      if (companions.isNotEmpty) {
        await db.batch((batch) {
          batch.insertAll(db.outboundItem, companions);
        });
      }
    }

    for (final item in saleItems) {
      if (isSaleMode) {
        await inventoryService.outbound(
          productId: item.productId,
          shopId: shopId,
          quantity: item.quantity.toInt(),
          time: now,
        );
      } else {
        await inventoryService.inbound(
          productId: item.productId,
          shopId: shopId,
          quantity: item.quantity.toInt(),
          // TODO: Handle return with batch number properly
          time: now,
        );
      }
    }

    final receiptNumber = 'SALE-${now.millisecondsSinceEpoch}';
    print('Sale successful. Receipt number: $receiptNumber');

    return receiptNumber;
  }
}

final saleServiceProvider = Provider<SaleService>((ref) {
  final salesTransactionRepository =
      ref.watch(salesTransactionRepositoryProvider);
  final inventoryService = ref.watch(inventoryServiceProvider);
  return SaleService(
    ref: ref,
    salesTransactionRepository: salesTransactionRepository,
    inventoryService: inventoryService,
  );
});