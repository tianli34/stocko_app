import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/outbound/domain/model/outbound_item.dart';
import 'package:stocko_app/features/outbound/domain/model/outbound_receipt.dart';

void main() {
  group('OutboundReceiptModel', () {
    final now = DateTime.now();
    final initialReceipt = OutboundReceiptModel(
      shopId: 1,
      reason: 'Test',
      createdAt: now,
      items: const [
        OutboundItemModel(productId: 1, batchId: 10, quantity: 5),
        OutboundItemModel(productId: 2, quantity: 10),
      ],
    );

    test('createDraft should create a valid draft receipt', () {
      final draft = OutboundReceiptModel.createDraft(shopId: 1, reason: 'Draft');
      expect(draft.id, isNull);
      expect(draft.shopId, 1);
      expect(draft.reason, 'Draft');
      expect(draft.items, isEmpty);
    });

    test('totalQuantity should calculate the sum of item quantities correctly', () {
      expect(initialReceipt.totalQuantity, 15);
    });

    group('upsertItem', () {
      test('should add a new item if it does not exist', () {
        const newItem = OutboundItemModel(productId: 3, quantity: 7);
        final updatedReceipt = initialReceipt.upsertItem(newItem);

        expect(updatedReceipt.items, hasLength(3));
        expect(updatedReceipt.items.last.productId, 3);
        expect(updatedReceipt.items.last.quantity, 7);
      });

      test('should merge quantities if an item with the same key exists', () {
        const existingItem = OutboundItemModel(productId: 1, batchId: 10, quantity: 3);
        final updatedReceipt = initialReceipt.upsertItem(existingItem);
        
        expect(updatedReceipt.items, hasLength(2));
        final mergedItem = updatedReceipt.items.firstWhere((it) => it.productId == 1);
        expect(mergedItem.quantity, 8); // 5 + 3
      });
    });

    group('removeItem', () {
      test('should remove an existing item by its key', () {
        const itemToRemove = OutboundItemModel(productId: 2, quantity: 10);
        final updatedReceipt = initialReceipt.removeItem(itemToRemove);
        
        expect(updatedReceipt.items, hasLength(1));
        expect(updatedReceipt.items.any((it) => it.productId == 2), isFalse);
      });
    });

    group('updateItem', () {
      test('should update an existing item with a new one by its key', () {
        const itemToUpdate = OutboundItemModel(productId: 2, quantity: 99);
        final updatedReceipt = initialReceipt.updateItem(itemToUpdate);

        expect(updatedReceipt.items, hasLength(2));
        final updatedItem = updatedReceipt.items.firstWhere((it) => it.productId == 2);
        expect(updatedItem.quantity, 99);
      });
    });
  });
}