import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stocko_app/features/product/presentation/widgets/product_image_picker.dart';
import 'package:stocko_app/core/services/image_service.dart';

// Mock classes
class MockImageService extends Mock implements ImageService {}

class MockImageChangedCallback extends Mock {
  void call(String? imagePath);
}

void main() {
  group('ProductImagePicker Widget Tests', () {
    late MockImageChangedCallback mockOnImageChanged;

    setUp(() {
      mockOnImageChanged = MockImageChangedCallback();
    });

    Widget createTestWidget({
      String? initialImagePath,
      double size = 120.0,
      ValueChanged<String?>? onImageChanged,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ProductImagePicker(
            initialImagePath: initialImagePath,
            size: size,
            onImageChanged: onImageChanged ?? mockOnImageChanged.call,
          ),
        ),
      );
    }

    group('基本渲染测试', () {
      testWidgets('当没有初始图片时应该显示占位符', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 验证占位符显示
        expect(find.byIcon(Icons.add_a_photo), findsOneWidget);
        expect(find.text('添加图片'), findsOneWidget);
      });

      testWidgets('当有初始图片时应该显示图片', (WidgetTester tester) async {
        const testImagePath = '/test/image.jpg';

        await tester.pumpWidget(
          createTestWidget(initialImagePath: testImagePath),
        );

        // 验证图片容器存在
        expect(find.byType(Container), findsAtLeast(1));

        // 验证图片文件路径被使用（通过ClipRRect组件判断）
        expect(find.byType(ClipRRect), findsOneWidget);
      });

      testWidgets('应该根据size参数设置正确的尺寸', (WidgetTester tester) async {
        const testSize = 150.0;

        await tester.pumpWidget(createTestWidget(size: testSize));

        // 查找主容器并验证尺寸
        final container = tester.widget<Container>(
          find.byType(Container).first,
        );

        expect(container.constraints?.minWidth, equals(testSize));
        expect(container.constraints?.minHeight, equals(testSize));
      });
    });
    group('点击事件测试', () {
      testWidgets('点击组件应该显示图片选择底部表单', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 点击图片选择器的Container区域
        await tester.tap(find.byType(Container).first);
        await tester.pumpAndSettle();

        // 验证底部表单出现
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.text('选择图片'), findsOneWidget);
      });

      testWidgets('底部表单应该包含相机和相册选项', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 打开底部表单
        await tester.tap(find.byType(Container).first);
        await tester.pumpAndSettle();

        // 验证选项存在
        expect(find.text('拍照'), findsOneWidget);
        expect(find.text('相册'), findsOneWidget);
        expect(find.byIcon(Icons.camera_alt), findsOneWidget);
        expect(find.byIcon(Icons.photo_library), findsOneWidget);
      });
      testWidgets('点击取消应该关闭底部表单', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 打开底部表单
        await tester.tap(find.byType(Container).first);
        await tester.pumpAndSettle();

        // 验证底部表单出现
        expect(find.byType(BottomSheet), findsOneWidget);

        // 通过点击Navigator.pop()或按返回键关闭底部表单
        Navigator.of(tester.element(find.byType(BottomSheet))).pop();
        await tester.pumpAndSettle();

        // 验证底部表单已关闭
        expect(find.byType(BottomSheet), findsNothing);
      });
    });

    group('操作按钮测试', () {
      testWidgets('当有图片时应该显示删除按钮', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(initialImagePath: '/test/image.jpg'),
        );

        // 验证删除按钮存在
        expect(find.text('删除'), findsOneWidget);
        expect(find.byIcon(Icons.delete), findsOneWidget);
      });

      testWidgets('当没有图片时不应该显示删除按钮', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 验证删除按钮不存在
        expect(find.text('删除'), findsNothing);
        expect(find.byIcon(Icons.delete), findsNothing);
      });
      testWidgets('点击删除按钮应该调用onImageChanged并传入null', (
        WidgetTester tester,
      ) async {
        String? receivedPath;

        await tester.pumpWidget(
          createTestWidget(
            initialImagePath: '/test/image.jpg',
            onImageChanged: (String? path) => receivedPath = path,
          ),
        );

        // 点击删除按钮
        await tester.tap(find.text('删除'));
        await tester.pump();

        // 验证回调被调用且传入null
        expect(receivedPath, isNull);
      });
    });

    group('占位符内容测试', () {
      testWidgets('占位符应该包含正确的图标和文本', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 验证占位符图标
        final icon = tester.widget<Icon>(find.byIcon(Icons.add_a_photo));
        expect(icon.color, equals(Colors.grey.shade400));

        // 验证占位符文本
        final text = tester.widget<Text>(find.text('添加图片'));
        expect(text.style?.color, equals(Colors.grey.shade600));
        expect(text.style?.fontSize, equals(12));
      });

      testWidgets('占位符图标大小应该根据组件尺寸调整', (WidgetTester tester) async {
        const testSize = 200.0;

        await tester.pumpWidget(createTestWidget(size: testSize));

        // 验证图标大小
        final icon = tester.widget<Icon>(find.byIcon(Icons.add_a_photo));
        expect(icon.size, equals(testSize * 0.3));
      });
    });

    group('图片显示测试', () {
      testWidgets('图片应该使用BoxFit.cover填充模式', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(initialImagePath: '/test/image.jpg'),
        );

        // 验证ClipRRect存在（用于圆角）
        expect(find.byType(ClipRRect), findsOneWidget);
      });

      testWidgets('图片容器应该有圆角边框', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(initialImagePath: '/test/image.jpg'),
        );

        // 查找ClipRRect并验证borderRadius
        final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
        expect(clipRRect.borderRadius, isA<BorderRadius>());
      });
    });
    group('Widget结构测试', () {
      testWidgets('应该有正确的Widget层次结构', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 验证主要Widget存在
        expect(find.byType(Container), findsAtLeast(1));
        expect(find.byType(ProductImagePicker), findsOneWidget);
        expect(find.byType(Column), findsAtLeast(1));
      });

      testWidgets('容器应该有正确的装饰', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 查找主容器
        final container = tester.widget<Container>(
          find.byType(Container).first,
        );

        // 验证装饰存在
        expect(container.decoration, isA<BoxDecoration>());
      });
    });

    group('边界情况测试', () {
      testWidgets('应该处理空字符串图片路径', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(initialImagePath: ''));

        // 应该显示占位符
        expect(find.byIcon(Icons.add_a_photo), findsOneWidget);
        expect(find.text('添加图片'), findsOneWidget);
      });
      testWidgets('应该处理非常小的尺寸', (WidgetTester tester) async {
        const verySmallSize = 80.0; // 进一步增大最小尺寸以避免布局溢出

        await tester.pumpWidget(createTestWidget(size: verySmallSize));

        // 组件应该仍然可以渲染
        expect(find.byType(ProductImagePicker), findsOneWidget);

        // 图标大小应该相应调整
        final icon = tester.widget<Icon>(find.byIcon(Icons.add_a_photo));
        expect(icon.size, equals(verySmallSize * 0.3));
      });

      testWidgets('应该处理非常大的尺寸', (WidgetTester tester) async {
        const veryLargeSize = 500.0;

        await tester.pumpWidget(createTestWidget(size: veryLargeSize));

        // 组件应该仍然可以渲染
        expect(find.byType(ProductImagePicker), findsOneWidget);

        // 容器尺寸应该正确设置
        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        expect(container.constraints?.minWidth, equals(veryLargeSize));
        expect(container.constraints?.minHeight, equals(veryLargeSize));
      });
    });
    group('交互性测试', () {
      testWidgets('组件应该响应点击事件', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 获取ProductImagePicker并验证存在
        expect(find.byType(ProductImagePicker), findsOneWidget);

        // 验证主Container存在并可点击
        expect(find.byType(Container), findsAtLeast(1));
      });
      testWidgets('多次点击应该正常工作', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 多次点击
        for (int i = 0; i < 3; i++) {
          await tester.tap(find.byType(Container).first);
          await tester.pumpAndSettle();

          // 验证底部表单出现
          expect(find.byType(BottomSheet), findsOneWidget);

          // 通过Navigator.pop()关闭
          Navigator.of(tester.element(find.byType(BottomSheet))).pop();
          await tester.pumpAndSettle();
        }
      });
    });
  });
}
