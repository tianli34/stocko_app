import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../analytics/application/provider/ranking_providers.dart';
import '../../../analytics/data/repository/sales_analytics_repository.dart';

class ProductRankingScreen extends ConsumerWidget {
  const ProductRankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(productSalesRankingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('商品排行榜')),
      body: Column(
        children: [
          const Divider(height: 1),
          _SortToggle(),
          const Divider(height: 1),
          Expanded(
            child: rankingAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Center(child: Text('暂无销量'));
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final it = list[index];
                    final hasMissingCost = it.missingCostCount > 0;
                    final profitYuan = it.totalProfitInCents / 100.0;
                    final profitColor = hasMissingCost
                        ? Colors.orange
                        : (profitYuan < 0 ? Colors.red : Colors.green);
                    return ListTile(
                      leading: _RankBadge(rank: index + 1),
                      title: Text(it.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(it.sku ?? ''),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${it.totalQty} 件', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('￥${(it.totalAmountInCents / 100).toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasMissingCost)
                                const Tooltip(
                                  message: '无采购记录，利润按0计算',
                                  child: Icon(Icons.info_outline, size: 14, color: Colors.orange),
                                ),
                              const SizedBox(width: 4),
                              Text(
                                '利润 ￥${profitYuan.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: profitColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('加载失败: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(rankingSortProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ChoiceChip(
          label: const Text('按销量'),
          selected: sort == ProductRankingSort.byQtyDesc,
          onSelected: (_) => ref.read(rankingSortProvider.notifier).state = ProductRankingSort.byQtyDesc,
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('按利润'),
          selected: sort == ProductRankingSort.byProfitDesc,
          onSelected: (_) => ref.read(rankingSortProvider.notifier).state = ProductRankingSort.byProfitDesc,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Color bg;
    switch (rank) {
      case 1:
        bg = Colors.amber;
        break;
      case 2:
        bg = Colors.blueGrey;
        break;
      case 3:
        bg = Colors.brown;
        break;
      default:
        bg = colors.primaryContainer;
    }
    return CircleAvatar(
      backgroundColor: bg,
      foregroundColor: Colors.white,
      child: Text('$rank'),
    );
  }
}
