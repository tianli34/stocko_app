import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ranking_providers.dart';

enum RangePreset { today, last7Days, thisMonth, custom }

final rangePresetProvider = StateProvider<RangePreset>((ref) => RangePreset.last7Days);

void applyPreset(WidgetRef ref, RangePreset preset) {
  final now = DateTime.now();
  switch (preset) {
    case RangePreset.today:
      final start = DateTime(now.year, now.month, now.day);
      ref.read(rankingRangeProvider.notifier).state = RankingRange(start, start.add(const Duration(days: 1)));
      break;
    case RangePreset.last7Days:
      final endOpen = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
      final start = endOpen.subtract(const Duration(days: 7));
      ref.read(rankingRangeProvider.notifier).state = RankingRange(start, endOpen);
      break;
    case RangePreset.thisMonth:
      final start = DateTime(now.year, now.month, 1);
      final nextMonth = (now.month == 12)
          ? DateTime(now.year + 1, 1, 1)
          : DateTime(now.year, now.month + 1, 1);
      ref.read(rankingRangeProvider.notifier).state = RankingRange(start, nextMonth);
      break;
    case RangePreset.custom:
      // 由调用方弹窗选择
      break;
  }
}
