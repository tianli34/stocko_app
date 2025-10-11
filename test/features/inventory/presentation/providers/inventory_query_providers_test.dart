import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/inventory/domain/model/aggregated_inventory.dart';
import 'package:stocko_app/features/inventory/presentation/providers/inventory_query_providers.dart';

void main() {
  group('InventoryFilterNotifier', () {
    test('updateShop 应该更新店铺筛选状态', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(inventoryFilterProvider.notifier).updateShop('总仓');

      final state = container.read(inventoryFilterProvider);
      expect(state.selectedShop, '总仓');
    });

    test('updateShop 传入"所有仓库"应该重置为默认值', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(inventoryFilterProvider.notifier).updateShop('总仓');
      container.read(inventoryFilterProvider.notifier).updateShop('所有仓库');

      final state = container.read(inventoryFilterProvider);
      expect(state.selectedShop, '所有仓库');
    });

    test('updateCategory 应该更新分类筛选状态', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(inventoryFilterProvider.notifier).updateCategory('饮料');

      final state = container.read(inventoryFilterProvider);
      expect(state.selectedCategory, '饮料');
    });

    test('updateStatus 应该更新库存状态筛选', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(inventoryFilterProvider.notifier).updateStatus('低库存');

      final state = container.read(inventoryFilterProvider);
      expect(state.selectedStatus, '低库存');
    });

    test('updateSortBy 应该更新排序方式', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(inventoryFilterProvider.notifier).updateSortBy(InventorySortType.byQuantity);

      final state = container.read(inventoryFilterProvider);
      expect(state.sortBy, InventorySortType.byQuantity);
    });

    test('reset 应该重置所有筛选条件', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(inventoryFilterProvider.notifier).updateShop('总仓');
      container.read(inventoryFilterProvider.notifier).updateCategory('饮料');
      container.read(inventoryFilterProvider.notifier).updateStatus('低库存');
      container.read(inventoryFilterProvider.notifier).updateSortBy(InventorySortType.byQuantity);

      container.read(inventoryFilterProvider.notifier).reset();

      final state = container.read(inventoryFilterProvider);
      expect(state.selectedShop, '所有仓库');
      expect(state.selectedCategory, '所有分类');
      expect(state.selectedStatus, '库存状态');
      expect(state.sortBy, InventorySortType.none);
    });
  });

  group('排序功能测试', () {
    group('聚合数据排序', () {
      test('按数量排序应该正确排序', () {
        // Arrange
        final data = [
          const AggregatedInventoryItem(
            productId: 100,
            productName: '可乐',
            totalQuantity: 80,
            unit: '瓶',
            categoryName: '饮料',
            details: [],
          ),
          const AggregatedInventoryItem(
            productId: 200,
            productName: '雪碧',
            totalQuantity: 30,
            unit: '瓶',
            categoryName: '饮料',
            details: [],
          ),
          const AggregatedInventoryItem(
            productId: 300,
            productName: '芬达',
            totalQuantity: 50,
            unit: '瓶',
            categoryName: '饮料',
            details: [],
          ),
        ];

        // Act - 模拟排序逻辑
        data.sort((a, b) => a.totalQuantity.compareTo(b.totalQuantity));

        // Assert
        expect(data[0].totalQuantity, 30);
        expect(data[1].totalQuantity, 50);
        expect(data[2].totalQuantity, 80);
      });

      test('按保质期排序应该正确排序', () {
        // Arrange
        final now = DateTime.now();
        final data = [
          AggregatedInventoryItem(
            productId: 100,
            productName: '可乐',
            totalQuantity: 80,
            unit: '瓶',
            categoryName: '饮料',
            details: [
              InventoryDetail(
                stockId: 1,
                shopId: 1,
                shopName: '总仓',
                quantity: 80,
                productionDate: now.subtract(const Duration(days: 300)),
                shelfLifeDays: 365,
                remainingDays: 65,
              ),
            ],
          ),
          AggregatedInventoryItem(
            productId: 200,
            productName: '雪碧',
            totalQuantity: 30,
            unit: '瓶',
            categoryName: '饮料',
            details: [
              InventoryDetail(
                stockId: 2,
                shopId: 1,
                shopName: '总仓',
                quantity: 30,
                productionDate: now.subtract(const Duration(days: 350)),
                shelfLifeDays: 365,
                remainingDays: 15,
              ),
            ],
          ),
          AggregatedInventoryItem(
            productId: 300,
            productName: '芬达',
            totalQuantity: 50,
            unit: '瓶',
            categoryName: '饮料',
            details: [
              InventoryDetail(
                stockId: 3,
                shopId: 1,
                shopName: '总仓',
                quantity: 50,
                productionDate: now.subtract(const Duration(days: 330)),
                shelfLifeDays: 365,
                remainingDays: 35,
              ),
            ],
          ),
        ];

        // Act - 模拟按保质期排序逻辑
        data.sort((a, b) {
          final aMinDays = a.minRemainingDays;
          final bMinDays = b.minRemainingDays;
          
          if (aMinDays == null && bMinDays == null) return 0;
          if (aMinDays == null) return 1;
          if (bMinDays == null) return -1;
          
          return aMinDays.compareTo(bMinDays);
        });

        // Assert
        expect(data[0].minRemainingDays, 15);
        expect(data[1].minRemainingDays, 35);
        expect(data[2].minRemainingDays, 65);
      });

      test('按保质期排序时无保质期信息的项应该排在后面', () {
        // Arrange
        final now = DateTime.now();
        final data = [
          AggregatedInventoryItem(
            productId: 100,
            productName: '可乐',
            totalQuantity: 80,
            unit: '瓶',
            categoryName: '饮料',
            details: [
              InventoryDetail(
                stockId: 1,
                shopId: 1,
                shopName: '总仓',
                quantity: 80,
                productionDate: now.subtract(const Duration(days: 300)),
                shelfLifeDays: 365,
                remainingDays: 65,
              ),
            ],
          ),
          const AggregatedInventoryItem(
            productId: 200,
            productName: '雪碧',
            totalQuantity: 30,
            unit: '瓶',
            categoryName: '饮料',
            details: [
              InventoryDetail(
                stockId: 2,
                shopId: 1,
                shopName: '总仓',
                quantity: 30,
              ),
            ],
          ),
        ];

        // Act - 模拟按保质期排序逻辑
        data.sort((a, b) {
          final aMinDays = a.minRemainingDays;
          final bMinDays = b.minRemainingDays;
          
          if (aMinDays == null && bMinDays == null) return 0;
          if (aMinDays == null) return 1;
          if (bMinDays == null) return -1;
          
          return aMinDays.compareTo(bMinDays);
        });

        // Assert
        expect(data[0].minRemainingDays, 65);
        expect(data[1].minRemainingDays, isNull);
      });
    });

    group('原始数据排序', () {
      test('按数量排序应该正确排序', () {
        // Arrange
        final data = [
          {'id': 1, 'productName': '可乐', 'quantity': 80},
          {'id': 2, 'productName': '雪碧', 'quantity': 30},
          {'id': 3, 'productName': '芬达', 'quantity': 50},
        ];

        // Act - 模拟排序逻辑
        data.sort((a, b) => (a['quantity'] as num).compareTo(b['quantity'] as num));

        // Assert
        expect(data[0]['quantity'], 30);
        expect(data[1]['quantity'], 50);
        expect(data[2]['quantity'], 80);
      });

      test('按保质期排序应该正确排序', () {
        // Arrange
        final now = DateTime.now();
        final data = [
          {
            'id': 1,
            'productName': '可乐',
            'quantity': 80,
            'productionDate': now.subtract(const Duration(days: 300)).toIso8601String(),
            'shelfLifeDays': 365,
            'shelfLifeUnit': 'days',
          },
          {
            'id': 2,
            'productName': '雪碧',
            'quantity': 30,
            'productionDate': now.subtract(const Duration(days: 350)).toIso8601String(),
            'shelfLifeDays': 365,
            'shelfLifeUnit': 'days',
          },
          {
            'id': 3,
            'productName': '芬达',
            'quantity': 50,
            'productionDate': now.subtract(const Duration(days: 330)).toIso8601String(),
            'shelfLifeDays': 365,
            'shelfLifeUnit': 'days',
          },
        ];

        // Act - 模拟按保质期排序逻辑（简化版）
        final filteredData = data.where((item) {
          final productionDateStr = item['productionDate'];
          final shelfLifeDays = item['shelfLifeDays'];
          final shelfLifeUnit = item['shelfLifeUnit'];
          return productionDateStr is String &&
              productionDateStr.isNotEmpty &&
              shelfLifeDays is int &&
              shelfLifeUnit is String;
        }).toList();

        filteredData.sort((a, b) {
          final aProductionDate = DateTime.parse(a['productionDate'] as String);
          final aShelfLife = a['shelfLifeDays'] as int;
          final aExpiryDate = aProductionDate.add(Duration(days: aShelfLife));
          final aRemaining = aExpiryDate.difference(now);

          final bProductionDate = DateTime.parse(b['productionDate'] as String);
          final bShelfLife = b['shelfLifeDays'] as int;
          final bExpiryDate = bProductionDate.add(Duration(days: bShelfLife));
          final bRemaining = bExpiryDate.difference(now);

          return aRemaining.compareTo(bRemaining);
        });

        // Assert - 雪碧剩余最少，芬达次之，可乐最多
        expect(filteredData[0]['productName'], '雪碧');
        expect(filteredData[1]['productName'], '芬达');
        expect(filteredData[2]['productName'], '可乐');
      });

      test('按保质期排序时无保质期信息的项应该被过滤', () {
        // Arrange
        final now = DateTime.now();
        final data = [
          {
            'id': 1,
            'productName': '可乐',
            'quantity': 80,
            'productionDate': now.subtract(const Duration(days: 300)).toIso8601String(),
            'shelfLifeDays': 365,
            'shelfLifeUnit': 'days',
          },
          {
            'id': 2,
            'productName': '雪碧',
            'quantity': 30,
          },
        ];

        // Act - 模拟按保质期排序逻辑
        final filteredData = data.where((item) {
          final productionDateStr = item['productionDate'];
          final shelfLifeDays = item['shelfLifeDays'];
          final shelfLifeUnit = item['shelfLifeUnit'];
          return productionDateStr is String &&
              productionDateStr.isNotEmpty &&
              shelfLifeDays is int &&
              shelfLifeUnit is String;
        }).toList();

        // Assert
        expect(filteredData.length, 1);
        expect(filteredData[0]['productName'], '可乐');
      });
    });
  });
}
