import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stocko_app/features/product/domain/model/product.dart';
import 'package:stocko_app/features/product/application/provider/product_providers.dart';
import 'package:stocko_app/features/product/presentation/widgets/product_list_tile.dart';
// Add missing imports for database and repository
import 'package:stocko_app/features/product/domain/repository/i_product_repository.dart';
import 'package:stocko_app/features/product/data/repository/product_repository.dart';
import 'package:stocko_app/core/database/database.dart';

// Mock classes
class MockProductRepository extends Mock implements IProductRepository {}

class MockAppDatabase extends Mock implements AppDatabase {}

/// Mock Ref for testing
class MockRef extends Mock implements Ref {
  @override
  void invalidate(ProviderOrFamily provider) {
    // 测试中不需要实际刷新
  }
}

/// 测试用的 ProductController
class TestProductController extends ProductController {
  TestProductController() : super(MockProductRepository(), MockRef());

  void setLoadingState() {
    state = const ProductControllerState(
      status: ProductOperationStatus.loading,
    );
  }

  void setInitialState() {
    state = const ProductControllerState(
      status: ProductOperationStatus.initial,
    );
  }
}

void main() {
  group('ProductListTile Widget Tests', () {
    late Product testProduct;
    late MockProductRepository mockRepository;
    late MockAppDatabase mockDatabase;

    setUp(() {
      mockRepository = MockProductRepository();
      mockDatabase = MockAppDatabase();

      // 创建测试产品数据
      testProduct = Product(
        id: 'test_id_123',
        name: '测试产品',
        sku: 'TEST001',
        barcode: '1234567890123',
        categoryId: 'category_1',
        brand: '测试品牌',
        specification: '500ml',
        unitId: 'unit_1',
        suggestedRetailPrice: 10.0,
        retailPrice: 15.0,
        promotionalPrice: 12.0,
        stockWarningValue: 10,
        shelfLife: 365,
        shelfLifeUnit: 'days',
        ownership: '测试公司',
        remarks: '测试备注',
        image: '/test/image.jpg',
        lastUpdated: DateTime(2024, 1, 2),
      );
    });
    Widget createTestWidget({
      Product? product,
      VoidCallback? onTap,
      VoidCallback? onEdit,
      VoidCallback? onDelete,
      bool showActions = true,
      bool showPrice = true,
    }) {
      final loadingController = TestProductController();
      loadingController.setInitialState();

      return ProviderScope(
        overrides: [
          // Override the database provider
          appDatabaseProvider.overrideWithValue(mockDatabase),
          // Override the repository provider
          productRepositoryProvider.overrideWithValue(mockRepository),
          // Override the controller provider
          productControllerProvider.overrideWith((ref) {
            return loadingController;
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ProductListTile(
              product: product ?? testProduct,
              onTap: onTap,
              onEdit: onEdit,
              onDelete: onDelete,
              showActions: showActions,
              showPrice: showPrice,
            ),
          ),
        ),
      );
    }

    group('基本渲染测试', () {
      testWidgets('应该正确显示产品基本信息', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 验证产品名称
        expect(find.text('测试产品'), findsOneWidget);
        // 验证产品编码
        expect(find.text('TEST001'), findsOneWidget);
      });

      testWidgets('应该正确显示价格信息', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 验证促销价显示
        expect(find.textContaining('￥12.00'), findsOneWidget);

        // 验证原价显示（有删除线）
        expect(find.textContaining('原价: ￥15.00'), findsOneWidget);
      });

      testWidgets('当showPrice为false时不应该显示价格', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showPrice: false));

        // 验证价格不显示
        expect(find.textContaining('￥'), findsNothing);
      });

      testWidgets('应该显示产品详细信息', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget()); // 验证品牌信息
        expect(find.textContaining('品牌:'), findsOneWidget);
        expect(find.text('测试品牌'), findsOneWidget); // 验证规格信息
        expect(find.textContaining('规格:'), findsOneWidget);
        expect(find.text('500ml'), findsOneWidget);
      });
    });

    group('操作按钮测试', () {
      testWidgets('当showActions为true时应该显示操作按钮', (WidgetTester tester) async {
        bool editCalled = false;
        bool deleteCalled = false;

        await tester.pumpWidget(
          createTestWidget(
            onEdit: () => editCalled = true,
            onDelete: () => deleteCalled = true,
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

        // 测试删除按钮点击
        await tester.tap(deleteButton);
        await tester.pump();
        expect(deleteCalled, isTrue);
      });

      testWidgets('当showActions为false时不应该显示操作按钮', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showActions: false));

        // 验证操作按钮不存在
        expect(find.text('编辑'), findsNothing);
        expect(find.text('删除'), findsNothing);
      });
      testWidgets('当控制器加载中时按钮应该被禁用', (WidgetTester tester) async {
        final loadingController = TestProductController();
        loadingController.setLoadingState();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(mockDatabase),
              productRepositoryProvider.overrideWithValue(mockRepository),
              productControllerProvider.overrideWith((ref) {
                return loadingController;
              }),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: ProductListTile(
                  product: testProduct,
                  onEdit: () {},
                  onDelete: () {},
                ),
              ),
            ),
          ),
        );

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

        // 点击卡片
        await tester.tap(find.byType(Card));
        await tester.pump();

        expect(tapCalled, isTrue);
      });

      testWidgets('当没有onTap回调时点击卡片不应该报错', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 点击卡片不应该报错
        await tester.tap(find.byType(Card));
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    });

    group('图片显示测试', () {
      testWidgets('当产品有图片时应该显示CachedImageWidget', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 验证图片组件存在
        expect(find.byType(ClipRRect), findsAtLeast(1));
      });

      testWidgets('当产品没有图片时应该显示占位符', (WidgetTester tester) async {
        final productWithoutImage = testProduct.copyWith(image: null);

        await tester.pumpWidget(
          createTestWidget(product: productWithoutImage),
        ); // 验证占位符图标存在
        expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      });
    });

    group('没有促销价的产品测试', () {
      testWidgets('没有促销价时应该显示零售价', (WidgetTester tester) async {
        final productWithoutPromo = testProduct.copyWith(
          promotionalPrice: null,
        );

        await tester.pumpWidget(
          createTestWidget(product: productWithoutPromo),
        ); // 验证零售价显示
        expect(find.textContaining('￥15.00'), findsOneWidget);

        // 验证没有促销价显示（应该只显示零售价）
        expect(find.textContaining('原价:'), findsNothing);
      });
    });

    group('可选字段测试', () {
      testWidgets('当品牌为null时不应该显示品牌信息', (WidgetTester tester) async {
        final productWithoutBrand = testProduct.copyWith(brand: null);

        await tester.pumpWidget(
          createTestWidget(product: productWithoutBrand),
        ); // 验证品牌信息不显示
        expect(find.textContaining('品牌:'), findsNothing);
      });

      testWidgets('当规格为null时不应该显示规格信息', (WidgetTester tester) async {
        final productWithoutSpec = testProduct.copyWith(specification: null);

        await tester.pumpWidget(
          createTestWidget(product: productWithoutSpec),
        ); // 验证规格信息不显示
        expect(find.textContaining('规格:'), findsNothing);
      });
    });

    group('Widget结构测试', () {
      testWidgets('应该有正确的Widget层次结构', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 验证主要Widget存在
        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(InkWell), findsOneWidget);
        expect(find.byType(Row), findsAtLeast(1));
        expect(find.byType(Column), findsAtLeast(1));
      });
    });
  });
}
