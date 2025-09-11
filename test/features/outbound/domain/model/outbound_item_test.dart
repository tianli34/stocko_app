import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/outbound/domain/model/outbound_item.dart';

void main() {
  group('OutboundItemModel', () {
    test('uniqueKey should generate correct key with batchId', () {
      const item = OutboundItemModel(
        receiptId: 1,
        productId: 10,
        batchId: 100,
        quantity: 5,
      );
      expect(item.uniqueKey(), '1#10#100');
    });

    test('uniqueKey should generate correct key without batchId', () {
      const item = OutboundItemModel(
        receiptId: 1,
        productId: 10,
        quantity: 5,
      );
      expect(item.uniqueKey(), '1#10#null');
    });

    test('uniqueKey should use overrideReceiptId when provided', () {
      const item = OutboundItemModel(
        receiptId: 1,
        productId: 10,
        quantity: 5,
      );
      expect(item.uniqueKey(overrideReceiptId: 99), '99#10#null');
    });

    test('increase should return a new instance with increased quantity', () {
      const item = OutboundItemModel(productId: 1, quantity: 5);
      final newItem = item.increase(3);
      expect(newItem.quantity, 8);
      expect(item.quantity, 5); // Original should be immutable
    });

    test('attachToReceipt should return a new instance with receiptId', () {
      const item = OutboundItemModel(productId: 1, quantity: 1);
      final attachedItem = item.attachToReceipt(123);
      expect(attachedItem.receiptId, 123);
    });

    test('should throw assertion error if quantity is not positive', () {
      expect(
        () => OutboundItemModel(productId: 1, quantity: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => OutboundItemModel(productId: 1, quantity: -1),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}