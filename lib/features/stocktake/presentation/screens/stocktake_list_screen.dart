import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/provider/stocktake_providers.dart';
import '../../domain/model/stocktake_status.dart';
import '../widgets/stocktake_order_card.dart';

/// 盘点记录列表页面
class StocktakeListScreen extends ConsumerWidget {
  const StocktakeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(stocktakeListProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('库存盘点'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/stocktake/create'),
        icon: const Icon(Icons.add),
        label: const Text('新建盘点'),
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无盘点记录',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击右下角按钮创建新盘点',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
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
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: StocktakeOrderCard(
                  order: order,
                  onTap: () => _navigateToDetail(context, order.id!, order.status),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('加载失败: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(stocktakeListProvider(null)),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, int stocktakeId, StocktakeStatus status) {
    switch (status) {
      case StocktakeStatus.draft:
      case StocktakeStatus.inProgress:
        context.push('/stocktake/$stocktakeId/entry');
        break;
      case StocktakeStatus.completed:
        context.push('/stocktake/$stocktakeId/diff');
        break;
      case StocktakeStatus.audited:
        context.push('/stocktake/$stocktakeId');
        break;
    }
  }
}
