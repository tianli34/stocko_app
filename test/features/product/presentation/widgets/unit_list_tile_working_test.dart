import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stocko_app/features/product/domain/model/unit.dart';
import 'package:stocko_app/features/product/application/provider/unit_providers.dart';
import 'package:stocko_app/features/product/presentation/widgets/unit_list_tile.dart';
import 'package:stocko_app/features/product/domain/repository/i_unit_repository.dart';
import 'package:stocko_app/features/product/data/repository/unit_repository.dart';
import 'package:stocko_app/core/database/database.dart';

/// Mock classes
class MockUnitRepository extends Mock implements IUnitRepository {}

class MockAppDatabase extends Mock implements AppDatabase {}

/// Mock Ref for testing
class MockRef extends Mock implements Ref {
  @override
  void invalidate(ProviderOrFamily provider) {
    // 测试中不需要实际刷新
  }
}

/// 测试用的 UnitController
class TestUnitController extends UnitController {
  TestUnitController() : super(MockUnitRepository(), MockRef());

  void setLoadingState() {
    state = const UnitControllerState(status: UnitOperationStatus.loading);
  }

  void setInitialState() {
    state = const UnitControllerState(status: UnitOperationStatus.initial);
  }
}

void main() {
  group('UnitListTile Widget Tests', () {
    late Unit testUnit;

    setUp(() {
      testUnit = Unit(id: 'unit_test_123', name: '测试单位');
    });
    Widget createTestWidget({
      Unit? unit,
      VoidCallback? onTap,
      VoidCallback? onEdit,
      VoidCallback? onDelete,
      bool showActions = true,
      bool isSelected = false,
      TestUnitController? controller,
    }) {
      final mockDatabase = MockAppDatabase();
      final mockRepository = MockUnitRepository();

      return ProviderScope(
        overrides: [
          // Override the database provider
          appDatabaseProvider.overrideWithValue(mockDatabase),
          // Override the repository provider
          unitRepositoryProvider.overrideWithValue(mockRepository),
          // Override the controller provider
          unitControllerProvider.overrideWith((ref) {
            return controller ?? TestUnitController();
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: UnitListTile(
              unit: unit ?? testUnit,
              onTap: onTap,
              onEdit: onEdit,
              onDelete: onDelete,
              showActions: showActions,
              isSelected: isSelected,
            ),
          ),
        ),
      );
    }

    group('基本渲染测试', () {
      testWidgets('应该正确显示单位基本信息', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 验证单位名称
        expect(find.text('测试单位'), findsOneWidget);

        // 验证单位ID
        expect(find.textContaining('ID: unit_test_123'), findsOneWidget);

        // 验证单位图标
        expect(find.byIcon(Icons.straighten), findsOneWidget);
      });

      testWidgets('当单位被选中时应该有不同的样式', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isSelected: true));

        // 验证选中状态下的图标
        expect(find.byIcon(Icons.check_circle), findsOneWidget);

        // 验证卡片样式有变化（elevation会不同）
        final card = tester.widget<Card>(find.byType(Card));
        expect(card.elevation, equals(4));
      });

      testWidgets('当单位未被选中时应该有默认样式', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isSelected: false));

        // 验证未选中状态下没有选中图标
        expect(find.byIcon(Icons.check_circle), findsNothing);

        // 验证默认卡片样式
        final card = tester.widget<Card>(find.byType(Card));
        expect(card.elevation, equals(2));
      });
    });

    group('操作按钮测试', () {
      testWidgets('当showActions为true时应该显示操作按钮', (WidgetTester tester) async {
        bool editCalled = false;

        await tester.pumpWidget(
          createTestWidget(
            onEdit: () => editCalled = true,
            onDelete: () {}, // 提供删除回调，但我们只测试编辑
          ),
        );

        // 验证编辑按钮存在
        final editButton = find.text('编辑');
        expect(editButton, findsOneWidget);

        // 验证删除按钮存在
        final deleteButton = find.text('删除');
        expect(deleteButton, findsOneWidget);

        // 测试编辑按钮点击
        await tester.tap(editButton);
        await tester.pump();
        expect(editCalled, isTrue);
      });

      testWidgets('当showActions为false时不应该显示操作按钮', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showActions: false));

        // 验证操作按钮不存在
        expect(find.text('编辑'), findsNothing);
        expect(find.text('删除'), findsNothing);
      });
      testWidgets('当控制器加载中时按钮应该被禁用', (WidgetTester tester) async {
        // 创建一个处于加载状态的控制器
        final loadingController = TestUnitController();
        loadingController.setLoadingState();

        await tester.pumpWidget(
          createTestWidget(
            onEdit: () {},
            onDelete: () {},
            controller: loadingController,
          ),
        ); // 等待widget完全构建
        await tester.pumpAndSettle();

        // 查找按钮 - TextButton.icon可能渲染为ButtonStyleButton
        final textButtons = find.byType(TextButton);
        final buttonStyleButtons = find.byWidgetPredicate(
          (widget) => widget is ButtonStyleButton,
        );

        // 验证按钮文本存在
        expect(find.text('编辑'), findsOneWidget);
        expect(find.text('删除'), findsOneWidget);

        // 根据实际找到的按钮类型进行验证
        final buttonsToTest = textButtons.evaluate().isNotEmpty
            ? textButtons
            : buttonStyleButtons;
        expect(buttonsToTest, findsNWidgets(2)); // 编辑和删除按钮

        // 验证按钮的onPressed为null（禁用状态）
        for (final element in buttonsToTest.evaluate()) {
          final button = element.widget;
          if (button is TextButton) {
            expect(button.onPressed, isNull);
          } else if (button is ButtonStyleButton) {
            expect(button.onPressed, isNull);
          }
        }
      });
    });

    group('点击事件测试', () {
      testWidgets('点击卡片应该触发onTap回调', (WidgetTester tester) async {
        bool tapCalled = false;

        await tester.pumpWidget(
          createTestWidget(onTap: () => tapCalled = true),
        );

        // 点击卡片（通过Card而不是InkWell）
        await tester.tap(find.byType(Card));
        await tester.pump();

        expect(tapCalled, isTrue);
      });

      testWidgets('当没有onTap回调时点击卡片不应该报错', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 点击卡片不应该报错
        final cardFinder = find.byType(Card);
        expect(cardFinder, findsOneWidget);

        await tester.tap(cardFinder);
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    });

    group('边界情况测试', () {
      testWidgets('应该处理空单位名称', (WidgetTester tester) async {
        final emptyNameUnit = Unit(id: 'test_id', name: '');

        await tester.pumpWidget(createTestWidget(unit: emptyNameUnit));

        // 验证组件仍然可以正常渲染
        expect(find.byType(UnitListTile), findsOneWidget);
        expect(find.text(''), findsOneWidget);
      });

      testWidgets('应该处理很长的单位名称', (WidgetTester tester) async {
        final longNameUnit = Unit(
          id: 'test_id',
          name: '这是一个非常非常非常长的单位名称，用来测试文本溢出处理',
        );

        await tester.pumpWidget(createTestWidget(unit: longNameUnit));

        // 验证长文本被正确处理（通过Expanded包装）
        expect(find.byType(UnitListTile), findsOneWidget);
        expect(find.textContaining('这是一个非常'), findsOneWidget);
      });
    });
  });
}
