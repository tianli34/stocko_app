import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/inbound/application/provider/inbound_list_provider.dart';
import 'package:stocko_app/features/product/domain/model/product.dart';

void main() {
  group('InboundListNotifier', () {
    test('addItem/addAllItems/removeItem/updateItem works', () {
      final notifier = InboundListNotifier();

      final a = InboundItemState(
        id: 'a',
        productId: 1,
        productName: 'A',
        unitId: 1,
        unitName: '个',
        quantity: 1,
        unitPriceInSis: 10000000, // 100元 = 100 * 100,000丝
        conversionRate: 1,
      );
      final b = InboundItemState(
        id: 'b',
        productId: 2,
        productName: 'B',
        unitId: 1,
        unitName: '个',
        quantity: 2,
        unitPriceInSis: 20000000, // 200元 = 200 * 100,000丝
        conversionRate: 1,
      );

      notifier.addItem(a);
      expect(notifier.state.length, 1);
      notifier.addAllItems([b]);
      expect(notifier.state.length, 2);

      // update
      final a2 = a.copyWith(quantity: 5);
      notifier.updateItem(a2);
      expect(notifier.state.firstWhere((e) => e.id == 'a').quantity, 5);

      // remove
      notifier.removeItem('b');
      expect(notifier.state.length, 1);

      // clear
      notifier.clear();
      expect(notifier.state, isEmpty);
    });

    test('addOrUpdateItem: merge by barcode first, fallback to productId+unitId', () {
      final notifier = InboundListNotifier();
      final product = ProductModel(
        id: 10,
        name: 'Coke',
        baseUnitId: 1,
        enableBatchManagement: false,
      );

      // First add with barcode
      notifier.addOrUpdateItem(
        product: product,
        unitId: 1,
        unitName: '瓶',
        barcode: '6900001',
        conversionRate: 1,
      );
      expect(notifier.state.length, 1);
      expect(notifier.state.first.quantity, 1);

      // Same barcode -> quantity increase
      notifier.addOrUpdateItem(
        product: product,
        unitId: 1,
        unitName: '瓶',
        barcode: '6900001',
        conversionRate: 1,
      );
      expect(notifier.state.first.quantity, 2);

  // Different barcode but same product+unit -> still merges by fallback to product+unit
      notifier.addOrUpdateItem(
        product: product,
        unitId: 1,
        unitName: '瓶',
        barcode: '6900002',
        conversionRate: 1,
      );
  expect(notifier.state.length, 1);
  expect(notifier.state.first.quantity, 3);

      // Fallback: no barcode, should match existing product+unit and increase the first matched line
      notifier.addOrUpdateItem(
        product: product,
        unitId: 1,
        unitName: '瓶',
        conversionRate: 1,
      );
  // quantity increased again on the same line
  final totalQty = notifier.state.fold<int>(0, (s, e) => s + e.quantity);
  expect(totalQty, 4);
    });
  });
}
