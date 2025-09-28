import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/inventory_query_providers.dart';
import '../widgets/inventory_filter_bar.dart';
import '../../../../core/widgets/cached_image_widget.dart';

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
          // 直接使用返回的Map数据，不需要转换为StockModel
          final inventoryList = inventoryListRaw;

          // 计算总数量
          final totalQuantity = inventoryList.fold<int>(
            0,
            (previousValue, element) => previousValue + (element['quantity'] as num).toInt(),
          );

          // 计算总价值 - 注意：需要从产品数据中获取价格信息
          // 由于当前数据结构中没有包含价格信息，暂时设为0
          // 如果需要显示总价值，需要在InventoryQueryService中添加价格信息
          final totalValue = inventoryList.fold<double>(
            0,
            (previousValue, element) => previousValue + (element['quantity'] as num) * (element['purchasePrice'] as num? ?? 0) / 100,
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
                      _buildSummaryItem('品种', '${inventoryList.length}'),
                      _buildSummaryItem('总数', '$totalQuantity'),
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
                          final inventoryData = inventoryList[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildInventoryCard(inventoryData),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 4),
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

  /// 构建库存卡片
  Widget _buildInventoryCard(Map<String, dynamic> inventoryData) {
    final productName = inventoryData['productName'] as String? ?? '未知商品';
    final productImage = inventoryData['productImage'] as String?;
    final quantity = (inventoryData['quantity'] as num?)?.toInt() ?? 0;
    final unit = inventoryData['unit'] as String? ?? '个';
    final shopName = inventoryData['shopName'] as String? ?? '未知店铺';
    final categoryName = inventoryData['categoryName'] as String? ?? '未分类';

    // 根据库存数量确定状态
    final stockStatus = _getStockStatus(quantity);

    // 计算保质期（如果有批次信息）
    String? shelfLifeText;
    if (inventoryData['productionDate'] != null && 
        inventoryData['shelfLifeDays'] != null &&
        inventoryData['shelfLifeUnit'] != null) {
      try {
        final productionDate = DateTime.parse(inventoryData['productionDate'] as String);
        final shelfLifeDays = inventoryData['shelfLifeDays'] as int;
        final shelfLifeUnit = inventoryData['shelfLifeUnit'] as String;
        
        int shelfLifeInDays;
        switch (shelfLifeUnit) {
          case 'days':
            shelfLifeInDays = shelfLifeDays;
            break;
          case 'months':
            shelfLifeInDays = shelfLifeDays * 30;
            break;
          case 'years':
            shelfLifeInDays = shelfLifeDays * 365;
            break;
          default:
            shelfLifeInDays = shelfLifeDays;
        }
        
        final expiryDate = productionDate.add(Duration(days: shelfLifeInDays));
        final remainingDays = expiryDate.difference(DateTime.now()).inDays;

        if (remainingDays <= 0) {
          shelfLifeText = '已过期';
        } else {
          shelfLifeText = '剩余: $remainingDays 天';
        }
      } catch (e) {
        // 如果日期解析失败，忽略保质期显示
        shelfLifeText = null;
      }
    }

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 商品图片
            productImage != null && productImage.isNotEmpty
                ? ProductThumbnailImage(imagePath: productImage)
                : Container(
                    width: 60,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.image_outlined,
                      color: Colors.grey.shade400,
                      size: 30,
                    ),
                  ),
            const SizedBox(width: 16),

            // 商品信息和库存
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 商品名称
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // 分类和店铺信息
                  Text(
                    '$categoryName · $shopName',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  if (shelfLifeText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      shelfLifeText,
                      style: TextStyle(
                        fontSize: 12,
                        color: shelfLifeText == '已过期'
                            ? Colors.red
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // 库存信息
                  Row(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$quantity',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            unit,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),

                      // 库存状态指示器
                      _buildStatusIndicator(stockStatus),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 根据库存数量获取状态
  _StockStatus _getStockStatus(int quantity) {
    if (quantity <= 0) {
      return _StockStatus.outOfStock;
    } else if (quantity <= 10) {
      return _StockStatus.lowStock;
    } else {
      return _StockStatus.normal;
    }
  }

  /// 构建状态指示器
  Widget _buildStatusIndicator(_StockStatus status) {
    switch (status) {
      case _StockStatus.outOfStock:
        return Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
        );
      case _StockStatus.lowStock:
        return Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
        );
      case _StockStatus.normal:
        return const SizedBox.shrink();
    }
  }
}

/// 库存状态枚举
enum _StockStatus {
  normal,
  lowStock,
  outOfStock,
}
