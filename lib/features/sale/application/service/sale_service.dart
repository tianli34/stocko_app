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

    final db = ref.read(appDatabaseProvider);

    return await db.transaction<String>(() async {
      // 1) 先落销售交易，拿到ID
      final transactionItems = saleItems.map((item) {
        return SalesTransactionItem(
          salesTransactionId: 0,
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

      final salesId = await salesTransactionRepository.addSalesTransaction(transaction);

      // 2) 仅销售模式：写出库单与明细，并在同事务内扣减库存并记录流水
      if (isSaleMode) {
        final receiptId = await db.outboundReceiptDao.insertOutboundReceipt(
          OutboundReceiptCompanion(
            shopId: drift.Value(shopId),
            reason: const drift.Value('销售出库'),
            salesTransactionId: drift.Value(salesId),
          ),
        );

        // 合并明细
        final Map<(int, int?), int> merged = {};
        for (final item in saleItems) {
          final key = (item.productId, item.batchId != null ? int.tryParse(item.batchId!) : null);
          merged.update(key, (q) => q + item.quantity.toInt(), ifAbsent: () => item.quantity.toInt());
        }

        // 批量写入出库明细
        if (merged.isNotEmpty) {
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
          await db.batch((batch) {
            batch.insertAll(db.outboundItem, companions);
          });
        }
      }

      // 3) 扣减或回补库存 + 写库存流水（允许负库存）
      for (final item in saleItems) {
        final ok = isSaleMode
            ? await inventoryService.outbound(
                productId: item.productId,
                shopId: shopId,
                quantity: item.quantity.toInt(),
                batchId: item.batchId != null ? int.tryParse(item.batchId!) : null,
                time: now,
              )
            : await inventoryService.inbound(
                productId: item.productId,
                shopId: shopId,
                quantity: item.quantity.toInt(),
                batchId: item.batchId != null ? int.tryParse(item.batchId!) : null,
                time: now,
              );
        if (!ok) {
          // 若库存记录不存在导致更新不到，抛错使事务回滚
          throw StateError('Inventory operation failed for product ${item.productId}');
        }
      }

      final receiptNumber = 'SALE-${now.millisecondsSinceEpoch}';
      print('Sale successful. Receipt number: $receiptNumber');
      return receiptNumber;
    });
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