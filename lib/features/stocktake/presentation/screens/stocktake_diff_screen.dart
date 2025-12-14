import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/provider/stocktake_providers.dart';
import '../../domain/model/stocktake_status.dart';
import '../widgets/diff_item_card.dart';
import '../widgets/stocktake_summary_bar.dart';

/// 盘点差异确认页面
class StocktakeDiffScreen extends ConsumerWidget {
  final int stocktakeId;

  const StocktakeDiffScreen({super.key, required this.stocktakeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(currentStocktakeProvider(stocktakeId));
    final summaryAsync = ref.watch(stocktakeSummaryProvider(stocktakeId));
    final diffItemsAsync = ref.watch(stocktakeDiffItemsProvider(stocktakeId));
    final isLoading = ref.watch(stocktakeDiffNotifierProvider(stocktakeId));

    return orderAsync.when(
      data: (order) {
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('差异确认')),
            body: const Center(child: Text('盘点单不存在')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('差异确认'),
            centerTitle: true,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          body: Column(
            children: [
              // 汇总栏
              summaryAsync.when(
                data: (summary) => StocktakeSummaryBar(
                  summary: summary,
                  showDiffDetail: true,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // 差异说明
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.orange.withOpacity(0.1),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '以下商品存在库存差异，请确认后调整库存',
                        style: TextStyle(color: Colors.orange[800]),
                      ),
                    ),
                  ],
                ),
              ),

              // 差异项列表
              Expanded(
                child: diffItemsAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 64, color: Colors.green[400]),
                            const SizedBox(height: 16),
                            const Text(
                              '没有差异项',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '所有商品库存与系统一致',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return DiffItemCard(
                          item: item,
                          onReasonChanged: (reason) {
                            ref
                                .read(stocktakeDiffNotifierProvider(stocktakeId)
                                    .notifier)
                                .updateReason(item.id!, reason);
                          },
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
          bottomNavigationBar: _buildBottomBar(context, ref, order, isLoading),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('差异确认')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('差异确认')),
        body: Center(child: Text('加载失败: $error')),
      ),
    );
  }

  Widget _buildBottomBar(
      BuildContext context, WidgetRef ref, dynamic order, bool isLoading) {
    // 已审核状态不显示操作按钮
    if (order.status == StocktakeStatus.audited) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            const SizedBox(width: 8),
            Text(
              '已完成库存调整',
              style: TextStyle(
                color: Colors.green[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('稍后处理'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed:
                  isLoading ? null : () => _confirmAdjustment(context, ref),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('确认调整库存'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAdjustment(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认调整'),
        content: const Text('确定要根据盘点结果调整库存吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('确认调整'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final notifier =
          ref.read(stocktakeDiffNotifierProvider(stocktakeId).notifier);
      final success = await notifier.confirmAdjustment();

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('库存调整成功'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('库存调整失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
