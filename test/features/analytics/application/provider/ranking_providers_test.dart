import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stocko_app/features/analytics/application/provider/ranking_providers.dart';
import 'package:stocko_app/features/analytics/data/repository/sales_analytics_repository.dart';
import 'package:stocko_app/features/analytics/domain/model/product_sales_ranking.dart';

class MockSalesAnalyticsRepository extends Mock
    implements SalesAnalyticsRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('productSalesRankingProvider', () {
    late MockSalesAnalyticsRepository mockRepo;
    late ProviderContainer container;

    final fixedStart = DateTime(2024, 1, 10);
    final fixedEnd = DateTime(2024, 1, 17); // 开区间上界

    setUp(() {
      mockRepo = MockSalesAnalyticsRepository();
      container = ProviderContainer(overrides: [
        salesAnalyticsRepositoryProvider.overrideWithValue(mockRepo),
        rankingRangeProvider.overrideWith((ref) => RankingRange(fixedStart, fixedEnd)),
        rankingSortProvider.overrideWith((ref) => ProductRankingSort.byQtyDesc),
      ]);
      addTearDown(container.dispose);
    });

    test('应按给定 range/sort 监听仓库并转发流数据', () async {
      final controller = StreamController<List<ProductSalesRanking>>();
      when(() => mockRepo.watchProductSalesRanking(
            start: fixedStart,
            end: fixedEnd,
            sort: ProductRankingSort.byQtyDesc,
            limit: any(named: 'limit'),
          )).thenAnswer((_) => controller.stream);

      final values = <List<ProductSalesRanking>>[];
      final sub = container.read(productSalesRankingProvider.stream).listen(values.add);

      // 模拟仓库推送两次结果
      final sample = [
        const ProductSalesRanking(
          productId: 1,
          name: '苹果',
          sku: 'A1',
          totalQty: 5,
          totalAmountInCents: 1500,
          totalProfitInCents: 500,
          missingCostCount: 0,
        ),
      ];
      controller.add(sample);
      controller.add(const []);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(values.length, 2);
      expect(values.first.first.totalAmountYuan, 15.0);
      expect(values.first.first.totalProfitYuan, 5.0);
      expect(values[1], isEmpty);

      await sub.cancel();
      await controller.close();

      verify(() => mockRepo.watchProductSalesRanking(
            start: fixedStart,
            end: fixedEnd,
            sort: ProductRankingSort.byQtyDesc,
            limit: any(named: 'limit'),
          )).called(1);
    });

    test('切换排序应重新监听（byProfitDesc）', () async {
      final controller = StreamController<List<ProductSalesRanking>>();

      // 初次监听 byQtyDesc
      when(() => mockRepo.watchProductSalesRanking(
            start: fixedStart,
            end: fixedEnd,
            sort: ProductRankingSort.byQtyDesc,
            limit: any(named: 'limit'),
          )).thenAnswer((_) => controller.stream);

      // 切换后监听 byProfitDesc
      when(() => mockRepo.watchProductSalesRanking(
            start: fixedStart,
            end: fixedEnd,
            sort: ProductRankingSort.byProfitDesc,
            limit: any(named: 'limit'),
          )).thenAnswer((_) => controller.stream);

      final received = <List<ProductSalesRanking>>[];
      final sub = container.read(productSalesRankingProvider.stream).listen(received.add);

      // 模拟首次发射
      controller.add(const []);
      await Future<void>.delayed(const Duration(milliseconds: 5));

      // 切换排序
      container.read(rankingSortProvider.notifier).state = ProductRankingSort.byProfitDesc;

      // 再次发射
      controller.add(const []);
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(received.length, greaterThanOrEqualTo(2));

      await sub.cancel();
      await controller.close();

      verify(() => mockRepo.watchProductSalesRanking(
            start: fixedStart,
            end: fixedEnd,
            sort: ProductRankingSort.byQtyDesc,
            limit: any(named: 'limit'),
          )).called(greaterThanOrEqualTo(1));
      verify(() => mockRepo.watchProductSalesRanking(
            start: fixedStart,
            end: fixedEnd,
            sort: ProductRankingSort.byProfitDesc,
            limit: any(named: 'limit'),
          )).called(greaterThanOrEqualTo(1));
    });
  });
}
