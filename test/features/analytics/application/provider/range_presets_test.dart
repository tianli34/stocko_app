import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stocko_app/features/analytics/application/provider/range_presets.dart';
import 'package:stocko_app/features/analytics/application/provider/ranking_providers.dart';

// 一个帮助组件：在首帧构建完成后调用 applyPreset，避免在 build 期间修改 provider。
class _ApplyPresetAfterBuild extends ConsumerStatefulWidget {
  const _ApplyPresetAfterBuild({required this.preset});
  final RangePreset preset;

  @override
  ConsumerState<_ApplyPresetAfterBuild> createState() => _ApplyPresetAfterBuildState();
}

class _ApplyPresetAfterBuildState extends ConsumerState<_ApplyPresetAfterBuild> {
  bool _ran = false;
  @override
  void initState() {
    super.initState();
    // 推迟到首帧之后，避免在构建期间修改 provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_ran) return;
      _ran = true;
      applyPreset(ref, widget.preset);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('applyPreset', () {
    testWidgets('today: 设置为[今日0点, 明日0点) 开区间', (tester) async {
      RankingRange? range;
      await tester.pumpWidget(ProviderScope(
        child: Column(
          children: [
            const _ApplyPresetAfterBuild(preset: RangePreset.today),
            Consumer(builder: (context, ref, _) {
              range = ref.watch(rankingRangeProvider);
              return const SizedBox.shrink();
            }),
          ],
        ),
      ));
      // 触发首帧后的回调并让 provider 完成更新
      await tester.pump();

      expect(range, isNotNull);
      final r = range!;
      // endOpen 是明日0点，start 是今日0点
      final startOfEndOpenDay = DateTime(r.endOpen.year, r.endOpen.month, r.endOpen.day);
      expect(r.start, startOfEndOpenDay.subtract(const Duration(days: 1)));
      expect(r.endOpen.difference(r.start).inHours, 24);
    });

    testWidgets('last7Days: 设置为近7天 [end-7, end) 开区间', (tester) async {
      RankingRange? range;
      await tester.pumpWidget(ProviderScope(
        child: Column(
          children: [
            const _ApplyPresetAfterBuild(preset: RangePreset.last7Days),
            Consumer(builder: (context, ref, _) {
              range = ref.watch(rankingRangeProvider);
              return const SizedBox.shrink();
            }),
          ],
        ),
      ));
      await tester.pump();

      expect(range, isNotNull);
      expect(range!.endOpen.difference(range!.start).inDays, 7);
    });

    testWidgets('thisMonth: 设置为当月 [1号, 下月1号) 开区间', (tester) async {
      RankingRange? range;
      await tester.pumpWidget(ProviderScope(
        child: Column(
          children: [
            const _ApplyPresetAfterBuild(preset: RangePreset.thisMonth),
            Consumer(builder: (context, ref, _) {
              range = ref.watch(rankingRangeProvider);
              return const SizedBox.shrink();
            }),
          ],
        ),
      ));
      await tester.pump();

      expect(range, isNotNull);
      final r = range!;
      final start = DateTime(r.start.year, r.start.month, 1);
      expect(r.start, start);
      expect(r.endOpen.isAfter(r.start), isTrue);
    });
  });
}
