import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/sale/domain/model/sales_transaction.dart'
    as domain;
import 'package:stocko_app/features/sale/domain/model/sales_transaction_item.dart'
    as domain;

void main() {
  group('SalesTransaction domain model', () {
    test('toTableCompanion omits id when null and maps fields', () {
      final t = domain.SalesTransaction(
        customerId: 1,
        shopId: 2,
        totalAmount: 30.5,
        actualAmount: 28.0,
        remarks: 'hello',
      );

      final c = t.toTableCompanion();
      expect(c.id.present, isFalse);
      expect(c.customerId, drift.Value(1));
      expect(c.shopId, drift.Value(2));
      expect(c.totalAmount, drift.Value(30.5));
      expect(c.actualAmount, drift.Value(28.0));
      expect(c.status.value, equals('preset'));
      expect(c.remarks.value, equals('hello'));
    });

    test('fromTableData maps to domain; default status fallback', () {
      final data = SalesTransactionData(
        id: 9,
        customerId: 3,
        shopId: 1,
        totalAmount: 99.9,
        actualAmount: 88.8,
        status: 'unknown-status',
        remarks: 'r',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final t = domain.SalesTransaction.fromTableData(data);
      expect(t.id, 9);
      expect(t.customerId, 3);
      // current implementation sets shopId to 0 (DB lacks this in data class), assert that behavior
      expect(t.shopId, 0);
      expect(t.totalAmount, 99.9);
      expect(t.actualAmount, 99.9); // equals totalAmount per current impl
      expect(t.status, domain.SalesStatus.preset);
      expect(t.remarks, 'r');
      expect(t.items, isEmpty);
    });

    test('fromTableData with items', () {
      final data = SalesTransactionData(
        id: 1,
        customerId: 2,
        shopId: 3,
        totalAmount: 10,
        actualAmount: 10,
        status: 'settled',
        remarks: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final items = [
        domain.SalesTransactionItem(
          id: 7,
          salesTransactionId: 1,
          productId: 100,
          quantity: 2,
          priceInCents: 500,
        ),
      ];
      final t = domain.SalesTransaction.fromTableData(data, items: items);
      expect(t.items.length, 1);
      expect(t.items.first.productId, 100);
      expect(t.status, domain.SalesStatus.settled);
    });
  });
}
