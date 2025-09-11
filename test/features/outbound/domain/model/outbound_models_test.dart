import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/outbound/domain/model/models.dart';

void main() {
  group('OutboundItemModel', () {
    test('uniqueKey: 带批次 与 不带批次', () {
      const itemWithBatch = OutboundItemModel(
        id: 1,
        receiptId: 10,
        productId: 2,
        batchId: 99,
        quantity: 1,
      );
      const itemNoBatch = OutboundItemModel(
        id: 2,
        receiptId: 10,
        productId: 2,
        quantity: 1,
      );
      expect(itemWithBatch.uniqueKey(), '10#2#99');
      expect(itemNoBatch.uniqueKey(), '10#2#null');
    });

    test('increase: 数量累加返回新实例', () {
      const item = OutboundItemModel(productId: 1, quantity: 2);
      final inc = item.increase(3);
      expect(inc.quantity, 5);
      expect(item.quantity, 2); // 不可变
    });

    test('attachToReceipt: 回填 receiptId', () {
      const draft = OutboundItemModel(productId: 3, quantity: 4);
      final attached = draft.attachToReceipt(7);
      expect(attached.receiptId, 7);
      expect(draft.receiptId, isNull);
    });
  });

  group('OutboundReceiptModel', () {
    test('createDraft: 默认空 items、时间为 now 近似', () {
      final t = DateTime(2024, 1, 1, 12);
      final draft = OutboundReceiptModel.createDraft(shopId: 1, reason: 'sale', now: t);
      expect(draft.id, isNull);
      expect(draft.items, isEmpty);
      expect(draft.createdAt, t);
      expect(draft.totalQuantity, 0);
    });

    test('upsertItem: 同一唯一键时合并数量', () {
      final base = OutboundReceiptModel.createDraft(shopId: 1, reason: 'sale', now: DateTime(2024));
      const a = OutboundItemModel(productId: 1, quantity: 2); // no batch
      const b = OutboundItemModel(productId: 1, quantity: 3); // same key
      final r1 = base.upsertItem(a);
      final r2 = r1.upsertItem(b);
      expect(r1.items.length, 1);
      expect(r2.items.length, 1);
      expect(r2.items.first.quantity, 5);
      expect(r2.totalQuantity, 5);
    });

    test('upsertItem: 不同唯一键时新增', () {
      final base = OutboundReceiptModel.createDraft(shopId: 1, reason: 'sale', now: DateTime(2024));
      const a = OutboundItemModel(productId: 1, batchId: 1, quantity: 2);
      const b = OutboundItemModel(productId: 1, quantity: 3); // no batch -> different key
      final r = base.upsertItem(a).upsertItem(b);
      expect(r.items.length, 2);
      expect(r.totalQuantity, 5);
    });

    test('removeItem: 按唯一键删除', () {
      final base = OutboundReceiptModel.createDraft(shopId: 1, reason: 'sale', now: DateTime(2024));
      const a = OutboundItemModel(productId: 1, quantity: 2);
      const b = OutboundItemModel(productId: 2, quantity: 3);
      final r = base.upsertItem(a).upsertItem(b);
      final removed = r.removeItem(a);
      expect(removed.items.length, 1);
      expect(removed.items.single.productId, 2);
    });

    test('updateItem: 按唯一键更新', () {
      final base = OutboundReceiptModel.createDraft(shopId: 1, reason: 'sale', now: DateTime(2024));
      const a = OutboundItemModel(productId: 1, quantity: 2);
      final r = base.upsertItem(a);
      final updated = r.updateItem(const OutboundItemModel(productId: 1, quantity: 10));
      expect(updated.items.single.quantity, 10);
      expect(updated.totalQuantity, 10);
    });
  });
}
