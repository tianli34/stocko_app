import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../../core/constants/app_routes.dart';
import '../../application/provider/customer_providers.dart';
import '../../data/dao/sales_transaction_dao.dart';
import '../../data/dao/sales_transaction_item_dao.dart';
import '../../../../core/database/database.dart';
import '../../../product/data/repository/product_repository.dart'
    show watchProductByIdProvider;

// Provider for SalesTransactionDao
final salesTransactionDaoProvider = Provider<SalesTransactionDao>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.salesTransactionDao;
});

// Provider for SalesTransactionItemDao
final salesTransactionItemDaoProvider = Provider<SalesTransactionItemDao>((
  ref,
) {
  final database = ref.watch(appDatabaseProvider);
  return database.salesTransactionItemDao;
});

// Provider to watch all sales transactions
final salesTransactionsProvider = StreamProvider<List<SalesTransactionData>>((
  ref,
) {
  final dao = ref.watch(salesTransactionDaoProvider);
  // Sort by created date descending
  return dao.watchAllSalesTransactions().map(
    (sales) => sales..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
  );
});

// Provider to get items for a specific sale
final salesTransactionItemsProvider =
    FutureProvider.family<List<SalesTransactionItemData>, String>((
      ref,
      saleId,
    ) {
      final dao = ref.watch(salesTransactionItemDaoProvider);
      return dao.findSalesTransactionItemsByTransactionId(saleId);
    });

// Provider to get unit name by unit ID
final unitNameByIdProvider = FutureProvider.family<String?, int>((ref, unitId) async {
  final database = ref.watch(appDatabaseProvider);
  final unitDao = database.unitDao;
  final unit = await unitDao.getUnitById(unitId);
  return unit?.name;
});

class SalesRecordsScreen extends ConsumerWidget {
  const SalesRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('销售记录'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.saleCreate),
            icon: const Icon(Icons.add),
            tooltip: '新建销售单',
          ),
        ],
      ),
      body: salesAsync.when(
        data: (sales) {
          if (sales.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '暂无销售订单',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sales.length,
            itemBuilder: (context, index) {
              final sale = sales[index];
              return SaleOrderCard(sale: sale);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('加载失败: $error')),
      ),
    );
  }
}

class SaleOrderCard extends ConsumerWidget {
  final SalesTransactionData sale;

  const SaleOrderCard({super.key, required this.sale});

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(allCustomersProvider);
    final itemsAsync = ref.watch(
      salesTransactionItemsProvider(sale.id.toString()),
    );

    Widget cardContent = Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: InkWell(
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: EdgeInsets.zero,
          shape: const Border(),
          title: Row(
            children: [
              Text(
                '销售单号: ${sale.id}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (sale.status == 'credit') ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '赊账',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              if (sale.status == 'settled') ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '已结清',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatDateTime(sale.createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              customersAsync.when(
                data: (customers) {
                  final customer = customers
                      .where((c) => c.id == sale.customerId)
                      .firstOrNull;
                  return Text('客户: ${customer?.name ?? '未知'}');
                },
                loading: () => const Text('客户: 加载中...'),
                error: (_, __) => const Text('客户: 加载失败'),
              ),
            ],
          ),
          trailing: itemsAsync.when(
            data: (items) {
              final totalAmount = items.fold<double>(
                0,
                (sum, item) => sum + (item.priceInCents * item.quantity),
              );
              final totalQuantity = items.fold<int>(
                0,
                (sum, item) => sum + item.quantity,
              );
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '￥${(totalAmount / 100).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
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
                    .map((item) => SaleOrderItemTile(item: item))
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

    // 只有赊账单才能左滑显示销账按钮
    Widget content;
    if (sale.status == 'credit') {
      content = Slidable(
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (context) {
                _handleSettlePayment(context, ref);
              },
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              icon: Icons.check_circle,
              label: '销账',
              borderRadius: BorderRadius.circular(12),
              padding: EdgeInsets.zero,
              autoClose: true,
              flex: 1,
            ),
          ],
        ),
        child: cardContent,
      );
    } else {
      content = cardContent;
    }

    return Container(margin: const EdgeInsets.all(4.0), child: content);
  }

  Future<void> _handleSettlePayment(BuildContext context, WidgetRef ref) async {
    final dao = ref.read(salesTransactionDaoProvider);
    final success = await dao.updateSalesTransactionStatus(sale.id, 'settled');

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('销账成功'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('销账失败，请重试'), backgroundColor: Colors.red),
      );
    }
  }
}

class SaleOrderItemTile extends ConsumerWidget {
  final SalesTransactionItemData item;

  const SaleOrderItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(watchProductByIdProvider(item.productId));
    final unitNameAsync = item.unitId != null 
        ? ref.watch(unitNameByIdProvider(item.unitId!))
        : const AsyncValue.data('');

    return ListTile(
      contentPadding: const EdgeInsets.only(
        left: 3,
        right: 16,
        top: 0,
        bottom: 0,
      ),
      minVerticalPadding: 0,
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -3),
      minLeadingWidth: 0,
      title: Row(
        children: [
          Text(' ${item.id}  ', style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Expanded(
            child: productAsync.when(
              data: (product) => Text(
                product?.name ?? '货品ID: ${item.productId}',
                style: const TextStyle(fontSize: 16),
              ),
              loading: () => const Text('加载中...'),
              error: (err, stack) => Text(
                '加载货品失败',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
          const SizedBox(width: 8),
          unitNameAsync.when(
            data: (unitName) => Text(
              unitName ?? '',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '￥${(item.priceInCents / 100).toStringAsFixed(2)} × ${item.quantity.toInt()}',
          ),
          Text(
            '￥${(item.priceInCents * item.quantity / 100).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
