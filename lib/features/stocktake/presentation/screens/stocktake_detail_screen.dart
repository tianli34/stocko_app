import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../application/provider/stocktake_providers.dart';
import '../../domain/model/stocktake_status.dart';
import '../widgets/stocktake_summary_bar.dart';

/// 盘点详情页面（已审核的盘点单）
class StocktakeDetailScreen extends ConsumerWidget {
  final int stocktakeId;

  const StocktakeDetailScreen({super.key, required this.stocktakeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(currentStocktakeProvider(stocktakeId));
    final itemsAsync = ref.watch(stocktakeItemsProvider(stocktakeId));
    final summaryAsync = ref.watch(stocktakeSummaryProvider(stocktakeId));

    return orderAsync.when(
      data: (order) {
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('盘点详情')),
            body: const Center(child: Text('盘点单不存在')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('盘点详情'),
            centerTitle: true,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          body: Column(
            children: [
              // 基本信息卡片
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            order.orderNumber,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _buildStatusChip(order.status),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildInfoRow('盘点类型', order.type.displayName),
                      _buildInfoRow(
                        '创建时间',
                        order.createdAt != null
                            ? DateFormat('yyyy-MM-dd HH:mm')
                                .format(order.createdAt!)
                            : '-',
                      ),
                      if (order.completedAt != null)
                        _buildInfoRow(
                          '完成时间',
                          DateFormat('yyyy-MM-dd HH:mm')
                              .format(order.completedAt!),
                        ),
                      if (order.auditedAt != null)
                        _buildInfoRow(
                          '审核时间',
                          DateFormat('yyyy-MM-dd HH:mm')
                              .format(order.auditedAt!),
                        ),
                      if (order.remarks != null && order.remarks!.isNotEmpty)
                        _buildInfoRow('备注', order.remarks!),
                    ],
                  ),
                ),
              ),

              // 汇总栏
              summaryAsync.when(
                data: (summary) => StocktakeSummaryBar(
                  summary: summary,
                  showDiffDetail: true,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // 盘点项列表标题
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text(
                      '盘点明细',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    itemsAsync.when(
                      data: (items) => Text(
                        '共 ${items.length} 项',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              // 盘点项列表
              Expanded(
                child: itemsAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const Center(child: Text('暂无盘点明细'));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(item.productName ?? '商品 #${item.productId}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '系统: ${item.systemQuantity} → 实盘: ${item.actualQuantity}',
                                ),
                                if (item.differenceReason != null)
                                  Text(
                                    '原因: ${item.differenceReason}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                            trailing: _buildDiffBadge(item.differenceQty),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('加载失败: $error')),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('盘点详情')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('盘点详情')),
        body: Center(child: Text('加载失败: $error')),
      ),
    );
  }

  Widget _buildStatusChip(StocktakeStatus status) {
    Color color;
    switch (status) {
      case StocktakeStatus.draft:
        color = Colors.grey;
        break;
      case StocktakeStatus.inProgress:
        color = Colors.blue;
        break;
      case StocktakeStatus.completed:
        color = Colors.orange;
        break;
      case StocktakeStatus.audited:
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildDiffBadge(int diff) {
    if (diff == 0) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 20);
    }

    final isPositive = diff > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPositive
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isPositive ? '+$diff' : '$diff',
        style: TextStyle(
          color: isPositive ? Colors.green : Colors.red,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
