import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/inbound/domain/model/inbound_item.dart';
import 'package:stocko_app/features/inbound/domain/model/inbound_receipt.dart';

void main() {
  group('InboundReceiptModel', () {
    final now = DateTime.now();
    const shopId = 1;
    const source = 'manual';

    // Factory for a clean draft model for each test
    InboundReceiptModel createDraft() => InboundReceiptModel.createDraft(
          shopId: shopId,
          source: source,
          now: now,
        );

    test('createDraft factory should create a valid preset receipt', () {
      final draft = createDraft();
      expect(draft.shopId, shopId);
      expect(draft.source, source);
      expect(draft.status, InboundReceiptStatus.preset);
      expect(draft.createdAt, now);
      expect(draft.updatedAt, now);
      expect(draft.items, isEmpty);
      expect(draft.isPreset, isTrue);
      expect(draft.isDraft, isFalse);
    });

    group('Status helpers', () {
      test('isPreset should be true for preset status', () {
        final model = createDraft().copyWith(status: InboundReceiptStatus.preset);
        expect(model.isPreset, isTrue);
        expect(model.isDraft, isFalse);
        expect(model.isCompleted, isFalse);
      });

      test('isDraft should be true for draft status', () {
        final model = createDraft().copyWith(status: InboundReceiptStatus.draft);
        expect(model.isPreset, isFalse);
        expect(model.isDraft, isTrue);
        expect(model.isCompleted, isFalse);
      });

      test('isCompleted should be true for completed status', () {
        final model = createDraft().copyWith(status: InboundReceiptStatus.completed);
        expect(model.isPreset, isFalse);
        expect(model.isDraft, isFalse);
        expect(model.isCompleted, isTrue);
      });
    });

    group('Item manipulations', () {
      const item1 = InboundItemModel(productId: 1, quantity: 10);
      const item2 = InboundItemModel(productId: 2, quantity: 5);

      test('upsertItem should add a new item', () {
        var receipt = createDraft();
        receipt = receipt.upsertItem(item1);

        expect(receipt.items, hasLength(1));
        expect(receipt.items.first, item1);
      });

      test('upsertItem should merge quantity for existing item', () {
        var receipt = createDraft().upsertItem(item1); // initial quantity 10
        receipt = receipt.upsertItem(item1.copyWith(quantity: 5)); // add 5 more

        expect(receipt.items, hasLength(1));
        expect(receipt.items.first.quantity, 15);
      });
      
      test('upsertItem should handle multiple distinct items', () {
        var receipt = createDraft().upsertItem(item1);
        receipt = receipt.upsertItem(item2);

        expect(receipt.items, hasLength(2));
        expect(receipt.items, containsAll([item1, item2]));
      });

      test('removeItem should remove an existing item', () {
        var receipt = createDraft().upsertItem(item1).upsertItem(item2);
        receipt = receipt.removeItem(item1);

        expect(receipt.items, hasLength(1));
        expect(receipt.items.first, item2);
      });

      test('removeItem should do nothing if item does not exist', () {
        var receipt = createDraft().upsertItem(item1);
        receipt = receipt.removeItem(item2); // item2 does not exist

        expect(receipt.items, hasLength(1));
        expect(receipt.items.first, item1);
      });

      test('updateItem should replace an existing item', () {
        var receipt = createDraft().upsertItem(item1);
        final updatedItem = item1.copyWith(quantity: 99);
        receipt = receipt.updateItem(updatedItem);

        expect(receipt.items, hasLength(1));
        expect(receipt.items.first.quantity, 99);
      });
    });

    group('Computed properties', () {
      test('totalQuantity should calculate sum of item quantities', () {
        var receipt = createDraft()
            .upsertItem(const InboundItemModel(productId: 1, quantity: 10))
            .upsertItem(const InboundItemModel(productId: 2, quantity: 5));
        
        expect(receipt.totalQuantity, 15);
      });

      test('totalQuantity should be 0 for empty items list', () {
        final receipt = createDraft();
        expect(receipt.totalQuantity, 0);
      });
    });

    group('JSON serialization', () {
      test('fromJson/toJson should work correctly with items', () {
        final model = createDraft().upsertItem(const InboundItemModel(productId: 1, quantity: 10));
        
        final json = model.toJson();
        final newModel = InboundReceiptModel.fromJson(json);

        expect(newModel, model);
        expect(newModel.items.first.quantity, 10);
      });
    });
  });
}
