import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stocko_app/features/product/domain/model/category.dart';
import 'package:stocko_app/features/product/application/provider/category_providers.dart';
import 'package:stocko_app/features/product/presentation/screens/category_selection_screen.dart';

// Mock类定义
class MockCategoryNotifier extends Mock implements CategoryNotifier {}

// 为了让Mocktail能够识别Category类型
class FakeCategory extends Fake implements Category {}

void main() {
  group('CategorySelectionScreen Tests', () {
    late List<Category> testCategories;

    setUpAll(() {
      // 注册Fake类型
      registerFallbackValue(FakeCategory());
    });

    setUp(() {
      // 准备测试数据
      testCategories = [
        const Category(id: '1', name: '食品饮料'),
        const Category(id: '2', name: '日用百货'),
        const Category(id: '3', name: '服装鞋帽'),
      ];
    });

    // 辅助函数：创建测试Widget
    Widget createTestWidget({
      String? selectedCategoryId,
      bool isSelectionMode = true,
      List<Category>? categories,
    }) {
      return ProviderScope(
        overrides: [
          categoriesProvider.overrideWith(
            (ref) => CategoryNotifier()..state = categories ?? testCategories,
          ),
        ],
        child: MaterialApp(
          home: CategorySelectionScreen(
            selectedCategoryId: selectedCategoryId,
            isSelectionMode: isSelectionMode,
          ),
        ),
      );
    }

    group('Widget 初始化测试', () {
      testWidgets('应该正确渲染基本界面元素', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 验证AppBar
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('选择类别'), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);

        // 验证类别列表
        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(Card), findsNWidgets(testCategories.length));

        // 验证类别名称
        for (final category in testCategories) {
          expect(find.text(category.name), findsOneWidget);
        }
      });

      testWidgets('在管理模式下应该显示正确的标题', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isSelectionMode: false));

        expect(find.text('类别管理'), findsOneWidget);
      });

      testWidgets('当类别列表为空时应该显示空状态', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(categories: []));

        expect(find.byIcon(Icons.category_outlined), findsOneWidget);
        expect(find.text('暂无类别'), findsOneWidget);
        expect(find.text('点击右上角 + 号添加新类别'), findsOneWidget);
      });

      testWidgets('在选择模式下有选中项时应该显示确认按钮', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(selectedCategoryId: '1'));

        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.text('确认选择'), findsOneWidget);
        expect(find.byIcon(Icons.check), findsOneWidget);
      });

      testWidgets('在管理模式下不应该显示确认按钮', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(isSelectionMode: false, selectedCategoryId: '1'),
        );

        expect(find.byType(FloatingActionButton), findsNothing);
      });
    });

    group('类别选择功能测试', () {
      testWidgets('点击类别应该选中该类别', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 找到第一个类别并点击
        final firstCategoryTile = find.byType(Card).first;
        await tester.tap(firstCategoryTile);
        await tester.pump();

        // 验证选中状态
        expect(find.byType(FloatingActionButton), findsOneWidget);
      });

      testWidgets('点击Radio按钮应该选中对应类别', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 找到第二个类别的Radio按钮并点击
        final radioButtons = find.byType(Radio<String>);
        await tester.tap(radioButtons.at(1));
        await tester.pump();

        // 验证选中状态
        expect(find.byType(FloatingActionButton), findsOneWidget);
      });

      testWidgets('预选中的类别应该正确显示', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(selectedCategoryId: '2'));

        // 验证FloatingActionButton存在
        expect(find.byType(FloatingActionButton), findsOneWidget);

        // 验证Radio按钮的选中状态
        final radioButtons = find.byType(Radio<String>);
        expect(radioButtons, findsNWidgets(testCategories.length));
      });

      testWidgets('点击确认选择应该返回选中的类别', (WidgetTester tester) async {
        Category? returnedCategory;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              categoriesProvider.overrideWith(
                (ref) => CategoryNotifier()..state = testCategories,
              ),
            ],
            child: MaterialApp(
              home: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.of(context).push<Category>(
                      MaterialPageRoute(
                        builder: (_) => const CategorySelectionScreen(
                          selectedCategoryId: '1',
                        ),
                      ),
                    );
                    returnedCategory = result;
                  },
                  child: const Text('打开选择'),
                ),
              ),
            ),
          ),
        );

        // 点击打开选择
        await tester.tap(find.text('打开选择'));
        await tester.pumpAndSettle();

        // 点击确认选择
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // 验证返回的类别
        expect(returnedCategory, isNotNull);
        expect(returnedCategory!.id, '1');
      });
    });

    group('类别管理功能测试', () {
      testWidgets('点击添加按钮应该显示添加对话框', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 点击添加按钮
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // 验证对话框出现
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('新增类别'), findsOneWidget);
        expect(find.text('类别名称'), findsOneWidget);
        expect(find.text('请输入类别名称'), findsOneWidget);
        expect(find.text('取消'), findsOneWidget);
        expect(find.text('添加'), findsOneWidget);
      });

      testWidgets('点击新增子类应该显示子类添加对话框', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 点击第一个类别的菜单按钮
        await tester.tap(find.byType(PopupMenuButton<String>).first);
        await tester.pumpAndSettle();

        // 点击新增子类
        await tester.tap(find.text('新增子类'));
        await tester.pumpAndSettle();

        // 验证子类添加对话框出现
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.textContaining('新增子类 - 食品饮料'), findsOneWidget);
        expect(find.text('子类名称'), findsOneWidget);
        expect(find.text('请输入子类名称'), findsOneWidget);
        expect(find.text('取消'), findsOneWidget);
        expect(find.text('添加'), findsOneWidget);
      });

      testWidgets('添加类别时输入为空应该显示验证错误', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 打开添加对话框
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // 直接点击添加按钮（输入为空）
        await tester.tap(find.text('添加'));
        await tester.pump();

        // 验证错误信息
        expect(find.text('请输入类别名称'), findsAtLeastNWidgets(1));
      });

      testWidgets('添加重复名称的类别应该显示错误', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 打开添加对话框
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // 输入已存在的类别名称
        await tester.enterText(find.byType(TextFormField), '食品饮料');
        await tester.tap(find.text('添加'));
        await tester.pump();

        // 验证错误信息
        expect(find.text('类别名称已存在'), findsOneWidget);
      });

      testWidgets('点击取消应该关闭添加对话框', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 打开添加对话框
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // 点击取消
        await tester.tap(find.text('取消'));
        await tester.pumpAndSettle();

        // 验证对话框关闭
        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets('点击菜单中的重命名应该显示编辑对话框', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 点击第一个类别的菜单按钮
        await tester.tap(find.byType(PopupMenuButton<String>).first);
        await tester.pumpAndSettle();

        // 点击重命名
        await tester.tap(find.text('重命名'));
        await tester.pumpAndSettle();

        // 验证编辑对话框出现
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('重命名类别'), findsOneWidget);
        expect(find.text('保存'), findsOneWidget);

        // 验证输入框中有原来的名称
        expect(find.text('食品饮料'), findsAtLeastNWidgets(1));
      });

      testWidgets('点击菜单中的删除应该显示删除确认对话框', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 点击第一个类别的菜单按钮
        await tester.tap(find.byType(PopupMenuButton<String>).first);
        await tester.pumpAndSettle();

        // 点击删除
        await tester.tap(find.text('删除'));
        await tester.pumpAndSettle(); // 验证删除确认对话框出现
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('删除类别'), findsOneWidget);
        expect(find.textContaining('确定要删除类别"食品饮料"吗？'), findsOneWidget);
        expect(find.textContaining('删除后无法恢复'), findsOneWidget);
      });

      testWidgets('添加子类时输入为空应该显示验证错误', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 打开新增子类对话框
        await tester.tap(find.byType(PopupMenuButton<String>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('新增子类'));
        await tester.pumpAndSettle();

        // 直接点击添加按钮（输入为空）
        await tester.tap(find.text('添加'));
        await tester.pump();

        // 验证错误信息
        expect(find.text('请输入子类名称'), findsAtLeastNWidgets(1));
      });

      testWidgets('添加重复名称的子类应该显示错误', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 打开新增子类对话框
        await tester.tap(find.byType(PopupMenuButton<String>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('新增子类'));
        await tester.pumpAndSettle();

        // 输入已存在的类别名称
        await tester.enterText(find.byType(TextFormField), '日用百货');
        await tester.tap(find.text('添加'));
        await tester.pump();

        // 验证错误信息
        expect(find.text('类别名称已存在'), findsOneWidget);
      });

      testWidgets('成功添加子类应该显示成功消息', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 打开新增子类对话框
        await tester.tap(find.byType(PopupMenuButton<String>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('新增子类'));
        await tester.pumpAndSettle();

        // 输入新的子类名称
        await tester.enterText(find.byType(TextFormField), '牛奶饮品');
        await tester.tap(find.text('添加'));
        await tester.pumpAndSettle();

        // 验证成功消息
        expect(find.text('子类"牛奶饮品"添加成功'), findsOneWidget);
      });
    });

    group('子类别层级显示测试', () {
      testWidgets('子类别应该有正确的视觉层级', (WidgetTester tester) async {
        // 创建包含子类的测试数据
        final categoriesWithSub = [
          const Category(id: '1', name: '食品饮料'),
          const Category(id: '2', name: '日用百货'),
          const Category(id: 'sub1', name: '牛奶饮品', parentId: '1'),
          const Category(id: 'sub2', name: '酒类', parentId: '1'),
        ];

        await tester.pumpWidget(
          createTestWidget(categories: categoriesWithSub),
        );

        // 验证主类别
        expect(find.text('食品饮料'), findsOneWidget);
        expect(find.text('日用百货'), findsOneWidget);

        // 验证子类别
        expect(find.text('牛奶饮品'), findsOneWidget);
        expect(find.text('酒类'), findsOneWidget);
        expect(find.text('子类别'), findsNWidgets(2));

        // 验证子类别图标
        expect(find.byIcon(Icons.subdirectory_arrow_right), findsNWidgets(2));
      });

      testWidgets('子类别不应该显示新增子类选项', (WidgetTester tester) async {
        // 创建包含子类的测试数据
        final categoriesWithSub = [
          const Category(id: '1', name: '食品饮料'),
          const Category(id: 'sub1', name: '牛奶饮品', parentId: '1'),
        ];

        await tester.pumpWidget(
          createTestWidget(categories: categoriesWithSub),
        );

        // 找到子类别的菜单按钮并点击
        final menuButtons = find.byType(PopupMenuButton<String>);
        expect(menuButtons, findsNWidgets(2)); // 主类别和子类别各一个

        // 点击子类别的菜单按钮（第二个）
        await tester.tap(menuButtons.at(1));
        await tester.pumpAndSettle();

        // 验证子类别菜单中没有"新增子类"选项
        expect(find.text('新增子类'), findsNothing);
        expect(find.text('重命名'), findsOneWidget);
        expect(find.text('删除'), findsOneWidget);
      });

      testWidgets('顶级类别应该显示新增子类选项', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 点击第一个类别的菜单按钮
        await tester.tap(find.byType(PopupMenuButton<String>).first);
        await tester.pumpAndSettle();

        // 验证顶级类别菜单中有"新增子类"选项
        expect(find.text('新增子类'), findsOneWidget);
        expect(find.text('重命名'), findsOneWidget);
        expect(find.text('删除'), findsOneWidget);
      });

      testWidgets('可以选择子类别', (WidgetTester tester) async {
        // 创建包含子类的测试数据
        final categoriesWithSub = [
          const Category(id: '1', name: '食品饮料'),
          const Category(id: 'sub1', name: '牛奶饮品', parentId: '1'),
        ];

        await tester.pumpWidget(
          createTestWidget(categories: categoriesWithSub),
        );

        // 点击子类别
        await tester.tap(find.text('牛奶饮品'));
        await tester.pump();

        // 验证确认按钮出现
        expect(find.byType(FloatingActionButton), findsOneWidget);
      });
    });

    group('UI状态和样式测试', () {
      testWidgets('选中的类别应该有正确的视觉样式', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(selectedCategoryId: '1'));

        // 验证选中的类别卡片存在
        final cards = find.byType(Card);
        expect(cards, findsNWidgets(testCategories.length));

        // 验证CircleAvatar存在
        expect(find.byType(CircleAvatar), findsNWidgets(testCategories.length));

        // 验证类别图标存在
        expect(
          find.byIcon(Icons.category),
          findsNWidgets(testCategories.length),
        );
      });

      testWidgets('在选择模式下应该显示Radio按钮', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(
          find.byType(Radio<String>),
          findsNWidgets(testCategories.length),
        );
      });

      testWidgets('在管理模式下不应该显示Radio按钮', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isSelectionMode: false));

        expect(find.byType(Radio<String>), findsNothing);
      });

      testWidgets('每个类别都应该有菜单按钮', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(
          find.byType(PopupMenuButton<String>),
          findsNWidgets(testCategories.length),
        );
      });

      testWidgets('ListTile在管理模式下点击应该无效果', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isSelectionMode: false));

        // 点击第一个类别
        await tester.tap(find.byType(Card).first);
        await tester.pump();

        // 验证没有显示确认按钮
        expect(find.byType(FloatingActionButton), findsNothing);
      });
    });

    group('边界情况测试', () {
      testWidgets('当categories为null时应该正常处理', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              categoriesProvider.overrideWith(
                (ref) => CategoryNotifier()..state = [],
              ),
            ],
            child: const MaterialApp(home: CategorySelectionScreen()),
          ),
        );

        expect(find.byType(CategorySelectionScreen), findsOneWidget);
        expect(find.text('暂无类别'), findsOneWidget);
      });

      testWidgets('选中不存在的categoryId应该正常处理', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(selectedCategoryId: 'non-existent-id'),
        );

        expect(find.byType(CategorySelectionScreen), findsOneWidget);
        // 应该没有显示确认按钮，因为选中的ID不存在
        expect(find.byType(FloatingActionButton), findsNothing);
      });

      testWidgets('快速连续点击应该正常处理', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        final firstCard = find.byType(Card).first;

        // 快速连续点击
        await tester.tap(firstCard);
        await tester.tap(firstCard);
        await tester.tap(firstCard);
        await tester.pump();

        // 应该正常显示确认按钮
        expect(find.byType(FloatingActionButton), findsOneWidget);
      });
    });

    group('可访问性测试', () {
      testWidgets('添加按钮应该有正确的tooltip', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        final addButton = find.byIcon(Icons.add);
        expect(addButton, findsOneWidget);

        // 长按以显示tooltip
        await tester.longPress(addButton);
        await tester.pump();

        expect(find.text('新增类别'), findsAtLeastNWidgets(1));
      });

      testWidgets('对话框应该有正确的语义结构', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 打开添加对话框
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle(); // 验证对话框结构
        expect(find.byType(Form), findsOneWidget);
        expect(find.byType(TextFormField), findsOneWidget);
      });
    });
  });
}
