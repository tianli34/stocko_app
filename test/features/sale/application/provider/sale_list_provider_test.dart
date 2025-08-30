import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stocko_app/features/sale/application/provider/sale_list_provider.dart';
import 'package:stocko_app/features/sale/domain/model/sale_cart_item.dart';
import 'package:stocko_app/features/product/domain/model/product.dart';

void main() {
  group('SaleListNotifier', () {
    late SaleListNotifier notifier;

    setUp(() {
      notifier = SaleListNotifier();
    });

    test('addItem 将新项添加到列表头部', () {
      final item1 = SaleCartItem(
        id: 'a',
        productId: 1,
        productName: '商品A',
        unitId: 1,
        unitName: '件',
        sellingPriceInCents: 1000,
        quantity: 1,
        amount: 10.0,
      );
      final item2 = SaleCartItem(
        id: 'b',
        productId: 2,
        productName: '商品B',
        unitId: 1,
        unitName: '件',
        sellingPriceInCents: 2000,
        quantity: 1,
        amount: 20.0,
      );

      notifier.addItem(item1);
      notifier.addItem(item2);

      expect(notifier.state.map((e) => e.id).toList(), ['b', 'a']);
    });

    test('addAllItems 将多个项按原顺序逆序后插入到头部', () {
      final existing = SaleCartItem(
        id: 'existing',
        productId: 99,
        productName: '已有',
        unitId: 1,
        unitName: '件',
        sellingPriceInCents: 500,
        quantity: 1,
        amount: 5.0,
      );
      notifier.addItem(existing);

      final items = [
        SaleCartItem(
          id: 'a',
          productId: 1,
          productName: 'A',
          unitId: 1,
          unitName: '件',
          sellingPriceInCents: 1000,
          quantity: 1,
          amount: 10.0,
        ),
        SaleCartItem(
          id: 'b',
          productId: 2,
          productName: 'B',
          unitId: 1,
          unitName: '件',
          sellingPriceInCents: 2000,
          quantity: 1,
          amount: 20.0,
        ),
      ];

      notifier.addAllItems(items);
      expect(notifier.state.map((e) => e.id).toList(), ['b', 'a', 'existing']);
    });

    test('removeItem 根据ID移除', () {
      final item = SaleCartItem(
        id: 'x',
        productId: 1,
        productName: 'X',
        unitId: 1,
        unitName: '件',
        sellingPriceInCents: 100,
        quantity: 1,
        amount: 1.0,
      );
      notifier.addItem(item);
      expect(notifier.state.length, 1);
      notifier.removeItem('x');
      expect(notifier.state, isEmpty);
    });

    test('updateItem 替换匹配ID项', () {
      final item = SaleCartItem(
        id: 'u',
        productId: 1,
        productName: 'U',
        unitId: 1,
        unitName: '件',
        sellingPriceInCents: 100,
        quantity: 1,
        amount: 1.0,
      );
      notifier.addItem(item);
      final updated = item.copyWith(quantity: 2, amount: 2.0);
      notifier.updateItem(updated);
      expect(notifier.state.single.quantity, 2);
      expect(notifier.state.single.amount, 2.0);
    });

    test('addOrUpdateItem 按条码合并数量', () {
      final product = ProductModel(id: 1, name: 'P', baseUnitId: 1);

      notifier.addOrUpdateItem(
        product: product,
        unitId: 1,
        unitName: '件',
        barcode: '6900001',
        sellingPriceInCents: 1000,
      );
      notifier.addOrUpdateItem(
        product: product,
        unitId: 1,
        unitName: '件',
        barcode: '6900001',
        sellingPriceInCents: 1000,
      );

      expect(notifier.state.length, 1);
      final only = notifier.state.first;
      expect(only.quantity, 2);
      // 更新路径的 amount = (quantity) * price / 100
      expect(only.amount, 2 * 1000 / 100);
    });

    test('addOrUpdateItem 按 productId+unitId 合并，batchId 不同不合并', () {
      final product = ProductModel(id: 2, name: 'Q', baseUnitId: 1);

      notifier.addOrUpdateItem(
        product: product,
        unitId: 1,
        unitName: '件',
        sellingPriceInCents: 500,
        batchId: '101',
      );
      notifier.addOrUpdateItem(
        product: product,
        unitId: 1,
        unitName: '件',
        sellingPriceInCents: 500,
        batchId: '102',
      );

      expect(notifier.state.length, 2);
    });

    test('addOrUpdateItem 按 productId+unitId 合并，batchId 相同才合并', () {
      final product = ProductModel(id: 3, name: 'R', baseUnitId: 1);

      notifier.addOrUpdateItem(
        product: product,
        unitId: 2,
        unitName: '箱',
        sellingPriceInCents: 1200,
        batchId: 'B01',
      );
      notifier.addOrUpdateItem(
        product: product,
        unitId: 2,
        unitName: '箱',
        sellingPriceInCents: 1200,
        batchId: 'B01',
      );

      expect(notifier.state.length, 1);
      final only = notifier.state.first;
      expect(only.quantity, 2);
    });
  });

  group('saleTotalsProvider', () {
    test('正确计算种类、数量与金额', () {
      final container = ProviderContainer(overrides: []);
      addTearDown(container.dispose);

      final notifier = container.read(saleListProvider.notifier);
      notifier.addAllItems([
        SaleCartItem(
          id: 'a', productId: 1, productName: 'A', unitId: 1, unitName: '件', sellingPriceInCents: 1000, quantity: 2, amount: 20.0,
        ),
        SaleCartItem(
          id: 'b', productId: 2, productName: 'B', unitId: 1, unitName: '件', sellingPriceInCents: 500, quantity: 3.5, amount: 17.5,
        ),
      ]);

      final totals = container.read(saleTotalsProvider);
      expect(totals['varieties'], 2);
      expect(totals['quantity'], 5.5);
      expect(totals['amount'], 37.5);
    });
  });
}
