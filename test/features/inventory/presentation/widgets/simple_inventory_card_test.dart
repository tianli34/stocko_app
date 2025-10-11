import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/inventory/domain/model/aggregated_inventory.dart';
import 'package:stocko_app/features/inventory/presentation/widgets/simple_inventory_card.dart';

void main() {
  group('SimpleInventoryCard', () {
    late AggregatedInventoryItem testItem;

    setUp(() {
      // 创建单条记录的测试数据
      testItem = AggregatedInventoryItem(
        productId: 1,
        productName: '单条记录商品',
        productImage: null,
        totalQuantity: 100,
        unit: '瓶',
        categoryId: 1,
        categoryName: '饮料',
        details: [
          InventoryDetail(
            stockId: 1,
            shopId: 1,
            shopName: '总店',
            quantity: 100,
            batchId: 1,
            batchNumber: 'B20240101',
            productionDate: DateTime(2024, 1, 1),
            shelfLifeDays: 365,
            shelfLifeUnit: 'days',
            remainingDays: 200,
          ),
        ],
      );
    });

    testWidgets('应该显示货品基本信息', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleInventoryCard(item: testItem),
          ),
        ),
      );

      // Assert
      expect(find.text('单条记录商品'), findsOneWidget);
      expect(find.text('饮料 · 总店'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('瓶'), findsOneWidget);
    });

    testWidgets('应该显示保质期信息', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleInventoryCard(item: testItem),
          ),
        ),
      );

      // Assert
      expect(find.text('剩余200天'), findsOneWidget);
    });

    testWidgets('不应该显示展开图标', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleInventoryCard(item: testItem),
          ),
        ),
      );

      // Assert - 不应该有展开图标
      expect(find.byIcon(Icons.expand_more), findsNothing);
      expect(find.text('1条记录'), findsNothing);
    });

    testWidgets('不应该可以展开', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleInventoryCard(item: testItem),
          ),
        ),
      );

      // Assert - 不应该有InkWell可以点击
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('应该显示库存状态指示器 - 低库存', (WidgetTester tester) async {
      // Arrange - 创建低库存商品
      final lowStockItem = AggregatedInventoryItem(
        productId: 1,
        productName: '低库存商品',
        productImage: null,
        totalQuantity: 5,
        unit: '个',
        categoryId: 1,
        categoryName: '其他',
        details: [
          const InventoryDetail(
            stockId: 1,
            shopId: 1,
            shopName: '总店',
            quantity: 5,
            batchId: null,
            batchNumber: null,
            productionDate: null,
            shelfLifeDays: null,
            shelfLifeUnit: null,
            remainingDays: null,
          ),
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleInventoryCard(item: lowStockItem),
          ),
        ),
      );

      // Assert - 应该显示橙色状态指示器
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(SimpleInventoryCard),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).color == Colors.orange,
          ),
        ),
      );
      expect(container, isNotNull);
    });

    testWidgets('无保质期信息时不应显示保质期', (WidgetTester tester) async {
      // Arrange - 创建无保质期信息的商品
      final noShelfLifeItem = AggregatedInventoryItem(
        productId: 1,
        productName: '无保质期商品',
        productImage: null,
        totalQuantity: 50,
        unit: '个',
        categoryId: 1,
        categoryName: '其他',
        details: [
          const InventoryDetail(
            stockId: 1,
            shopId: 1,
            shopName: '总店',
            quantity: 50,
            batchId: null,
            batchNumber: null,
            productionDate: null,
            shelfLifeDays: null,
            shelfLifeUnit: null,
            remainingDays: null,
          ),
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleInventoryCard(item: noShelfLifeItem),
          ),
        ),
      );

      // Assert - 不应该显示保质期信息
      expect(find.textContaining('剩余'), findsNothing);
    });

    testWidgets('应该正确显示过期商品', (WidgetTester tester) async {
      // Arrange - 创建已过期商品
      final expiredItem = AggregatedInventoryItem(
        productId: 1,
        productName: '过期商品',
        productImage: null,
        totalQuantity: 30,
        unit: '瓶',
        categoryId: 1,
        categoryName: '饮料',
        details: [
          InventoryDetail(
            stockId: 1,
            shopId: 1,
            shopName: '总店',
            quantity: 30,
            batchId: 1,
            batchNumber: 'B20230101',
            productionDate: DateTime(2023, 1, 1),
            shelfLifeDays: 365,
            shelfLifeUnit: 'days',
            remainingDays: -10,
          ),
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleInventoryCard(item: expiredItem),
          ),
        ),
      );

      // Assert - 应该显示"已过期"
      expect(find.text('已过期'), findsOneWidget);
    });
  });
}
