import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/purchase/domain/model/purchase_order.dart';
import 'package:stocko_app/features/purchase/domain/model/purchase_order_item.dart';
import 'package:stocko_app/core/database/database.dart';
import 'package:stocko_app/core/database/purchase_orders_table.dart';
import 'package:drift/drift.dart' show Value;

void main() {
  group('PurchaseOrderModel', () {
    final now = DateTime.now();
    final purchaseOrderData = PurchaseOrderData(
      id: 1,
      supplierId: 10,
      shopId: 100,
      status: PurchaseOrderStatus.completed,
      createdAt: now,
      updatedAt: now,
    );

    final purchaseOrderItem = PurchaseOrderItemModel(
      id: 1,
      purchaseOrderId: 1,
      productId: 1,
      quantity: 10,
      unitPriceInCents: 100,
    );

    test('should have preset status and empty items list by default', () {
      // Act
      final model = PurchaseOrderModel(supplierId: 1, shopId: 1);

      // Assert
      expect(model.status, PurchaseOrderStatus.preset);
      expect(model.items, isEmpty);
    });

    test('toTableCompanion should convert model to PurchaseOrderCompanion', () {
      // Arrange
      final model = PurchaseOrderModel(
        id: 1,
        supplierId: 10,
        shopId: 100,
        status: PurchaseOrderStatus.completed,
        createdAt: now,
        updatedAt: now,
      );

      // Act
      final companion = model.toTableCompanion();

      // Assert
      expect(companion.id, const Value(1));
      expect(companion.supplierId, const Value(10));
      expect(companion.shopId, const Value(100));
      expect(companion.status, const Value(PurchaseOrderStatus.completed));
      expect(companion.createdAt, Value(now));
      expect(companion.updatedAt, Value(now));
    });

    test('fromTableData should create a model from PurchaseOrderData', () {
      // Act
      final model = PurchaseOrderModel.fromTableData(
        purchaseOrderData,
        items: [purchaseOrderItem],
      );

      // Assert
      expect(model.id, 1);
      expect(model.supplierId, 10);
      expect(model.shopId, 100);
      expect(model.status, PurchaseOrderStatus.completed);
      expect(model.createdAt, now);
      expect(model.updatedAt, now);
      expect(model.items, [purchaseOrderItem]);
    });

    test('fromJson should create a model from a map', () {
      // Arrange
      final json = {
        'id': 2,
        'supplierId': 20,
        'shopId': 200,
        'status': 'draft', // Assuming status is serialized as a string
        'items': [
          {
            'id': 1,
            'purchaseOrderId': 2,
            'productId': 1,
            'quantity': 10,
            'unitPriceInCents': 100,
          }
        ]
      };

      // Act
      final model = PurchaseOrderModel.fromJson(json);

      // Assert
      expect(model.id, 2);
      expect(model.supplierId, 20);
      expect(model.shopId, 200);
      expect(model.status, PurchaseOrderStatus.draft);
      expect(model.items.first.id, 1);
    });
  });
}