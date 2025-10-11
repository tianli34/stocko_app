import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/inventory/domain/model/aggregated_inventory.dart';
import 'package:stocko_app/features/inventory/presentation/widgets/aggregated_inventory_card.dart';

void main() {
  group('AggregatedInventoryCard', () {
    late AggregatedInventoryItem testItem;

    setUp(() {
      // 创建测试数据
      testItem = AggregatedInventoryItem(
        productId: 1,
        productName: '测试商品',
        productImage: null,
        totalQuantity: 150,
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
          InventoryDetail(
            stockId: 2,
            shopId: 2,
            shopName: '分店A',
            quantity: 50,
            batchId: 2,
            batchNumber: 'B20240115',
            productionDate: DateTime(2024, 1, 15),
            shelfLifeDays: 365,
            shelfLifeUnit: 'days',
            remainingDays: 214,
          ),
        ],
      );
    });

    testWidgets('应该显示货品基本信息和总库存', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AggregatedInventoryCard(item: testItem),
          ),
        ),
      );

      // Assert
      expect(find.text('测试商品'), findsOneWidget);
      expect(find.text('饮料'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);
      expect(find.text('瓶'), findsOneWidget);
      expect(find.text('2条记录'), findsOneWidget);
    });

    testWidgets('收起状态不应显示详细信息', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AggregatedInventoryCard(item: testItem),
          ),
        ),
      );

      // Assert - 详细信息不应该可见
      expect(find.text('总店'), findsNothing);
      expect(find.text('分店A'), findsNothing);
      expect(find.text('B20240101'), findsNothing);
    });

    testWidgets('点击后应该展开显示详细信息', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AggregatedInventoryCard(item: testItem),
          ),
        ),
      );

      // Act - 点击卡片展开
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle(); // 等待动画完成

      // Assert - 详细信息应该可见
      expect(find.text('总店'), findsOneWidget);
      expect(find.text('分店A'), findsOneWidget);
      expect(find.text('2024-01-01'), findsOneWidget);
      expect(find.text('2024-01-15'), findsOneWidget);
    });

    testWidgets('再次点击应该收起详细信息', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AggregatedInventoryCard(item: testItem),
          ),
        ),
      );

      // Act - 展开
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Act - 收起
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Assert - 详细信息应该不可见
      expect(find.text('总店'), findsNothing);
      expect(find.text('分店A'), findsNothing);
    });

    testWidgets('应该显示所有详细记录', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AggregatedInventoryCard(item: testItem),
          ),
        ),
      );

      // Act - 展开
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Assert - 验证所有详细记录都显示
      expect(find.text('总店'), findsOneWidget);
      expect(find.text('分店A'), findsOneWidget);
      expect(find.text('100瓶'), findsOneWidget);
      expect(find.text('50瓶'), findsOneWidget);
    });

    testWidgets('应该正确显示保质期颜色 - 已过期', (WidgetTester tester) async {
      // Arrange - 创建已过期的商品
      final expiredItem = AggregatedInventoryItem(
        productId: 1,
        productName: '过期商品',
        productImage: null,
        totalQuantity: 80,
        unit: '瓶',
        categoryId: 1,
        categoryName: '饮料',
        details: [
          InventoryDetail(
            stockId: 1,
            shopId: 1,
            shopName: '总店',
            quantity: 50,
            batchId: 1,
            batchNumber: 'B20230101',
            productionDate: DateTime(2023, 1, 1),
            shelfLifeDays: 365,
            shelfLifeUnit: 'days',
            remainingDays: -10, // 已过期
          ),
          InventoryDetail(
            stockId: 2,
            shopId: 2,
            shopName: '分店A',
            quantity: 30,
            batchId: 2,
            batchNumber: 'B20240101',
            productionDate: DateTime(2024, 1, 1),
            shelfLifeDays: 365,
            shelfLifeUnit: 'days',
            remainingDays: 200, // 正常
          ),
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AggregatedInventoryCard(item: expiredItem),
          ),
        ),
      );

      // Assert - 应该显示过期警告
      expect(find.text('含已过期批次'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('应该正确显示保质期颜色 - 即将过期', (WidgetTester tester) async {
      // Arrange - 创建即将过期的商品
      final expiringSoonItem = AggregatedInventoryItem(
        productId: 1,
        productName: '即将过期商品',
        productImage: null,
        totalQuantity: 80,
        unit: '瓶',
        categoryId: 1,
        categoryName: '饮料',
        details: [
          InventoryDetail(
            stockId: 1,
            shopId: 1,
            shopName: '总店',
            quantity: 50,
            batchId: 1,
            batchNumber: 'B20240101',
            productionDate: DateTime.now().subtract(const Duration(days: 340)),
            shelfLifeDays: 365,
            shelfLifeUnit: 'days',
            remainingDays: 25, // 即将过期
          ),
          InventoryDetail(
            stockId: 2,
            shopId: 2,
            shopName: '分店B',
            quantity: 30,
            batchId: 2,
            batchNumber: 'B20240201',
            productionDate: DateTime.now().subtract(const Duration(days: 100)),
            shelfLifeDays: 365,
            shelfLifeUnit: 'days',
            remainingDays: 265, // 正常
          ),
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AggregatedInventoryCard(item: expiringSoonItem),
          ),
        ),
      );

      // Assert - 应该显示即将过期警告
      expect(find.text('含即将过期批次'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('应该正确显示批次信息', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AggregatedInventoryCard(item: testItem),
          ),
        ),
      );

      // Act - 展开
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Assert - 验证生产日期显示
      expect(find.text('2024-01-01'), findsOneWidget);
      expect(find.text('2024-01-15'), findsOneWidget);
    });

    testWidgets('应该显示表头', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AggregatedInventoryCard(item: testItem),
          ),
        ),
      );

      // Act - 展开
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Assert - 验证表头显示
      expect(find.text('店铺'), findsOneWidget);
      expect(find.text('生产日期'), findsOneWidget);
      expect(find.text('剩余保质期'), findsOneWidget);
      expect(find.text('数量'), findsOneWidget);
    });

    testWidgets('无批次信息时应显示占位符', (WidgetTester tester) async {
      // Arrange - 创建无批次信息的商品（需要多条记录才能展开）
      final noBatchItem = AggregatedInventoryItem(
        productId: 1,
        productName: '无批次商品',
        productImage: null,
        totalQuantity: 80,
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
          const InventoryDetail(
            stockId: 2,
            shopId: 2,
            shopName: '分店B',
            quantity: 30,
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
            body: AggregatedInventoryCard(item: noBatchItem),
          ),
        ),
      );

      // 展开卡片
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Assert - 应该显示占位符
      expect(find.text('-'), findsNWidgets(4)); // 两条记录，每条的批次和保质期都显示 "-"
    });
  });
}
