import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drift/drift.dart' as drift;

import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/analytics/data/repository/sales_analytics_repository.dart';

class MockAppDatabase extends Mock implements AppDatabase {}
class MockSelectable<T> extends Mock implements drift.Selectable<T> {}
class FakeResultRow extends Fake implements drift.QueryRow {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SalesAnalyticsRepository', () {
    late MockAppDatabase db;
    late SalesAnalyticsRepository repo;

    setUp(() {
      db = MockAppDatabase();
      repo = SalesAnalyticsRepository(db);
    });

    test('watchProductSalesRanking: 应该调用 customSelect 并返回流', () async {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 31);

      final selectable = MockSelectable<drift.QueryRow>();
      when(() => selectable.watch()).thenAnswer((_) => const Stream.empty());

      // stub customSelect 返回我们伪造的 selectable
      when(() => db.customSelect(any(), variables: any(named: 'variables'), readsFrom: any(named: 'readsFrom')))
          .thenReturn(selectable);

      final stream = repo.watchProductSalesRanking(start: start, end: end);
      expect(stream, isA<Stream>());

      verify(() => db.customSelect(any(), variables: any(named: 'variables'), readsFrom: any(named: 'readsFrom'))).called(1);
    });
  });
}
