import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/inventory_query_providers.dart';
import '../widgets/inventory_item_card.dart';
import '../widgets/inventory_filter_bar.dart';

/// 库存查询页面
/// 展示商品库存信息，支持筛选功能
class InventoryQueryScreen extends ConsumerWidget {
  const InventoryQueryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsyncValue = ref.watch(inventoryQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('库存查询'),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回',
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          PopupMenuButton<InventorySortType>(
            onSelected: (InventorySortType sortType) {
              ref.read(inventoryFilterProvider.notifier).updateSortBy(sortType);
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<InventorySortType>>[
              const PopupMenuItem<InventorySortType>(
                value: InventorySortType.byQuantity,
                child: Text('按库存数量排序'),
              ),
              const PopupMenuItem<InventorySortType>(
                value: InventorySortType.byShelfLife,
                child: Text('按剩余保质期排序'),
              ),
              const PopupMenuItem<InventorySortType>(
                value: InventorySortType.none,
                child: Text('默认排序'),
              ),
            ],
            icon: const Icon(Icons.sort),
            tooltip: '排序方式',
          ),
        ],
      ),
      bottomNavigationBar: null,
      body: Column(
        children: [
          // 筛选栏
          const InventoryFilterBar(),

          // 商品列表
          Expanded(
            child: inventoryAsyncValue.when(
              data: (inventoryList) {
                if (inventoryList.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '暂无库存数据',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: inventoryList.length,
                  itemBuilder: (context, index) {
                    final inventory = inventoryList[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InventoryItemCard(inventory: inventory),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '加载库存数据失败',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(inventoryQueryProvider);
                      },
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
