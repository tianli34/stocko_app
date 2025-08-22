import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repository/sales_analytics_repository.dart';
import '../../domain/model/product_sales_ranking.dart';

// 时间筛选模式
enum TimeFilterMode {
  daily('每天'),
  weekly('每周'),
  monthly('每月');

  const TimeFilterMode(this.label);
  final String label;
}

// 时间范围 Provider
class RankingRange {
  final DateTime start;
  final DateTime endOpen;
  const RankingRange(this.start, this.endOpen);
}

final rankingRangeProvider = StateProvider<RankingRange>((ref) {
  final now = DateTime.now();
  final endOpen = DateTime(now.year, now.month, now.day).add(const Duration(days: 1)); // 明日 00:00
  final start = endOpen.subtract(const Duration(days: 7)); // 近7天
  return RankingRange(start, endOpen);
});

// 时间筛选模式 Provider
final timeFilterModeProvider = StateProvider<TimeFilterMode>((ref) => TimeFilterMode.daily);

// 选中的日期 Provider
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// 选中的周范围 Provider
final selectedWeekRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

// 选中的月份 Provider
final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

// 排序方式（销量/利润）
final rankingSortProvider = StateProvider<ProductRankingSort>((ref) => ProductRankingSort.byQtyDesc);

// 排行榜 Provider（Stream/Query on demand -> Future）
final productSalesRankingProvider = StreamProvider<List<ProductSalesRanking>>((ref) {
  final range = ref.watch(rankingRangeProvider);
  final sort = ref.watch(rankingSortProvider);
  final repo = ref.watch(salesAnalyticsRepositoryProvider);
  // 只按销量排序、只展示有销量；监听数据库变化
  return repo.watchProductSalesRanking(start: range.start, end: range.endOpen, sort: sort);
});
