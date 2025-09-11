import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/purchase/domain/model/purchase_order_item.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:drift/drift.dart' show Value;

void main() {
  group('PurchaseOrderItemModel', () {
    const validPurchaseOrderId = 1;
    const validProductId = 101;
    const validQuantity = 10;
    const validUnitPrice = 1500; // 15.00

    test('should be created successfully with valid data', () {
      // Act
      final item = PurchaseOrderItemModel(
        purchaseOrderId: validPurchaseOrderId,
        productId: validProductId,
        quantity: validQuantity,
        unitPriceInCents: validUnitPrice,
      );

      // Assert
      expect(item.isValid, isTrue);
      expect(item.validationErrors, isEmpty);
    });

    test(
        'createWithValidation should throw ArgumentError for invalid purchaseOrderId',
        () {
      // Assert
      expect(
        () => PurchaseOrderItemModel.createWithValidation(
          purchaseOrderId: 0,
          productId: validProductId,
          quantity: validQuantity,
          unitPriceInCents: validUnitPrice,
        ),
        throwsArgumentError,
      );
    });

    test(
        'createWithValidation should throw ArgumentError for invalid productId',
        () {
      // Assert
      expect(
        () => PurchaseOrderItemModel.createWithValidation(
          purchaseOrderId: validPurchaseOrderId,
          productId: 0,
          quantity: validQuantity,
          unitPriceInCents: validUnitPrice,
        ),
        throwsArgumentError,
      );
    });

    test('createWithValidation should throw ArgumentError for invalid quantity',
        () {
      // Assert
      expect(
        () => PurchaseOrderItemModel.createWithValidation(
          purchaseOrderId: validPurchaseOrderId,
          productId: validProductId,
          quantity: 0,
          unitPriceInCents: validUnitPrice,
        ),
        throwsArgumentError,
      );
    });

    test(
        'createWithValidation should throw ArgumentError for negative unit price',
        () {
      // Assert
      expect(
        () => PurchaseOrderItemModel.createWithValidation(
          purchaseOrderId: validPurchaseOrderId,
          productId: validProductId,
          quantity: validQuantity,
          unitPriceInCents: -1,
        ),
        throwsArgumentError,
      );
    });

    test('isValid should be false and validationErrors should not be empty for invalid data', () {
        // Arrange
        final item = PurchaseOrderItemModel(
            purchaseOrderId: 0,
            productId: -1,
            quantity: 0,
            unitPriceInCents: -100,
        );

        // Act & Assert
        expect(item.isValid, isFalse);
        expect(item.validationErrors, isNotEmpty);
        expect(item.validationErrors, contains('采购订单ID必须大于0'));
        expect(item.validationErrors, contains('产品ID必须大于0'));
        expect(item.validationErrors, contains('数量必须大于0'));
        expect(item.validationErrors, contains('单价不能为负数'));
    });

    test('toTableCompanion should convert model to PurchaseOrderItemCompanion',
        () {
      // Arrange
      final now = DateTime.now();
      final item = PurchaseOrderItemModel(
        id: 5,
        purchaseOrderId: 1, // This will be overridden by the method argument
        productId: validProductId,
        quantity: validQuantity,
        unitPriceInCents: validUnitPrice,
        productionDate: now,
      );
      const newOrderId = 2;

      // Act
      final companion = item.toTableCompanion(newOrderId);

      // Assert
      expect(companion.id, const Value(5));
      expect(companion.purchaseOrderId, const Value(newOrderId));
      expect(companion.productId, const Value(validProductId));
      expect(companion.quantity, const Value(validQuantity));
      expect(companion.unitPriceInCents, const Value(validUnitPrice));
      expect(companion.productionDate, Value(now));
    });

    test('fromTableData should create a model from PurchaseOrderItemData', () {
      // Arrange
      final now = DateTime.now();
      final tableData = PurchaseOrderItemData(
        id: 1,
        purchaseOrderId: 2,
        productId: 3,
        unitPriceInCents: 2000,
        quantity: 20,
        productionDate: now,
      );

      // Act
      final model = PurchaseOrderItemModel.fromTableData(tableData);

      // Assert
      expect(model.id, 1);
      expect(model.purchaseOrderId, 2);
      expect(model.productId, 3);
      expect(model.unitPriceInCents, 2000);
      expect(model.quantity, 20);
      expect(model.productionDate, now);
    });

    test('fromJson should create a model from a map', () {
      // Arrange
      final json = {
        'id': 10,
        'purchaseOrderId': 20,
        'productId': 30,
        'unitPriceInCents': 2500,
        'quantity': 5,
      };

      // Act
      final model = PurchaseOrderItemModel.fromJson(json);

      // Assert
      expect(model.id, 10);
      expect(model.purchaseOrderId, 20);
      expect(model.productId, 30);
      expect(model.unitPriceInCents, 2500);
      expect(model.quantity, 5);
    });
  });
}