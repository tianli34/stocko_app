import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/inventory/domain/model/inventory_transaction.dart';

void main() {
  group('InventoryTransactionModel', () {
    group('Enum Extensions', () {
      test('InventoryTransactionType displayName', () {
        expect(InventoryTransactionType.inbound.displayName, equals('入库'));
        expect(InventoryTransactionType.outbound.displayName, equals('出库'));
        expect(InventoryTransactionType.adjustment.displayName, equals('调整'));
        expect(InventoryTransactionType.transfer.displayName, equals('调拨'));
        expect(InventoryTransactionType.returned.displayName, equals('退货'));
      });

      test('InventoryTransactionType toDbCode', () {
        expect(InventoryTransactionType.inbound.toDbCode, equals('in'));
        expect(InventoryTransactionType.outbound.toDbCode, equals('out'));
        expect(InventoryTransactionType.adjustment.toDbCode, equals('adjust'));
        expect(InventoryTransactionType.transfer.toDbCode, equals('transfer'));
        expect(InventoryTransactionType.returned.toDbCode, equals('return'));
      });
    });

    group('inventoryTransactionTypeFromDbCode', () {
      test('正确转换数据库编码到枚举', () {
        expect(inventoryTransactionTypeFromDbCode('in'), equals(InventoryTransactionType.inbound));
        expect(inventoryTransactionTypeFromDbCode('out'), equals(InventoryTransactionType.outbound));
        expect(inventoryTransactionTypeFromDbCode('adjust'), equals(InventoryTransactionType.adjustment));
        expect(inventoryTransactionTypeFromDbCode('transfer'), equals(InventoryTransactionType.transfer));
        expect(inventoryTransactionTypeFromDbCode('return'), equals(InventoryTransactionType.returned));
      });

      test('未知编码返回默认值', () {
        expect(inventoryTransactionTypeFromDbCode('unknown'), equals(InventoryTransactionType.inbound));
        expect(inventoryTransactionTypeFromDbCode(''), equals(InventoryTransactionType.inbound));
      });
    });

    group('Factory Constructors', () {
      test('createInbound 创建入库流水', () {
        final transaction = InventoryTransactionModel.createInbound(
          productId: 100,
          quantity: 50,
          shopId: 1,
          batchId: 5,
        );

        expect(transaction.productId, equals(100));
        expect(transaction.type, equals(InventoryTransactionType.inbound));
        expect(transaction.quantity, equals(50));
        expect(transaction.shopId, equals(1));
        expect(transaction.batchId, equals(5));
        expect(transaction.createdAt, isNotNull);
      });

      test('createOutbound 创建出库流水', () {
        final transaction = InventoryTransactionModel.createOutbound(
          productId: 200,
          quantity: 25,
          shopId: 2,
        );

        expect(transaction.productId, equals(200));
        expect(transaction.type, equals(InventoryTransactionType.outbound));
        expect(transaction.quantity, equals(25));
        expect(transaction.shopId, equals(2));
        expect(transaction.batchId, isNull);
        expect(transaction.createdAt, isNotNull);
      });

      test('createAdjustment 创建调整流水', () {
        final transaction = InventoryTransactionModel.createAdjustment(
          productId: 300,
          quantity: -10, // 可以为负数表示减少库存
          shopId: 3,
        );

        expect(transaction.productId, equals(300));
        expect(transaction.type, equals(InventoryTransactionType.adjustment));
        expect(transaction.quantity, equals(-10));
        expect(transaction.shopId, equals(3));
        expect(transaction.batchId, isNull);
        expect(transaction.createdAt, isNotNull);
      });
    });

    group('Getters', () {
      test('typeDisplayName 返回正确的显示名称', () {
        final inbound = InventoryTransactionModel.createInbound(productId: 1, quantity: 1, shopId: 1);
        final outbound = InventoryTransactionModel.createOutbound(productId: 1, quantity: 1, shopId: 1);
        final adjustment = InventoryTransactionModel.createAdjustment(productId: 1, quantity: 1, shopId: 1);

        expect(inbound.typeDisplayName, equals('入库'));
        expect(outbound.typeDisplayName, equals('出库'));
        expect(adjustment.typeDisplayName, equals('调整'));
      });

      test('isInbound, isOutbound, isAdjustment, isTransfer, isReturn 布尔值', () {
        final inbound = InventoryTransactionModel.createInbound(productId: 1, quantity: 1, shopId: 1);
        final outbound = InventoryTransactionModel.createOutbound(productId: 1, quantity: 1, shopId: 1);
        final adjustment = InventoryTransactionModel.createAdjustment(productId: 1, quantity: 1, shopId: 1);

        expect(inbound.isInbound, isTrue);
        expect(inbound.isOutbound, isFalse);
        expect(inbound.isAdjustment, isFalse);
        expect(inbound.isTransfer, isFalse);
        expect(inbound.isReturn, isFalse);

        expect(outbound.isInbound, isFalse);
        expect(outbound.isOutbound, isTrue);
        expect(outbound.isAdjustment, isFalse);

        expect(adjustment.isInbound, isFalse);
        expect(adjustment.isOutbound, isFalse);
        expect(adjustment.isAdjustment, isTrue);
      });
    });

    group('JSON Serialization', () {
      test('fromJson 创建对象的正确性', () {
        final json = {
          'id': 123,
          'productId': 456,
          'type': 'in',
          'quantity': 100,
          'shopId': 2,
          'batchId': 7,
          'createdAt': '2023-01-15T10:30:00.000Z',
        };

        final transaction = InventoryTransactionModel.fromJson(json);
        expect(transaction.id, equals(123));
        expect(transaction.productId, equals(456));
        expect(transaction.type, equals(InventoryTransactionType.inbound));
        expect(transaction.quantity, equals(100));
        expect(transaction.shopId, equals(2));
        expect(transaction.batchId, equals(7));
        expect(transaction.createdAt?.year, equals(2023));
        expect(transaction.createdAt?.month, equals(1));
        expect(transaction.createdAt?.day, equals(15));
      });

      test('toJson 序列化的正确性', () {
        final transaction = InventoryTransactionModel(
          id: 789,
          productId: 999,
          type: InventoryTransactionType.outbound,
          quantity: 50,
          shopId: 3,
          batchId: 15,
          createdAt: DateTime(2023, 6, 20, 14, 45, 30),
        );

        final json = transaction.toJson();
        expect(json['id'], equals(789));
        expect(json['productId'], equals(999));
        expect(json['type'], equals('out'));
        expect(json['quantity'], equals(50));
        expect(json['shopId'], equals(3));
        expect(json['batchId'], equals(15));
        expect(json['createdAt'], isNotNull);
      });
    });

    group('Full Constructor', () {
      test('创建完整对象', () {
        final transaction = InventoryTransactionModel(
          id: 42,
          productId: 12345,
          type: InventoryTransactionType.transfer,
          quantity: 75,
          shopId: 5,
          batchId: 20,
          createdAt: DateTime(2024, 3, 10),
        );

        expect(transaction.id, equals(42));
        expect(transaction.productId, equals(12345));
        expect(transaction.type, equals(InventoryTransactionType.transfer));
        expect(transaction.quantity, equals(75));
        expect(transaction.shopId, equals(5));
        expect(transaction.batchId, equals(20));
        expect(transaction.createdAt, equals(DateTime(2024, 3, 10)));
        expect(transaction.isTransfer, isTrue);
      });

      test('处理空值字段', () {
        final transaction = InventoryTransactionModel(
          productId: 67890,
          type: InventoryTransactionType.returned,
          quantity: 1,
          shopId: 7,
        );

        expect(transaction.id, isNull);
        expect(transaction.productId, equals(67890));
        expect(transaction.type, equals(InventoryTransactionType.returned));
        expect(transaction.quantity, equals(1));
        expect(transaction.shopId, equals(7));
        expect(transaction.batchId, isNull);
        expect(transaction.createdAt, isNull);
        expect(transaction.isReturn, isTrue);
      });
    });

    group('copyWith', () {
      test('修改特定字段', () {
        final original = InventoryTransactionModel.createInbound(
          productId: 111,
          quantity: 30,
          shopId: 1,
          batchId: 5,
        );

        final copied = original.copyWith(
          productId: 222,
          quantity: 60,
          type: InventoryTransactionType.adjustment,
        );

        // 修改的字段
        expect(copied.productId, equals(222));
        expect(copied.quantity, equals(60));
        expect(copied.type, equals(InventoryTransactionType.adjustment));

        // 未修改的字段保持不变
        expect(copied.shopId, equals(original.shopId));
        expect(copied.batchId, equals(original.batchId));
        expect(copied.createdAt, equals(original.createdAt));
      });

      test('设置空值', () {
        final original = InventoryTransactionModel(
          id: 100,
          productId: 111,
          type: InventoryTransactionType.inbound,
          quantity: 30,
          shopId: 1,
          batchId: 5,
          createdAt: DateTime.now(),
        );

        final copied = original.copyWith(
          batchId: null,
          createdAt: null,
        );

        expect(copied.batchId, isNull);
        expect(copied.createdAt, isNull);

        // 其他字段不变
        expect(copied.id, equals(original.id));
        expect(copied.productId, equals(original.productId));
        expect(copied.type, equals(original.type));
        expect(copied.quantity, equals(original.quantity));
        expect(copied.shopId, equals(original.shopId));
      });
    });

    group('Business Logic validation', () {
      test('库存数量可以为负数（用于调整和退货）', () {
        final adjustment = InventoryTransactionModel.createAdjustment(
          productId: 1,
          quantity: -5,
          shopId: 1,
        );

        final returned = InventoryTransactionModel(
          productId: 1,
          type: InventoryTransactionType.returned,
          quantity: -1,
          shopId: 1,
        );

        expect(adjustment.quantity, equals(-5));
        expect(returned.quantity, equals(-1));
      });

      test('入库和出库数量通常为正数', () {
        final inbound = InventoryTransactionModel.createInbound(
          productId: 1,
          quantity: 10,
          shopId: 1,
        );

        final outbound = InventoryTransactionModel.createOutbound(
          productId: 1,
          quantity: 5,
          shopId: 1,
        );

        expect(inbound.quantity, equals(10));
        expect(outbound.quantity, equals(5));
      });

      test('所有必需字段必须提供', () {
        // 这些应该不会编译通过，因为移除了必需的参数
        // final transaction = InventoryTransactionModel();
      });
    });
  });
}