import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stocko_app/features/inventory/application/inventory_service.dart';
import 'package:stocko_app/features/sale/data/repository/sales_transaction_repository.dart';

import '../../domain/model/sale_item.dart';
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
    required String shopId,
    required List<SaleItem> saleItems,
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
        unitId: item.unitId,
        batchId: item.batchId,
        quantity: item.quantity.toInt(),
        unitPrice: item.sellingPriceInCents/100,
        totalPrice: item.amount,
      );
    }).toList();

    final transaction = SalesTransaction(
      salesOrderNo: salesOrderNo,
      shopId: shopId,
      totalAmount: totalAmount,
      actualAmount: totalAmount,
      remarks: remarks,
      customerId: customerId ?? 0,
      items: transactionItems,
      status: status,
    );

    await salesTransactionRepository.addSalesTransaction(transaction);

    for (final item in saleItems) {
      if (isSaleMode) {
        await inventoryService.outbound(
          productId: item.productId,
          shopId: shopId,
          quantity: item.quantity,
          time: now,
        );
      } else {
        await inventoryService.inbound(
          productId: item.productId,
          shopId: shopId,
          quantity: item.quantity,
          batchNumber: 'RETURN',
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