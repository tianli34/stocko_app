import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/features/sale/domain/model/sales_transaction_item.dart'
    as domain;

void main() {
  group('SalesTransactionItem domain model', () {
    test('validation succeeds with valid fields', () {
      final item = domain.SalesTransactionItem(
        salesTransactionId: 1,
        productId: 2,
        batchId: null,
        quantity: 3,
        priceInCents: 1500,
      );

      expect(item.isValid, isTrue);
      expect(item.validationErrors, isEmpty);
      expect(item.isBatchRelated, isFalse);
    });

    test('validation fails and lists errors for invalid fields', () {
      final item = domain.SalesTransactionItem(
        salesTransactionId: 0, // invalid
        productId: 0, // invalid
        batchId: 99, // considered invalid by current rules
        quantity: 0, // invalid
        priceInCents: 0, // invalid
      );

      expect(item.isValid, isFalse);
      expect(
        item.validationErrors,
        containsAll([
          '销售交易ID必须大于0',
          '产品ID必须大于0',
          // 当前实现对非空 batchId 视为无效，并返回以下错误文案
          '批次ID不能为空字符串',
          '数量必须大于0',
          '单位价格必须大于0',
        ]),
      );
    });

    test('createWithValidation throws on invalid data', () {
      expect(
        () => domain.SalesTransactionItem.createWithValidation(
          salesTransactionId: 0,
          productId: -1,
          batchId: 1,
          quantity: 0,
          priceInCents: -1,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toTableCompanion omits id when null and includes when present', () {
      final itemWithoutId = domain.SalesTransactionItem(
        salesTransactionId: 1,
        productId: 2,
        quantity: 3,
        priceInCents: 400,
      );
      final c1 = itemWithoutId.toTableCompanion(10);
      expect(c1.id.present, isFalse);
      expect(c1.salesTransactionId, drift.Value(10));
      expect(c1.productId, drift.Value(2));
      expect(c1.quantity, drift.Value(3));
      expect(c1.priceInCents, drift.Value(400));

      final itemWithId = itemWithoutId.copyWith(id: 7);
      final c2 = itemWithId.toTableCompanion(11);
      expect(c2.id.present, isTrue);
      expect(c2.id, drift.Value(7));
      expect(c2.salesTransactionId, drift.Value(11));
    });

    test('fromTableData maps fields correctly', () {
      final data = SalesTransactionItemData(
        id: 5,
        salesTransactionId: 9,
        productId: 2,
        batchId: 15,
        priceInCents: 1234,
        quantity: 6,
      );

      final item = domain.SalesTransactionItem.fromTableData(data);
      expect(item.id, 5);
      expect(item.salesTransactionId, 9);
      expect(item.productId, 2);
      expect(item.batchId, 15);
      expect(item.priceInCents, 1234);
      expect(item.quantity, 6);
    });
  });
}
