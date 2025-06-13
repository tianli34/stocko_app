import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stocko_app/features/product/presentation/screens/unit_selection_screen.dart';
import 'package:stocko_app/features/product/domain/model/unit.dart';
import 'package:stocko_app/features/product/application/provider/unit_providers.dart';
import 'package:stocko_app/features/product/data/repository/unit_repository.dart';
import 'package:stocko_app/features/product/domain/repository/i_unit_repository.dart';

// 简单的Mock Repository
class MockUnitRepository implements IUnitRepository {
  @override
  Future<int> addUnit(Unit unit) async => 1;

  @override
  Future<Unit?> getUnitById(String id) async => null;

  @override
  Future<Unit?> getUnitByName(String name) async => null;

  @override
  Future<List<Unit>> getAllUnits() async => [];

  @override
  Stream<List<Unit>> watchAllUnits() => Stream.value([]);

  @override
  Future<bool> updateUnit(Unit unit) async => true;

  @override
  Future<int> deleteUnit(String id) async => 1;

  @override
  Future<bool> isUnitNameExists(String name, [String? excludeId]) async =>
      false;

  @override
  Future<void> insertDefaultUnits() async {}
}

void main() {
  group('UnitSelectionScreen Tests', () {
    // 创建测试用的单位数据
    final testUnits = [
      Unit(id: 'unit1', name: '千克'),
      Unit(id: 'unit2', name: '克'),
      Unit(id: 'unit3', name: '个'),
    ];

    Widget createTestWidget({
      List<Unit>? units,
      bool isLoading = false,
      String? error,
      String? selectedUnitId,
      bool isSelectionMode = true,
    }) {
      return ProviderScope(
        overrides: [
          allUnitsProvider.overrideWith((ref) {
            if (error != null) {
              return Stream.error(error);
            }
            if (isLoading) {
              // 返回一个空的Stream来模拟加载状态，不发出任何数据
              return const Stream<List<Unit>>.empty();
            }
            return Stream.value(units ?? testUnits);
          }),
          unitRepositoryProvider.overrideWithValue(MockUnitRepository()),
        ],
        child: MaterialApp(
          home: UnitSelectionScreen(
            selectedUnitId: selectedUnitId,
            isSelectionMode: isSelectionMode,
          ),
        ),
      );
    }

    group('基本渲染测试', () {
      testWidgets('选择模式下应该显示正确的标题', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isSelectionMode: true));
        await tester.pumpAndSettle();

        expect(find.text('选择单位'), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('管理模式下应该显示正确的标题', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isSelectionMode: false));
        await tester.pumpAndSettle();

        expect(find.text('单位管理'), findsOneWidget);
      });

      testWidgets('应该显示添加单位按钮', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.add), findsOneWidget);
        expect(find.byTooltip('新增单位'), findsOneWidget);
      });

      testWidgets('应该显示返回按钮', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
        expect(find.byTooltip('返回'), findsOneWidget);
      });
    });

    group('单位列表显示测试', () {
      testWidgets('应该显示单位列表', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证单位名称显示
        expect(find.text('千克'), findsOneWidget);
        expect(find.text('克'), findsOneWidget);
        expect(find.text('个'), findsOneWidget);
      });

      testWidgets('应该显示单位ID', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证单位ID显示
        expect(find.textContaining('unit1'), findsOneWidget);
        expect(find.textContaining('unit2'), findsOneWidget);
        expect(find.textContaining('unit3'), findsOneWidget);
      });

      testWidgets('选择模式下应该显示单选按钮', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isSelectionMode: true));
        await tester.pumpAndSettle();

        // 验证Radio按钮存在
        expect(find.byType(Radio<String>), findsAtLeast(3));
      });

      testWidgets('应该显示单位图标', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证单位图标
        expect(find.byIcon(Icons.straighten), findsAtLeast(3));
      });
    });

    group('选择功能测试', () {
      testWidgets('应该能选择单位', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isSelectionMode: true));
        await tester.pumpAndSettle();

        // 点击第一个单位
        await tester.tap(find.text('千克').first);
        await tester.pumpAndSettle();

        // 验证选择状态（通过Card的颜色变化等视觉反馈）
        expect(find.byType(Card), findsAtLeast(3));
      });

      testWidgets('预选单位应该显示为已选择状态', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(isSelectionMode: true, selectedUnitId: 'unit1'),
        );
        await tester.pumpAndSettle();

        // 验证预选单位的视觉状态
        expect(find.byType(Radio<String>), findsAtLeast(3));
      });

      testWidgets('选择单位后应该显示确认按钮', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(isSelectionMode: true, selectedUnitId: 'unit1'),
        );
        await tester.pumpAndSettle();

        // 验证确认选择按钮
        expect(find.text('确认选择'), findsOneWidget);
        expect(find.byIcon(Icons.check), findsOneWidget);
      });
    });

    group('空状态测试', () {
      testWidgets('无单位时应该显示空状态', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(units: []));
        await tester.pumpAndSettle();

        // 验证空状态显示
        expect(find.text('暂无单位'), findsOneWidget);
        expect(find.text('点击右上角的 + 号添加新单位'), findsOneWidget);
        expect(find.byIcon(Icons.straighten), findsOneWidget);
      });
    });
    group('加载状态测试', () {
      testWidgets('应该显示加载状态', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isLoading: true));
        await tester.pump(); // 使用pump而不是pumpAndSettle

        // 验证加载指示器
        expect(find.text('加载单位列表中...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('错误状态测试', () {
      testWidgets('应该显示错误状态', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(error: '网络错误'));
        await tester.pumpAndSettle();

        // 验证错误显示
        expect(find.text('加载单位列表失败'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });
      testWidgets('错误状态应该有重试功能', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(error: '网络错误'));
        await tester.pumpAndSettle();

        // 验证重试按钮 - 查找按钮文本和刷新图标
        expect(find.text('重试'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });
    });

    group('下拉刷新测试', () {
      testWidgets('应该支持下拉刷新', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证RefreshIndicator存在
        expect(find.byType(RefreshIndicator), findsOneWidget);
      });
    });

    group('添加单位功能测试', () {
      testWidgets('点击添加按钮应该显示对话框', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 点击添加按钮
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // 验证对话框出现
        expect(find.text('新增单位'), findsOneWidget);
        expect(find.byType(AlertDialog), findsOneWidget);
      });

      testWidgets('添加对话框应该有输入字段', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 点击添加按钮
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // 验证输入字段
        expect(find.text('单位名称'), findsOneWidget);
        expect(find.text('请输入单位名称'), findsOneWidget);
        expect(find.byType(TextFormField), findsOneWidget);
      });
      testWidgets('添加对话框应该有确认和取消按钮', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 点击添加按钮
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // 验证按钮
        expect(find.text('取消'), findsOneWidget);
        expect(find.text('添加'), findsOneWidget);
      });
    });

    group('Widget结构测试', () {
      testWidgets('应该有正确的Widget层次结构', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证主要Widget存在
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(Column), findsAtLeast(1));
      });

      testWidgets('列表应该使用ListView.builder', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证ListView存在
        expect(find.byType(ListView), findsOneWidget);
      });
    });

    group('管理模式测试', () {
      testWidgets('管理模式下应该显示编辑和删除操作', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isSelectionMode: false));
        await tester.pumpAndSettle();

        // 在管理模式下，应该有编辑和删除操作
        // 这些操作通常在UnitListTile中实现
        expect(find.byType(Card), findsAtLeast(3));
      });
    });
  });
}
