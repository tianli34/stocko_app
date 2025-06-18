import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stocko_app/features/inventory/presentation/application/inventory_query_service.dart';

void main() {
  group('库存查询功能测试', () {
    test('InventoryQueryService 应该正确创建', () {
      final container = ProviderContainer();

      try {
        final service = container.read(inventoryQueryServiceProvider);
        expect(service, isNotNull);
        expect(service, isA<InventoryQueryService>());
      } finally {
        container.dispose();
      }
    });
  });
}
