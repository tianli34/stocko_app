import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../../application/provider/supplier_providers.dart';
import 'purchase_records_screen.dart';

final purchaseDetailProvider =
    StreamProvider.family<List<PurchasesTableData>, String>((
      ref,
      purchaseNumber,
    ) {
      final dao = ref.watch(purchaseDaoProvider);
      return dao.watchAllPurchases().map(
        (purchases) =>
            purchases.where((p) => p.purchaseNumber == purchaseNumber).toList(),
      );
    });

class PurchaseDetailScreen extends ConsumerWidget {
  final String purchaseNumber;

  const PurchaseDetailScreen({super.key, required this.purchaseNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseItemsAsync = ref.watch(
      purchaseDetailProvider(purchaseNumber),
    );
    final suppliersAsync = ref.watch(allSuppliersProvider);

    return Scaffold(
      appBar: AppBar(title: Text('采购单: $purchaseNumber')),
      body: purchaseItemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '未找到采购明细',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final totalAmount = items.fold<double>(
            0,
            (sum, item) => sum + (item.unitPrice * item.quantity),
          );
          final totalQuantity = items.fold<double>(
            0,
            (sum, item) => sum + item.quantity,
          );

          return Column(
            children: [
              // 采购单头部信息
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '采购单号: $purchaseNumber',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '日期: ${items.first.purchaseDate.toString().substring(0, 10)}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    suppliersAsync.when(
                      data: (suppliers) {
                        final supplier = suppliers
                            .where((s) => s.id == items.first.supplierId)
                            .firstOrNull;
                        return Text(
                          '供应商: ${supplier?.name ?? '未知'}',
                          style: const TextStyle(fontSize: 14),
                        );
                      },
                      loading: () => const Text('供应商: 加载中...'),
                      error: (_, __) => const Text('供应商: 加载失败'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '总金额: ￥${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '总数量: ${totalQuantity.toInt()}件',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 明细列表
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final itemTotal = item.unitPrice * item.quantity;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.productId,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Text(
                                  '￥${itemTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '单价: ￥${item.unitPrice.toStringAsFixed(2)}',
                                  ),
                                ),
                                Expanded(
                                  child: Text('数量: ${item.quantity.toInt()}'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '生产日期: ${item.productionDate.toString().substring(0, 10)}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('加载失败: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.refresh(purchaseDetailProvider(purchaseNumber)),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
