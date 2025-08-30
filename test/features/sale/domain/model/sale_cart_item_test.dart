import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/sale/domain/model/sale_cart_item.dart';

void main() {
  group('SaleCartItem', () {
    test('toJson/fromJson roundtrip', () {
      const item = SaleCartItem(
        id: 'abc',
        productId: 1,
        productName: 'P',
        unitId: 2,
        unitName: '箱',
        batchId: '10',
        sellingPriceInCents: 1200,
        quantity: 3.5,
        amount: 42.0,
      );
      final json = item.toJson();
      final again = SaleCartItem.fromJson(json);
      expect(again, equals(item));
    });
  });
}
