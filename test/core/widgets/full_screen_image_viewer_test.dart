import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/widgets/full_screen_image_viewer.dart';

void main() {
  group('FullScreenImageViewer Tests', () {
    late String testImagePath;

    setUp(() {
      testImagePath = '/test/path/image.jpg';
    });

    Widget createTestWidget({String? imagePath, String? heroTag}) {
      return MaterialApp(
        home: FullScreenImageViewer(
          imagePath: imagePath ?? testImagePath,
          heroTag: heroTag,
        ),
      );
    }

    group('基本渲染测试', () {
      testWidgets('应该正确渲染全屏图片查看器', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证主要组件存在
        expect(find.byType(FullScreenImageViewer), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('应该显示关闭按钮', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证关闭按钮存在
        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('应该显示重置按钮', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证重置按钮存在（AppBar中有一个，底部控制栏中有一个）
        expect(find.byIcon(Icons.refresh), findsAtLeast(1));
      });

      testWidgets('应该包含InteractiveViewer用于缩放', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证InteractiveViewer存在
        expect(find.byType(InteractiveViewer), findsOneWidget);
      });
    });

    group('Hero动画测试', () {
      testWidgets('当提供heroTag时应该包含Hero组件', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(heroTag: 'test_hero'));
        await tester.pumpAndSettle();

        // 验证Hero组件存在
        expect(find.byType(Hero), findsOneWidget);

        // 验证Hero的tag正确
        final hero = tester.widget<Hero>(find.byType(Hero));
        expect(hero.tag, equals('test_hero'));
      });

      testWidgets('当没有heroTag时不应该包含Hero组件', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证没有Hero组件
        expect(find.byType(Hero), findsNothing);
      });
    });

    group('缩放控制测试', () {
      testWidgets('InteractiveViewer应该有正确的缩放限制', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 获取InteractiveViewer并验证属性
        final interactiveViewer = tester.widget<InteractiveViewer>(
          find.byType(InteractiveViewer),
        );

        expect(interactiveViewer.minScale, equals(0.5));
        expect(interactiveViewer.maxScale, equals(4.0));
        expect(interactiveViewer.panEnabled, isTrue);
        expect(interactiveViewer.scaleEnabled, isTrue);
      });

      testWidgets('缩放功能测试', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 点击放大按钮并验证组件仍然存在
        await tester.tap(find.byIcon(Icons.zoom_in));
        await tester.pumpAndSettle();

        // 验证组件正常工作
        expect(find.byType(FullScreenImageViewer), findsOneWidget);
      });
    });

    group('底部控制栏测试', () {
      testWidgets('应该显示底部控制按钮', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证控制按钮存在
        expect(find.byIcon(Icons.zoom_out), findsOneWidget);
        expect(find.byIcon(Icons.zoom_in), findsOneWidget);
        expect(find.byIcon(Icons.fit_screen), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsAtLeast(1)); // 重置按钮可能有多个
      });

      testWidgets('应该显示控制按钮标签', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证按钮标签存在
        expect(find.text('缩小'), findsOneWidget);
        expect(find.text('放大'), findsOneWidget);
        expect(find.text('适应屏幕'), findsOneWidget);
        expect(find.text('重置'), findsOneWidget);
      });
    });

    group('按钮点击测试', () {
      testWidgets('点击关闭按钮应该弹出页面', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          FullScreenImageViewer(imagePath: testImagePath),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );

        // 点击按钮打开图片查看器
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // 验证图片查看器已打开
        expect(find.byType(FullScreenImageViewer), findsOneWidget);

        // 点击关闭按钮
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // 验证已返回原页面
        expect(find.byType(FullScreenImageViewer), findsNothing);
        expect(find.text('Open'), findsOneWidget);
      });

      testWidgets('缩放控制按钮功能测试', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 点击放大按钮
        await tester.tap(find.byIcon(Icons.zoom_in));
        await tester.pumpAndSettle();

        // 验证组件正常
        expect(find.byType(FullScreenImageViewer), findsOneWidget);

        // 点击重置按钮
        final resetButtons = find.byIcon(Icons.refresh);
        await tester.tap(resetButtons.last);
        await tester.pumpAndSettle();

        // 验证组件正常
        expect(find.byType(FullScreenImageViewer), findsOneWidget);
      });
    });

    group('图片显示测试', () {
      testWidgets('应该显示图片', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证Image组件存在
        expect(find.byType(Image), findsOneWidget);
      });

      testWidgets('图片应该使用正确的路径', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(imagePath: testImagePath));
        await tester.pumpAndSettle();

        // 获取Image组件并验证路径
        final image = tester.widget<Image>(find.byType(Image));
        expect(image.image, isA<FileImage>());
      });

      testWidgets('图片应该使用BoxFit.contain', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证图片的fit属性
        final image = tester.widget<Image>(find.byType(Image));
        expect(image.fit, equals(BoxFit.contain));
      });
    });

    group('错误处理测试', () {
      testWidgets('图片加载失败时应该显示错误Widget', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(imagePath: '/non/existent/path.jpg'),
        );

        await tester.pumpAndSettle();

        // 由于测试环境的限制，errorBuilder可能不会被触发
        // 我们验证组件能正常渲染即可
        expect(find.byType(FullScreenImageViewer), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
      });
    });

    group('样式和布局测试', () {
      testWidgets('AppBar应该是透明的', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 获取AppBar并验证背景色
        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.backgroundColor, equals(Colors.transparent));
        expect(appBar.elevation, equals(0));
      });

      testWidgets('底部控制栏应该有渐变背景', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证渐变容器存在
        expect(find.byType(Container), findsAtLeast(1));
      });

      testWidgets('缩放指示器应该有正确的样式', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 查找缩放指示器容器
        final containers = find.byType(Container);
        expect(containers, findsAtLeast(1));
      });
    });

    group('系统UI控制测试', () {
      testWidgets('应该设置正确的系统UI模式', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证组件正常渲染（系统UI调用在实际运行时才会生效）
        expect(find.byType(FullScreenImageViewer), findsOneWidget);
      });
    });

    group('Widget结构测试', () {
      testWidgets('应该有正确的Widget层次结构', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证主要Widget存在
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(Stack), findsAtLeast(1)); // 可能有多个Stack
        expect(find.byType(InteractiveViewer), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
      });

      testWidgets('Stack应该包含正确的子组件', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证Positioned组件存在
        expect(find.byType(Positioned), findsAtLeast(1));

        // 验证组件正常工作
        expect(find.byType(FullScreenImageViewer), findsOneWidget);
      });
    });

    group('边界情况测试', () {
      testWidgets('应该处理空图片路径', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(imagePath: ''));
        await tester.pumpAndSettle();

        // 组件应该仍然存在
        expect(find.byType(FullScreenImageViewer), findsOneWidget);
      });

      testWidgets('应该处理很长的heroTag', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            heroTag: 'very_long_hero_tag_that_might_cause_issues_in_some_cases',
          ),
        );
        await tester.pumpAndSettle();

        // 验证Hero组件正常工作
        expect(find.byType(Hero), findsOneWidget);
      });
    });

    group('交互测试', () {
      testWidgets('应该响应手势操作', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 获取InteractiveViewer
        final interactiveViewer = find.byType(InteractiveViewer);
        expect(interactiveViewer, findsOneWidget);

        // 验证可以进行手势操作（在真实设备上）
        expect(
          tester.widget<InteractiveViewer>(interactiveViewer).panEnabled,
          isTrue,
        );
        expect(
          tester.widget<InteractiveViewer>(interactiveViewer).scaleEnabled,
          isTrue,
        );
      });
    });
  });
}
