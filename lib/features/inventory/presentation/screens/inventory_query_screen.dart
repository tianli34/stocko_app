import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stocko_app/features/inventory/domain/model/inventory.dart';
import 'package:stocko_app/features/product/domain/model/product.dart';
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
      body: inventoryAsyncValue.when(
        data: (inventoryListRaw) {
          final inventoryList = inventoryListRaw
              .map((e) => StockModel.fromJson(e))
              .toList();

          // 计算总数量
          final totalQuantity = inventoryList.fold<double>(
            0,
            (previousValue, element) => previousValue + element.quantity,
          );

          // 计算总价值
          final totalValue = inventoryList.fold<double>(
            0,
            (previousValue, element) {
              final productJson = element.toJson()['product'];
              if (productJson is Map<String, dynamic>) {
                 final product = ProductModel.fromJson(productJson);
                 return previousValue +
                  (element.quantity * (product.retailPrice?.cents ?? 0) / 100);
              }
              return previousValue;
            }
          );

          return Column(
            children: [
              // 筛选栏
              const InventoryFilterBar(),

              // Summary section
              if (inventoryList.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem('货品种数', '${inventoryList.length}'),
                      _buildSummaryItem('总数量', totalQuantity.toStringAsFixed(2)),
                      _buildSummaryItem('总价值', '¥${totalValue.toStringAsFixed(2)}'),
                    ],
                  ),
                ),

              // 商品列表
              Expanded(
                child: inventoryList.isEmpty
                    ? const Center(
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
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: inventoryList.length,
                        itemBuilder: (context, index) {
                          final inventory = inventoryList[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InventoryItemCard(inventory: inventory),
                          );
                        },
                      ),
              ),
            ],
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
    );
  }

  Widget _buildSummaryItem(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
