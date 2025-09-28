import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../analytics/application/provider/ranking_providers.dart';
import '../../../analytics/data/repository/sales_analytics_repository.dart';
import '../widgets/time_filter_bottom_sheet.dart';

class ProductRankingScreen extends ConsumerWidget {
  const ProductRankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(productSalesRankingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('商品排行榜'),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final range = ref.watch(rankingRangeProvider);
              final timeFilterText = _getTimeFilterText(range);
              return TextButton.icon(
                onPressed: () => _showTimeFilterBottomSheet(context),
                icon: const Icon(Icons.calendar_today, size: 20),
                label: Text(timeFilterText),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              );
            },
          ),
        ],
      ),
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
                      title: Text(
                        it.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(it.sku ?? ''),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${it.totalQty} 件',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '￥${(it.totalAmountInCents / 100).toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasMissingCost)
                                const Tooltip(
                                  message: '无采购记录，利润按0计算',
                                  child: Icon(
                                    Icons.info_outline,
                                    size: 14,
                                    color: Colors.orange,
                                  ),
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
          onSelected: (_) => ref.read(rankingSortProvider.notifier).state =
              ProductRankingSort.byQtyDesc,
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('按利润'),
          selected: sort == ProductRankingSort.byProfitDesc,
          onSelected: (_) => ref.read(rankingSortProvider.notifier).state =
              ProductRankingSort.byProfitDesc,
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

// 获取时间筛选显示文本
String _getTimeFilterText(RankingRange range) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final start = DateTime(range.start.year, range.start.month, range.start.day);
  final end = DateTime(
    range.endOpen.year,
    range.endOpen.month,
    range.endOpen.day,
  ).subtract(const Duration(days: 1));

  // 检查是否是今天
  if (start == today && end == today) {
    return '今天';
  }

  // 检查是否是昨天
  if (start == yesterday && end == yesterday) {
    return '昨天';
  }

  // 检查是否是本周
  final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 6));
  if (start == startOfWeek && end == endOfWeek) {
    return now.year == start.year ? '本周' : '${start.year}年本周';
  }

  // 检查是否是上周
  final startOfLastWeek = startOfWeek.subtract(const Duration(days: 7));
  final endOfLastWeek = startOfWeek.subtract(const Duration(days: 1));
  if (start == startOfLastWeek && end == endOfLastWeek) {
    return now.year == start.year ? '上周' : '${start.year}年上周';
  }

  // 检查是否是本月
  final startOfMonth = DateTime(today.year, today.month, 1);
  final endOfMonth = DateTime(
    today.year,
    today.month + 1,
    1,
  ).subtract(const Duration(days: 1));
  if (start == startOfMonth && end == endOfMonth) {
    return now.year == start.year ? '本月' : '${start.year}年本月';
  }

  // 检查是否是上月
  final startOfLastMonth = DateTime(today.year, today.month - 1, 1);
  final endOfLastMonth = DateTime(
    today.year,
    today.month,
    1,
  ).subtract(const Duration(days: 1));
  if (start == startOfLastMonth && end == endOfLastMonth) {
    return now.year == start.year ? '上月' : '${start.year}年上月';
  }

  // 检查是否是最近7天
  if (end == today && start == today.subtract(const Duration(days: 6))) {
    return now.year == start.year ? '近7天' : '${start.year}年近7天';
  }

  // 检查是否是最近30天
  if (end == today && start == today.subtract(const Duration(days: 29))) {
    return now.year == start.year ? '近30天' : '${start.year}年近30天';
  }

  // 如果是同一天，显示日期
  if (start == end) {
    return now.year == start.year
        ? '${start.month}月${start.day}日'
        : '${start.year}年${start.month}月${start.day}日';
  }

  // 如果是同一月，显示月日-日
  if (start.year == end.year && start.month == end.month) {
    return now.year == start.year
        ? '${start.month}月${start.day}-${end.day}日'
        : '${start.year}年${start.month}月${start.day}-${end.day}日';
  }

  // 如果是同一年，显示月日-月日
  if (start.year == end.year) {
    return now.year == start.year
        ? '${start.month}月${start.day}-${end.month}月${end.day}日'
        : '${start.year}年${start.month}月${start.day}-${end.month}月${end.day}日';
  }

  // 其他情况，显示完整日期范围
  return '${start.year}/${start.month}/${start.day}-${end.year}/${end.month}/${end.day}';
}

// 显示时间筛选底部面板
void _showTimeFilterBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const TimeFilterBottomSheet(),
  );
}
