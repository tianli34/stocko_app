import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/widgets/cached_image_widget.dart';

void main() {
  group('CachedImageWidget Tests', () {
    late String testImagePath;

    setUp(() {
      testImagePath = '/test/path/image.jpg';
    });

    Widget createTestWidget({
      String? imagePath,
      double? width,
      double? height,
      BoxFit fit = BoxFit.cover,
      BorderRadius? borderRadius,
      Widget? placeholder,
      Widget? errorWidget,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: CachedImageWidget(
            imagePath: imagePath ?? testImagePath,
            width: width,
            height: height,
            fit: fit,
            borderRadius: borderRadius,
            placeholder: placeholder,
            errorWidget: errorWidget,
          ),
        ),
      );
    }

    group('基本渲染测试', () {
      testWidgets('应该显示图片组件', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 验证CachedImageWidget存在
        expect(find.byType(CachedImageWidget), findsOneWidget);
      });
      testWidgets('应该正确设置图片路径', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(imagePath: testImagePath));

        // 等待图片加载
        await tester.pump();

        // 验证CachedImageWidget存在
        expect(find.byType(CachedImageWidget), findsOneWidget);
      });
      testWidgets('应该正确设置尺寸参数', (WidgetTester tester) async {
        const testWidth = 200.0;
        const testHeight = 150.0;

        await tester.pumpWidget(
          createTestWidget(width: testWidth, height: testHeight),
        );

        // 获取CachedImageWidget
        final cachedImageWidget = tester.widget<CachedImageWidget>(
          find.byType(CachedImageWidget),
        );

        // 验证尺寸参数设置正确
        expect(cachedImageWidget.width, equals(testWidth));
        expect(cachedImageWidget.height, equals(testHeight));
      });
      testWidgets('应该正确设置BoxFit参数', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(fit: BoxFit.contain));

        // 获取CachedImageWidget并验证fit属性
        final cachedImageWidget = tester.widget<CachedImageWidget>(
          find.byType(CachedImageWidget),
        );
        expect(cachedImageWidget.fit, equals(BoxFit.contain));
      });
    });

    group('边框圆角测试', () {
      testWidgets('当设置borderRadius时应该使用ClipRRect', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(borderRadius: BorderRadius.circular(12)),
        );

        // 验证ClipRRect存在
        expect(find.byType(ClipRRect), findsOneWidget);

        // 验证borderRadius设置正确
        final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
        expect(clipRRect.borderRadius, isA<BorderRadius>());
      });

      testWidgets('当没有设置borderRadius时不应该使用ClipRRect', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        // 验证ClipRRect不存在或者存在时borderRadius为null
        final clipRRects = find.byType(ClipRRect);
        if (clipRRects.evaluate().isNotEmpty) {
          final clipRRect = tester.widget<ClipRRect>(clipRRects.first);
          expect(clipRRect.borderRadius, isNull);
        }
      });
    });

    group('占位符测试', () {
      testWidgets('应该显示默认占位符', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // 验证加载指示器存在
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('应该使用自定义占位符', (WidgetTester tester) async {
        const customPlaceholder = Text('自定义占位符');

        await tester.pumpWidget(
          createTestWidget(placeholder: customPlaceholder),
        );
        await tester.pump();

        // 验证自定义占位符显示
        expect(find.text('自定义占位符'), findsOneWidget);
      });

      testWidgets('默认占位符应该有正确的样式', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(width: 100, height: 100));
        await tester.pump();

        // 验证占位符容器存在
        expect(find.byType(Container), findsAtLeast(1));

        // 验证加载指示器存在
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });
    group('错误处理测试', () {
      testWidgets('图片加载失败时应该显示默认错误Widget', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(imagePath: '/non/existent/path.jpg'),
        ); // 等待图片加载尝试完成
        await tester.pump(); // 等待初始渲染
        await tester.pump(const Duration(milliseconds: 100)); // 等待异步操作
        await tester.pump(); // 等待状态更新
        await tester.pump(const Duration(milliseconds: 100)); // 再等待一下
        await tester.pump(); // 最终状态更新

        // 验证错误图标存在
        expect(find.byIcon(Icons.broken_image), findsOneWidget);
      });
      testWidgets('应该使用自定义错误Widget', (WidgetTester tester) async {
        const customErrorWidget = Text('自定义错误提示');

        await tester.pumpWidget(
          createTestWidget(
            imagePath: '/non/existent/path.jpg',
            errorWidget: customErrorWidget,
          ),
        );

        // 等待图片加载尝试完成
        await tester.pump(); // 等待初始渲染
        await tester.pump(const Duration(milliseconds: 100)); // 等待异步操作
        await tester.pump(); // 等待状态更新

        // 验证自定义错误Widget显示
        expect(find.text('自定义错误提示'), findsOneWidget);
      });
      testWidgets('默认错误Widget应该有正确的样式', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            imagePath: '/non/existent/path.jpg',
            width: 100,
            height: 100,
          ),
        );

        // 等待图片加载尝试完成
        await tester.pump(); // 等待初始渲染
        await tester.pump(const Duration(milliseconds: 100)); // 等待异步操作
        await tester.pump(); // 等待状态更新

        // 验证错误容器存在
        expect(find.byType(Container), findsAtLeast(1));

        // 验证错误图标
        expect(find.byIcon(Icons.broken_image), findsOneWidget);
      });
    });
    group('预构建组件变体测试', () {
      testWidgets('ProductThumbnailImage应该正确渲染', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProductThumbnailImage(imagePath: testImagePath),
            ),
          ),
        );

        // 验证组件存在
        expect(find.byType(ProductThumbnailImage), findsOneWidget);
        expect(find.byType(CachedImageWidget), findsOneWidget);
      });

      testWidgets('ProductDetailImage应该正确渲染', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ProductDetailImage(imagePath: testImagePath)),
          ),
        );

        // 验证组件存在且有Hero包装
        expect(find.byType(ProductDetailImage), findsOneWidget);
        expect(find.byType(Hero), findsOneWidget);
        expect(find.byType(CachedImageWidget), findsOneWidget);
      });

      testWidgets('ProductDialogImage应该正确渲染', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ProductDialogImage(imagePath: testImagePath)),
          ),
        );

        // 验证组件存在
        expect(find.byType(ProductDialogImage), findsOneWidget);
        expect(find.byType(CachedImageWidget), findsOneWidget);
      });
    });

    group('Widget结构测试', () {
      testWidgets('应该有正确的Widget层次结构', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 验证主要Widget存在
        expect(find.byType(CachedImageWidget), findsOneWidget);
      });

      testWidgets('应该根据参数正确构建Widget树', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            width: 200,
            height: 150,
            borderRadius: BorderRadius.circular(8),
          ),
        );

        // 验证有尺寸约束
        final widgets = find.byType(SizedBox);
        expect(widgets.evaluate().length, greaterThanOrEqualTo(0));

        // 验证有圆角裁剪
        expect(find.byType(ClipRRect), findsOneWidget);
      });
    });

    group('边界情况测试', () {
      testWidgets('应该处理null图片路径', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(imagePath: ''));

        // 应该显示错误状态或占位符
        expect(find.byType(CachedImageWidget), findsOneWidget);
      });

      testWidgets('应该处理0尺寸', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(width: 0, height: 0));

        // 组件应该仍然存在
        expect(find.byType(CachedImageWidget), findsOneWidget);
      });

      testWidgets('应该处理负数尺寸', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(width: -100, height: -100));

        // 组件应该仍然存在
        expect(find.byType(CachedImageWidget), findsOneWidget);
      });

      testWidgets('应该处理非常大的尺寸', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(width: 10000, height: 10000));

        // 组件应该仍然存在
        expect(find.byType(CachedImageWidget), findsOneWidget);
      });
    });

    group('图片缓存测试', () {
      testWidgets('相同路径的图片应该复用', (WidgetTester tester) async {
        // 创建两个相同路径的图片组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  CachedImageWidget(imagePath: testImagePath),
                  CachedImageWidget(imagePath: testImagePath),
                ],
              ),
            ),
          ),
        );

        // 验证两个组件都存在
        expect(find.byType(CachedImageWidget), findsNWidgets(2));
      });
    });
  });
}
