import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/inventory/domain/model/aggregated_inventory.dart';
import 'package:stocko_app/features/inventory/presentation/providers/inventory_query_providers.dart';
import 'package:stocko_app/features/inventory/presentation/screens/inventory_query_screen.dart';
import 'package:stocko_app/features/inventory/presentation/widgets/aggregated_inventory_card.dart';

void main() {
  group('InventoryQueryScreen Widget Tests', () {
    // 测试数据准备
    late List<AggregatedInventoryItem> mockAggregatedData;
    late List<Map<String, dynamic>> mockOriginalData;

    setUp(() {
      // 创建聚合模式的测试数据
      mockAggregatedData = [
        AggregatedInventoryItem(
          productId: 1,
          productName: '可口可乐',
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
        ),
        AggregatedInventoryItem(
          productId: 2,
          productName: '雪碧',
          productImage: null,
          totalQuantity: 80,
          unit: '瓶',
          categoryId: 1,
          categoryName: '饮料',
          details: [
            InventoryDetail(
              stockId: 3,
              shopId: 1,
              shopName: '总店',
              quantity: 80,
              batchId: 3,
              batchNumber: 'B20240201',
              productionDate: DateTime(2024, 2, 1),
              shelfLifeDays: 365,
              shelfLifeUnit: 'days',
              remainingDays: 230,
            ),
          ],
        ),
      ];

      // 创建原始模式的测试数据
      mockOriginalData = [
        {
          'id': 1,
          'productId': 1,
          'productName': '可口可乐',
          'productImage': null,
          'quantity': 100,
          'unit': '瓶',
          'shopId': 1,
          'shopName': '总店',
          'categoryId': 1,
          'categoryName': '饮料',
          'batchNumber': 'B20240101',
          'productionDate': '2024-01-01T00:00:00.000Z',
          'shelfLifeDays': 365,
          'shelfLifeUnit': 'days',
          'purchasePrice': 300, // 3.00元
        },
        {
          'id': 2,
          'productId': 2,
          'productName': '雪碧',
          'productImage': null,
          'quantity': 80,
          'unit': '瓶',
          'shopId': 1,
          'shopName': '总店',
          'categoryId': 1,
          'categoryName': '饮料',
          'batchNumber': 'B20240201',
          'productionDate': '2024-02-01T00:00:00.000Z',
          'shelfLifeDays': 365,
          'shelfLifeUnit': 'days',
          'purchasePrice': 250, // 2.50元
        },
      ];
    });

    testWidgets('未筛选店铺时应显示聚合卡片', (WidgetTester tester) async {
      // Arrange - 创建带有mock数据的ProviderScope
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryQueryProvider.overrideWith((ref) async {
              return mockAggregatedData;
            }),
            inventoryFilterProvider.overrideWith((ref) {
              return InventoryFilterNotifier();
            }),
          ],
          child: const MaterialApp(
            home: InventoryQueryScreen(),
          ),
        ),
      );

      // Act - 等待异步数据加载
      await tester.pumpAndSettle();

      // Assert - 验证显示聚合卡片
      expect(find.byType(AggregatedInventoryCard), findsNWidgets(2));
      expect(find.text('可口可乐'), findsOneWidget);
      expect(find.text('雪碧'), findsOneWidget);
      
      // 验证显示总库存数量
      expect(find.text('150'), findsOneWidget);
      expect(find.text('80'), findsOneWidget);
      
      // 验证汇总统计
      expect(find.text('品种'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // 2个品种
      expect(find.text('总数'), findsOneWidget);
      expect(find.text('230'), findsOneWidget); // 150 + 80
    });

    testWidgets('筛选店铺时应显示原始卡片', (WidgetTester tester) async {
      // Arrange - 创建带有筛选状态的ProviderScope
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryQueryProvider.overrideWith((ref) async {
              return mockOriginalData;
            }),
            inventoryFilterProvider.overrideWith((ref) {
              final notifier = InventoryFilterNotifier();
              notifier.updateShop('总店');
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: InventoryQueryScreen(),
          ),
        ),
      );

      // Act - 等待异步数据加载
      await tester.pumpAndSettle();

      // Assert - 验证不显示聚合卡片
      expect(find.byType(AggregatedInventoryCard), findsNothing);
      
      // 验证显示原始卡片（通过查找Card组件）
      expect(find.byType(Card), findsWidgets);
      expect(find.text('可口可乐'), findsOneWidget);
      expect(find.text('雪碧'), findsOneWidget);
      
      // 验证显示店铺信息
      expect(find.text('饮料 · 总店'), findsNWidgets(2));
      
      // 验证汇总统计
      expect(find.text('品种'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // 2条记录
      expect(find.text('总数'), findsOneWidget);
      expect(find.text('180'), findsOneWidget); // 100 + 80
    });

    testWidgets('切换筛选条件时应正确更新显示模式', (WidgetTester tester) async {
      // Arrange - 创建可变的ProviderContainer
      final container = ProviderContainer(
        overrides: [
          inventoryQueryProvider.overrideWith((ref) async {
            final filterState = ref.watch(inventoryFilterProvider);
            if (filterState.selectedShop == '所有仓库') {
              return mockAggregatedData;
            } else {
              return mockOriginalData;
            }
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: InventoryQueryScreen(),
          ),
        ),
      );

      // Act - 等待初始加载（聚合模式）
      await tester.pumpAndSettle();

      // Assert - 验证初始状态为聚合模式
      expect(find.byType(AggregatedInventoryCard), findsNWidgets(2));

      // Act - 切换到筛选店铺模式
      container.read(inventoryFilterProvider.notifier).updateShop('总店');
      await tester.pumpAndSettle();

      // Assert - 验证切换到原始模式
      expect(find.byType(AggregatedInventoryCard), findsNothing);
      expect(find.text('饮料 · 总店'), findsWidgets);

      // Act - 清除店铺筛选
      container.read(inventoryFilterProvider.notifier).updateShop('所有仓库');
      await tester.pumpAndSettle();

      // Assert - 验证切换回聚合模式
      expect(find.byType(AggregatedInventoryCard), findsNWidgets(2));
    });

    testWidgets('聚合模式下汇总统计应正确计算', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryQueryProvider.overrideWith((ref) async {
              return mockAggregatedData;
            }),
            inventoryFilterProvider.overrideWith((ref) {
              return InventoryFilterNotifier();
            }),
          ],
          child: const MaterialApp(
            home: InventoryQueryScreen(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert - 验证品种数量
      expect(find.text('品种'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Assert - 验证总数量（150 + 80 = 230）
      expect(find.text('总数'), findsOneWidget);
      expect(find.text('230'), findsOneWidget);

      // Assert - 验证总价值（聚合模式下为0）
      expect(find.text('总价值'), findsOneWidget);
      expect(find.text('¥0.00'), findsOneWidget);
    });

    testWidgets('原始模式下汇总统计应正确计算', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryQueryProvider.overrideWith((ref) async {
              return mockOriginalData;
            }),
            inventoryFilterProvider.overrideWith((ref) {
              final notifier = InventoryFilterNotifier();
              notifier.updateShop('总店');
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: InventoryQueryScreen(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert - 验证品种数量（原始模式下是记录数）
      expect(find.text('品种'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Assert - 验证总数量（100 + 80 = 180）
      expect(find.text('总数'), findsOneWidget);
      expect(find.text('180'), findsOneWidget);

      // Assert - 验证总价值（100*3.00 + 80*2.50 = 300 + 200 = 500）
      expect(find.text('总价值'), findsOneWidget);
      expect(find.text('¥500.00'), findsOneWidget);
    });

    testWidgets('空数据时应显示空状态提示', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryQueryProvider.overrideWith((ref) async {
              return <AggregatedInventoryItem>[];
            }),
            inventoryFilterProvider.overrideWith((ref) {
              return InventoryFilterNotifier();
            }),
          ],
          child: const MaterialApp(
            home: InventoryQueryScreen(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('暂无库存数据'), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });

    testWidgets('加载中应显示进度指示器', (WidgetTester tester) async {
      // Arrange - 使用Completer来控制异步完成时机
      bool shouldComplete = false;
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryQueryProvider.overrideWith((ref) async {
              // 等待直到测试允许完成
              while (!shouldComplete) {
                await Future.delayed(const Duration(milliseconds: 10));
              }
              return mockAggregatedData;
            }),
            inventoryFilterProvider.overrideWith((ref) {
              return InventoryFilterNotifier();
            }),
          ],
          child: const MaterialApp(
            home: InventoryQueryScreen(),
          ),
        ),
      );

      // Act - 只pump一次，不等待完成
      await tester.pump();

      // Assert - 验证显示加载指示器
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Cleanup - 允许Future完成以避免pending timer警告
      shouldComplete = true;
      await tester.pumpAndSettle();
    });

    testWidgets('错误时应显示错误信息和重试按钮', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryQueryProvider.overrideWith((ref) async {
              throw Exception('数据库连接失败');
            }),
            inventoryFilterProvider.overrideWith((ref) {
              return InventoryFilterNotifier();
            }),
          ],
          child: const MaterialApp(
            home: InventoryQueryScreen(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('加载库存数据失败'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
      expect(find.text('Exception: 数据库连接失败'), findsOneWidget);
    });

    testWidgets('应显示排序菜单按钮', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryQueryProvider.overrideWith((ref) async {
              return mockAggregatedData;
            }),
            inventoryFilterProvider.overrideWith((ref) {
              return InventoryFilterNotifier();
            }),
          ],
          child: const MaterialApp(
            home: InventoryQueryScreen(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert - 验证排序按钮存在
      expect(find.byIcon(Icons.sort), findsOneWidget);
      expect(find.byType(PopupMenuButton<InventorySortType>), findsOneWidget);
    });

    testWidgets('点击排序按钮应显示排序选项', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryQueryProvider.overrideWith((ref) async {
              return mockAggregatedData;
            }),
            inventoryFilterProvider.overrideWith((ref) {
              return InventoryFilterNotifier();
            }),
          ],
          child: const MaterialApp(
            home: InventoryQueryScreen(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();

      // Assert - 验证排序选项显示
      expect(find.text('按库存数量排序'), findsOneWidget);
      expect(find.text('按剩余保质期排序'), findsOneWidget);
      expect(find.text('默认排序'), findsOneWidget);
    });

    testWidgets('应显示返回按钮', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryQueryProvider.overrideWith((ref) async {
              return mockAggregatedData;
            }),
            inventoryFilterProvider.overrideWith((ref) {
              return InventoryFilterNotifier();
            }),
          ],
          child: const MaterialApp(
            home: InventoryQueryScreen(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.arrow_back), findsOneWidget);
    });

    testWidgets('应显示标题"库存查询"', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryQueryProvider.overrideWith((ref) async {
              return mockAggregatedData;
            }),
            inventoryFilterProvider.overrideWith((ref) {
              return InventoryFilterNotifier();
            }),
          ],
          child: const MaterialApp(
            home: InventoryQueryScreen(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('库存查询'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
