import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/inbound/domain/model/inbound_item.dart';

void main() {
  group('InboundItemModel', () {
    const productId = 1;
    const initialQuantity = 10;

    // A basic model instance for testing
    const baseModel = InboundItemModel(
      productId: productId,
      quantity: initialQuantity,
    );

    test('should be created correctly', () {
      expect(baseModel.productId, productId);
      expect(baseModel.quantity, initialQuantity);
      expect(baseModel.id, isNull);
      expect(baseModel.receiptId, isNull);
      expect(baseModel.batchId, isNull);
    });

    test('should throw assertion error if quantity is not positive', () {
      expect(
        () => InboundItemModel(productId: productId, quantity: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => InboundItemModel(productId: productId, quantity: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    group('uniqueKey', () {
      test('should generate correct key when receiptId and id are null', () {
        const model = InboundItemModel(productId: 1, quantity: 1);
        expect(model.uniqueKey(), 'null#1#null');
      });

      test('should generate correct key when receiptId is not null', () {
        const model = InboundItemModel(receiptId: 100, productId: 1, quantity: 1);
        expect(model.uniqueKey(), '100#1#null');
      });

      test('should generate correct key when receiptId and id are not null', () {
        const model = InboundItemModel(id: 200, receiptId: 100, productId: 1, quantity: 1);
        expect(model.uniqueKey(), '100#1#200');
      });

      test('should use overrideReceiptId when provided', () {
        const model = InboundItemModel(receiptId: 100, productId: 1, quantity: 1);
        expect(model.uniqueKey(overrideReceiptId: 999), '999#1#null');
      });
    });

    group('increase', () {
      test('should return a new instance with increased quantity', () {
        const delta = 5;
        final newModel = baseModel.increase(delta);

        expect(newModel.quantity, initialQuantity + delta);
        // Ensure it's a new instance
        expect(identical(newModel, baseModel), isFalse);
        // Other properties should remain the same
        expect(newModel.productId, baseModel.productId);
      });

      test('should throw assertion error if delta is not positive', () {
        expect(() => baseModel.increase(0), throwsA(isA<AssertionError>()));
        expect(() => baseModel.increase(-1), throwsA(isA<AssertionError>()));
      });
    });

    group('attachToReceipt', () {
      test('should return a new instance with the given receiptId', () {
        const receiptId = 123;
        final newModel = baseModel.attachToReceipt(receiptId);

        expect(newModel.receiptId, receiptId);
        // Ensure it's a new instance
        expect(identical(newModel, baseModel), isFalse);
        // Other properties should remain the same
        expect(newModel.quantity, baseModel.quantity);
      });
    });

    group('JSON serialization', () {
      test('fromJson/toJson should work correctly', () {
        final model = InboundItemModel(
          id: 1,
          receiptId: 10,
          productId: 100,
          batchId: 1000,
          quantity: 10,
        );

        final json = model.toJson();
        final newModel = InboundItemModel.fromJson(json);

        expect(newModel, model);
      });

      test('fromJson/toJson should handle null values', () {
        const model = InboundItemModel(
          productId: 100,
          quantity: 10,
        );

        final json = model.toJson();
        final newModel = InboundItemModel.fromJson(json);

        expect(newModel, model);
      });
    });
  });
}