import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../../application/provider/supplier_providers.dart';
import '../../data/dao/purchase_dao.dart';
import '../../../../core/database/database.dart';
import '../../../product/data/repository/product_repository.dart';

// Provider for PurchaseDao
final purchaseDaoProvider = Provider<PurchaseDao>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.purchaseDao;
});

// Provider to watch all purchase orders
final purchaseOrdersProvider = StreamProvider<List<PurchaseOrderData>>((
  ref,
) {
  final dao = ref.watch(purchaseDaoProvider);
  // Sort by purchase date descending
  return dao.watchAllPurchaseOrders().map(
    (orders) =>
        orders..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
  );
});

// Provider to get items for a specific order
final purchaseOrderItemsProvider =
    FutureProvider.family<List<PurchaseOrderItemData>, int>((
      ref,
      orderId,
    ) {
      final dao = ref.watch(purchaseDaoProvider);
      return dao.getPurchaseOrderItems(orderId);
    });

class PurchaseRecordsScreen extends ConsumerWidget {
  const PurchaseRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(purchaseOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('采购记录'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.purchaseCreate),
            icon: const Icon(Icons.add),
            tooltip: '新建采购单',
          ),
        ],
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '暂无采购订单',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return PurchaseOrderCard(order: order);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('加载失败: $error')),
      ),
    );
  }
}

class PurchaseOrderCard extends ConsumerWidget {
  final PurchaseOrderData order;

  const PurchaseOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(allSuppliersProvider);
    final itemsAsync = ref.watch(purchaseOrderItemsProvider(order.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        child: ExpansionTile(
          title: Text(
            '订单号: ${order.id}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('日期: ${order.createdAt.toString().substring(0, 10)}'),
              suppliersAsync.when(
                data: (suppliers) {
                  final supplier = suppliers
                      .where((s) => s.id == order.supplierId)
                      .firstOrNull;
                  return Text('供应商: ${supplier?.name ?? '未知'}');
                },
                loading: () => const Text('供应商: 加载中...'),
                error: (_, __) => const Text('供应商: 加载失败'),
              ),
            ],
          ),
          trailing: itemsAsync.when(
            data: (items) {
              final totalAmount = items.fold<double>(
                0,
                (sum, item) => sum + (item.unitPriceInCents * item.quantity),
              );
              final totalQuantity = items.fold<double>(
                0,
                (sum, item) => sum + item.quantity,
              );
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '￥${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    '${totalQuantity.toInt()}件',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => const Icon(Icons.error, color: Colors.red),
          ),
          children: [
            itemsAsync.when(
              data: (items) => Column(
                children: items
                    .map((item) => PurchaseOrderItemTile(item: item))
                    .toList(),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, s) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(child: Text('加载明细失败: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PurchaseOrderItemTile extends ConsumerWidget {
  final PurchaseOrderItemData item;

  const PurchaseOrderItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productByIdProvider(item.productId));
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
      title: productAsync.when(
        data: (product) => Text(product?.name ?? '货品ID: ${item.productId}'),
        loading: () => const Text('加载中...'),
        error: (err, stack) => Text(
          '加载货品失败',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      subtitle: item.productionDate != null
          ? Text('生产日期: ${item.productionDate!.toString().substring(0, 10)}')
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '￥${item.unitPriceInCents.toStringAsFixed(2)} × ${item.quantity.toInt()}',
          ),
          Text(
            '￥${(item.unitPriceInCents * item.quantity).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
