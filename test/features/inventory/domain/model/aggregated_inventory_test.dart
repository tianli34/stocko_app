import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/inventory/domain/model/aggregated_inventory.dart';

void main() {
  group('InventoryDetail', () {
    test('fromMap should create InventoryDetail from map data', () {
      final map = {
        'id': 1,
        'shopId': 1,
        'shopName': '总店',
        'quantity': 100,
        'batchNumber': 123,
        'productionDate': '2024-01-01T00:00:00.000Z',
        'shelfLifeDays': 365,
        'shelfLifeUnit': 'days',
      };

      final detail = InventoryDetail.fromMap(map);

      expect(detail.stockId, 1);
      expect(detail.shopId, 1);
      expect(detail.shopName, '总店');
      expect(detail.quantity, 100);
      expect(detail.batchNumber, '123');
      expect(detail.shelfLifeDays, 365);
      expect(detail.remainingDays, isNotNull);
    });

    test('fromMap should handle missing batch information', () {
      final map = {'id': 1, 'shopId': 1, 'shopName': '总店', 'quantity': 100};

      final detail = InventoryDetail.fromMap(map);

      expect(detail.stockId, 1);
      expect(detail.batchId, isNull);
      expect(detail.batchNumber, isNull);
      expect(detail.productionDate, isNull);
      expect(detail.remainingDays, isNull);
    });

    test('fromMap should calculate remaining days correctly', () {
      final now = DateTime.now();
      final productionDate = now.subtract(const Duration(days: 100));

      final map = {
        'id': 1,
        'shopId': 1,
        'shopName': '总店',
        'quantity': 100,
        'productionDate': productionDate.toIso8601String(),
        'shelfLifeDays': 365,
      };

      final detail = InventoryDetail.fromMap(map);

      expect(detail.remainingDays, isNotNull);
      expect(detail.remainingDays, closeTo(265, 1)); // 365 - 100 ≈ 265
    });

    test('batchDisplayText should return formatted production date', () {
      final detail = InventoryDetail(
        stockId: 1,
        shopId: 1,
        shopName: '总店',
        quantity: 100,
        productionDate: DateTime(2024, 1, 15),
      );

      expect(detail.batchDisplayText, '2024-01-15');
    });

    test('batchDisplayText should return "-" if no production date', () {
      final detail = InventoryDetail(
        stockId: 1,
        shopId: 1,
        shopName: '总店',
        quantity: 100,
      );

      expect(detail.batchDisplayText, '-');
    });

    test('remainingDaysDisplayText should show correct text for expired', () {
      final detail = InventoryDetail(
        stockId: 1,
        shopId: 1,
        shopName: '总店',
        quantity: 100,
        remainingDays: -5,
      );

      expect(detail.remainingDaysDisplayText, '已过期');
    });

    test('remainingDaysDisplayText should show remaining days', () {
      final detail = InventoryDetail(
        stockId: 1,
        shopId: 1,
        shopName: '总店',
        quantity: 100,
        remainingDays: 15,
      );

      expect(detail.remainingDaysDisplayText, '剩余15天');
    });

    test('shelfLifeColorStatus should return correct status', () {
      final expiredDetail = InventoryDetail(
        stockId: 1,
        shopId: 1,
        shopName: '总店',
        quantity: 100,
        remainingDays: -1,
      );
      expect(expiredDetail.shelfLifeColorStatus, 'expired');

      final criticalDetail = InventoryDetail(
        stockId: 1,
        shopId: 1,
        shopName: '总店',
        quantity: 100,
        remainingDays: 5,
      );
      expect(criticalDetail.shelfLifeColorStatus, 'critical');

      final warningDetail = InventoryDetail(
        stockId: 1,
        shopId: 1,
        shopName: '总店',
        quantity: 100,
        remainingDays: 20,
      );
      expect(warningDetail.shelfLifeColorStatus, 'warning');

      final normalDetail = InventoryDetail(
        stockId: 1,
        shopId: 1,
        shopName: '总店',
        quantity: 100,
        remainingDays: 100,
      );
      expect(normalDetail.shelfLifeColorStatus, 'normal');
    });

    test(
      'isExpiringSoon should return true for items expiring within 30 days',
      () {
        final detail = InventoryDetail(
          stockId: 1,
          shopId: 1,
          shopName: '总店',
          quantity: 100,
          remainingDays: 20,
        );

        expect(detail.isExpiringSoon, isTrue);
      },
    );

    test('isExpired should return true for expired items', () {
      final detail = InventoryDetail(
        stockId: 1,
        shopId: 1,
        shopName: '总店',
        quantity: 100,
        remainingDays: -5,
      );

      expect(detail.isExpired, isTrue);
    });
  });

  group('AggregatedInventoryItem', () {
    test('fromInventoryList should aggregate inventory correctly', () {
      final inventoryItems = [
        {
          'id': 1,
          'productId': 1,
          'productName': '可口可乐',
          'productImage': '/path/to/image.jpg',
          'quantity': 100,
          'unit': '瓶',
          'shopId': 1,
          'shopName': '总店',
          'categoryId': 1,
          'categoryName': '饮料',
        },
        {
          'id': 2,
          'productId': 1,
          'productName': '可口可乐',
          'productImage': '/path/to/image.jpg',
          'quantity': 50,
          'unit': '瓶',
          'shopId': 2,
          'shopName': '分店A',
          'categoryId': 1,
          'categoryName': '饮料',
        },
      ];

      final aggregated = AggregatedInventoryItem.fromInventoryList(
        inventoryItems,
      );

      expect(aggregated.productId, 1);
      expect(aggregated.productName, '可口可乐');
      expect(aggregated.totalQuantity, 150); // 100 + 50
      expect(aggregated.unit, '瓶');
      expect(aggregated.details.length, 2);
    });

    test('fromInventoryList should throw error for empty list', () {
      expect(
        () => AggregatedInventoryItem.fromInventoryList([]),
        throwsArgumentError,
      );
    });

    test('fromInventoryList should handle missing category', () {
      final inventoryItems = [
        {
          'id': 1,
          'productId': 1,
          'productName': '测试产品',
          'quantity': 100,
          'shopId': 1,
          'shopName': '总店',
        },
      ];

      final aggregated = AggregatedInventoryItem.fromInventoryList(
        inventoryItems,
      );

      expect(aggregated.categoryName, '未分类');
      expect(aggregated.categoryId, isNull);
    });

    test('minRemainingDays should return minimum remaining days', () {
      final aggregated = AggregatedInventoryItem(
        productId: 1,
        productName: '可口可乐',
        totalQuantity: 150,
        unit: '瓶',
        categoryName: '饮料',
        details: [
          InventoryDetail(
            stockId: 1,
            shopId: 1,
            shopName: '总店',
            quantity: 100,
            remainingDays: 200,
          ),
          InventoryDetail(
            stockId: 2,
            shopId: 2,
            shopName: '分店A',
            quantity: 50,
            remainingDays: 50,
          ),
        ],
      );

      expect(aggregated.minRemainingDays, 50);
    });

    test('minRemainingDays should return null if no shelf life info', () {
      final aggregated = AggregatedInventoryItem(
        productId: 1,
        productName: '可口可乐',
        totalQuantity: 150,
        unit: '瓶',
        categoryName: '饮料',
        details: [
          InventoryDetail(stockId: 1, shopId: 1, shopName: '总店', quantity: 100),
        ],
      );

      expect(aggregated.minRemainingDays, isNull);
    });

    test(
      'hasExpiringSoon should return true if any batch expires within 30 days',
      () {
        final aggregated = AggregatedInventoryItem(
          productId: 1,
          productName: '可口可乐',
          totalQuantity: 150,
          unit: '瓶',
          categoryName: '饮料',
          details: [
            InventoryDetail(
              stockId: 1,
              shopId: 1,
              shopName: '总店',
              quantity: 100,
              remainingDays: 200,
            ),
            InventoryDetail(
              stockId: 2,
              shopId: 2,
              shopName: '分店A',
              quantity: 50,
              remainingDays: 20,
            ),
          ],
        );

        expect(aggregated.hasExpiringSoon, isTrue);
      },
    );

    test('hasExpired should return true if any batch is expired', () {
      final aggregated = AggregatedInventoryItem(
        productId: 1,
        productName: '可口可乐',
        totalQuantity: 150,
        unit: '瓶',
        categoryName: '饮料',
        details: [
          InventoryDetail(
            stockId: 1,
            shopId: 1,
            shopName: '总店',
            quantity: 100,
            remainingDays: 200,
          ),
          InventoryDetail(
            stockId: 2,
            shopId: 2,
            shopName: '分店A',
            quantity: 50,
            remainingDays: -5,
          ),
        ],
      );

      expect(aggregated.hasExpired, isTrue);
    });

    test('toJson and fromJson should work correctly', () {
      final aggregated = AggregatedInventoryItem(
        productId: 1,
        productName: '可口可乐',
        productImage: '/path/to/image.jpg',
        totalQuantity: 150,
        unit: '瓶',
        categoryId: 1,
        categoryName: '饮料',
        details: [
          InventoryDetail(stockId: 1, shopId: 1, shopName: '总店', quantity: 100),
        ],
      );

      final json = aggregated.toJson();
      final fromJsonAggregated = AggregatedInventoryItem.fromJson(json);

      expect(fromJsonAggregated.productId, aggregated.productId);
      expect(fromJsonAggregated.productName, aggregated.productName);
      expect(fromJsonAggregated.totalQuantity, aggregated.totalQuantity);
      expect(fromJsonAggregated.details.length, aggregated.details.length);
    });
  });
}
