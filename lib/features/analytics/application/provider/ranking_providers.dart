import 'dart:async';
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
// 内部：维护一个稳定的输出流（broadcast），当外部筛选或排序变化时，
// 仅更新与仓库之间的订阅，确保消费者订阅不被打断（避免测试中复用同一单订阅 Stream 时的事件丢失）。
final _productSalesRankingStreamControllerProvider =
    Provider<StreamController<List<ProductSalesRanking>>>((ref) {
  final repo = ref.watch(salesAnalyticsRepositoryProvider);
  final controller = StreamController<List<ProductSalesRanking>>.broadcast();

  StreamSubscription<List<ProductSalesRanking>>? sub;
  Stream<List<ProductSalesRanking>>? lastSrc;

  void resubscribe() {
    final range = ref.read(rankingRangeProvider);
    final sort = ref.read(rankingSortProvider);
    final src = repo.watchProductSalesRanking(
      start: range.start,
      end: range.endOpen,
      sort: sort,
    );
    // 若仓库返回的是同一个单订阅 Stream 实例（测试里可能复用同一个 controller.stream），
    // 不要二次监听，以免抛出 “Stream has already been listened to”。
    if (identical(lastSrc, src)) {
      return; // 保持原订阅，继续接收事件
    }

    // 先尝试建立新订阅，成功后再取消旧订阅，避免对相同单订阅流的二次监听
    StreamSubscription<List<ProductSalesRanking>>? newSub;
    try {
      newSub = src.listen(
        controller.add,
        onError: controller.addError,
        onDone: () {},
        cancelOnError: false,
      );
    } catch (e) {
      // 如果是单订阅流重复监听导致的异常，则保留原订阅，不切换
      final msg = e.toString();
      if (msg.contains('Stream has already been listened to') || e is StateError) {
        return;
      }
      rethrow;
    }

    // 新订阅建立成功，替换并取消旧订阅
    final oldSub = sub;
    sub = newSub;
    lastSrc = src;
    oldSub?.cancel();
  }

  // 初次订阅
  resubscribe();

  // 监听筛选/排序变化，重建与仓库的订阅
  ref.listen<RankingRange>(rankingRangeProvider, (prev, next) {
    // 仅当发生实际变化时重建
    if (prev?.start != next.start || prev?.endOpen != next.endOpen) {
      resubscribe();
    }
  });
  ref.listen<ProductRankingSort>(rankingSortProvider, (prev, next) {
    if (prev != next) {
      resubscribe();
    }
  });

  ref.onDispose(() async {
    await sub?.cancel();
    await controller.close();
  });

  return controller;
});

final productSalesRankingProvider =
    StreamProvider<List<ProductSalesRanking>>((ref) {
  final controller = ref.watch(_productSalesRankingStreamControllerProvider);
  return controller.stream;
});
