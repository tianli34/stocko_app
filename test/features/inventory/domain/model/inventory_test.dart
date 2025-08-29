import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/inventory/domain/model/inventory.dart';

void main() {
  group('StockModel Test', () {
    final now = DateTime.now();
    final stock = StockModel(
      id: 1,
      productId: 101,
      quantity: 100,
      shopId: 1,
      batchId: 1,
      createdAt: now,
      updatedAt: now,
    );

    test('create factory should create a new stock record', () {
      final newStock = StockModel.create(
        productId: 102,
        quantity: 50,
        shopId: 2,
      );

      expect(newStock.id, isNull);
      expect(newStock.productId, 102);
      expect(newStock.quantity, 50);
      expect(newStock.shopId, 2);
      expect(newStock.batchId, isNull);
      expect(newStock.createdAt, isA<DateTime>());
      expect(newStock.updatedAt, isA<DateTime>());
    });

    test('updateQuantity should return a new instance with updated quantity and time', () {
      final updatedStock = stock.updateQuantity(120);

      expect(updatedStock.id, stock.id);
      expect(updatedStock.quantity, 120);
      expect(updatedStock.updatedAt, isNot(stock.updatedAt));
    });

    test('fromJson and toJson should work correctly', () {
      final json = stock.toJson();
      final fromJsonStock = StockModel.fromJson(json);

      expect(fromJsonStock.id, stock.id);
      expect(fromJsonStock.productId, stock.productId);
      expect(fromJsonStock.quantity, stock.quantity);
      expect(fromJsonStock.shopId, stock.shopId);
      expect(fromJsonStock.batchId, stock.batchId);
      expect(fromJsonStock.createdAt?.toIso8601String(), stock.createdAt?.toIso8601String());
      expect(fromJsonStock.updatedAt?.toIso8601String(), stock.updatedAt?.toIso8601String());
    });
  });
}