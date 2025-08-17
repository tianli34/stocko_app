import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../../application/provider/supplier_providers.dart';
import 'purchase_records_screen.dart';
import '../../data/dao/purchase_dao.dart';

final purchaseOrderWithItemsProvider =
    StreamProvider.family<PurchaseOrderWithItems, int>((ref, orderId) {
      final dao = ref.watch(purchaseDaoProvider);
      return dao.watchPurchaseOrderWithItems(orderId);
    });

class PurchaseDetailScreen extends ConsumerWidget {
  final String orderId;

  const PurchaseDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderIdInt = int.tryParse(orderId) ?? -1;
    if (orderIdInt == -1) {
      return const Scaffold(body: Center(child: Text('无效的订单ID')));
    }

    final purchaseAsync = ref.watch(purchaseOrderWithItemsProvider(orderIdInt));

    return Scaffold(
      appBar: AppBar(title: const Text('采购订单详情')),
      body: purchaseAsync.when(
        data: (data) {
          final order = data.order;
          final items = data.items;

          if (order.id == -1) {
            return const Center(child: Text('未找到订单'));
          }

          final totalAmount = items.fold<double>(
            0,
            (sum, item) => sum + (item.item.unitPriceInCents * item.item.quantity),
          );
          final totalQuantity = items.fold<double>(
            0,
            (sum, item) => sum + item.item.quantity,
          );

          return Column(
            children: [
              PurchaseDetailHeader(
                order: order,
                totalAmount: totalAmount,
                totalQuantity: totalQuantity,
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final detailedItem = items[index];
                    return PurchaseDetailItemCard(item: detailedItem);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('加载失败: $error')),
      ),
    );
  }
}

class PurchaseDetailHeader extends ConsumerWidget {
  final PurchaseOrderData order;
  final double totalAmount;
  final double totalQuantity;

  const PurchaseDetailHeader({
    super.key,
    required this.order,
    required this.totalAmount,
    required this.totalQuantity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(allSuppliersProvider);

    return Container(
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
                '订单号: ${order.id}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text('日期: ${order.createdAt.toString().substring(0, 10)}'),
            ],
          ),
          const SizedBox(height: 8),
          suppliersAsync.when(
            data: (suppliers) {
              final supplier = suppliers
                  .where((s) => s.id == order.supplierId)
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
    );
  }
}

class PurchaseDetailItemCard extends ConsumerWidget {
  final PurchaseOrderItemWithDetails item;

  const PurchaseDetailItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemTotal = item.item.unitPriceInCents * item.item.quantity;

    // Use the product data from the joined query
    final product = item.product;

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
                    product.name,
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
                  child: Text('单价: ￥${item.item.unitPriceInCents.toStringAsFixed(2)}'),
                ),
                Expanded(child: Text('数量: ${item.item.quantity.toInt()}')),
              ],
            ),
            if (item.item.productionDate != null) ...[
              const SizedBox(height: 4),
              Text(
                '生产日期: ${item.item.productionDate!.toString().substring(0, 10)}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
