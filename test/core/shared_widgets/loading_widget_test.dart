import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/shared_widgets/loading_widget.dart';

void main() {
  group('LoadingWidget Tests', () {
    testWidgets('应该显示默认的加载指示器', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LoadingWidget())),
      );

      // 验证CircularProgressIndicator存在
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(Center), findsOneWidget);
    });

    testWidgets('应该显示自定义消息', (WidgetTester tester) async {
      const testMessage = '正在加载数据...';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LoadingWidget(message: testMessage)),
        ),
      );

      // 验证消息文本存在
      expect(find.text(testMessage), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('应该隐藏消息当showMessage为false时', (WidgetTester tester) async {
      const testMessage = '正在加载数据...';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(message: testMessage, showMessage: false),
          ),
        ),
      );

      // 验证消息文本不存在
      expect(find.text(testMessage), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('应该使用自定义尺寸', (WidgetTester tester) async {
      const customSize = 60.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LoadingWidget(size: customSize)),
        ),
      );

      // 验证SizedBox尺寸
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, customSize);
      expect(sizedBox.height, customSize);
    });

    testWidgets('应该使用自定义颜色', (WidgetTester tester) async {
      const customColor = Colors.red;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LoadingWidget(color: customColor)),
        ),
      );

      // 验证CircularProgressIndicator颜色
      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.color, customColor);
    });

    testWidgets('当message为null时不应该显示文本', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LoadingWidget(message: null))),
      );

      // 验证没有文本组件
      expect(find.byType(Text), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
  group('LoadingOverlay Tests', () {
    testWidgets('当isLoading为false时应该只显示子组件', (WidgetTester tester) async {
      const childText = '主要内容';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(isLoading: false, child: Text(childText)),
          ),
        ),
      );

      // 验证子组件存在，加载指示器不存在
      expect(find.text(childText), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // LoadingOverlay总是使用Stack，所以应该存在
      expect(find.byType(Stack), findsAtLeast(1));
    });
    testWidgets('当isLoading为true时应该显示覆盖层', (WidgetTester tester) async {
      const childText = '主要内容';
      const loadingMessage = '正在处理...';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(
              isLoading: true,
              loadingMessage: loadingMessage,
              child: Text(childText),
            ),
          ),
        ),
      );

      // 验证Stack和加载指示器存在
      expect(find.byType(Stack), findsAtLeast(1));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(loadingMessage), findsOneWidget);

      // 子组件仍然存在但被覆盖
      expect(find.text(childText), findsOneWidget);
    });
    testWidgets('应该显示半透明背景', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(isLoading: true, child: Text('内容')),
          ),
        ),
      );

      // 验证Container组件存在（用于创建覆盖层）
      expect(find.byType(Container), findsAtLeast(1));
      expect(find.byType(Stack), findsAtLeast(1));
    });
  });
}
