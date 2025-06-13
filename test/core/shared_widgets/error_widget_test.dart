import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/shared_widgets/error_widget.dart';

void main() {
  group('CustomErrorWidget Tests', () {
    testWidgets('应该显示基本错误信息', (WidgetTester tester) async {
      const errorMessage = '发生了错误';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CustomErrorWidget(message: errorMessage)),
        ),
      ); // 验证错误消息存在
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.byType(CustomErrorWidget), findsOneWidget);
      expect(find.byType(Column), findsAtLeast(1));
    });

    testWidgets('应该显示自定义标题', (WidgetTester tester) async {
      const errorTitle = '网络错误';
      const errorMessage = '连接失败';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomErrorWidget(title: errorTitle, message: errorMessage),
          ),
        ),
      );

      // 验证标题和消息都存在
      expect(find.text(errorTitle), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('应该显示默认错误图标', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CustomErrorWidget(message: '错误消息')),
        ),
      );

      // 验证图标存在
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('应该显示自定义图标', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomErrorWidget(message: '网络错误', icon: Icons.wifi_off),
          ),
        ),
      );

      // 验证自定义图标存在
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('应该隐藏图标当showIcon为false时', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomErrorWidget(message: '错误消息', showIcon: false),
          ),
        ),
      );

      // 验证没有图标
      expect(find.byType(Icon), findsNothing);
      expect(find.text('错误消息'), findsOneWidget);
    });

    testWidgets('应该显示重试按钮', (WidgetTester tester) async {
      bool retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomErrorWidget(
              message: '错误消息',
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      ); // 验证重试按钮存在
      expect(find.text('重试'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // 点击重试按钮
      await tester.tap(find.text('重试'));
      expect(retryPressed, isTrue);
    });

    testWidgets('应该显示自定义重试按钮文本', (WidgetTester tester) async {
      const customRetryText = '重新加载';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomErrorWidget(
              message: '错误消息',
              onRetry: () {},
              retryText: customRetryText,
            ),
          ),
        ),
      );

      // 验证自定义重试文本存在
      expect(find.text(customRetryText), findsOneWidget);
      expect(find.text('重试'), findsNothing);
    });

    testWidgets('应该显示次要操作按钮', (WidgetTester tester) async {
      bool secondaryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomErrorWidget(
              message: '错误消息',
              onSecondaryAction: () => secondaryPressed = true,
              secondaryActionText: '返回首页',
            ),
          ),
        ),
      ); // 验证次要操作按钮存在
      expect(find.text('返回首页'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);

      // 点击次要操作按钮
      await tester.tap(find.text('返回首页'));
      expect(secondaryPressed, isTrue);
    });

    testWidgets('应该同时显示重试和次要操作按钮', (WidgetTester tester) async {
      bool retryPressed = false;
      bool secondaryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomErrorWidget(
              message: '错误消息',
              onRetry: () => retryPressed = true,
              onSecondaryAction: () => secondaryPressed = true,
              secondaryActionText: '返回',
            ),
          ),
        ),
      ); // 验证两个按钮都存在
      expect(find.text('重试'), findsOneWidget);
      expect(find.text('返回'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);

      // 测试两个按钮的功能
      await tester.tap(find.text('重试'));
      expect(retryPressed, isTrue);

      await tester.tap(find.text('返回'));
      expect(secondaryPressed, isTrue);
    });

    testWidgets('当没有回调时不应该显示按钮', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CustomErrorWidget(message: '错误消息')),
        ),
      ); // 验证没有按钮
      expect(find.byIcon(Icons.refresh), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('应该正确布局所有元素', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomErrorWidget(
              title: '错误标题',
              message: '错误详情消息',
              onRetry: () {},
              onSecondaryAction: () {},
              secondaryActionText: '取消',
            ),
          ),
        ),
      );

      // 验证所有元素都存在
      expect(find.text('错误标题'), findsOneWidget);
      expect(find.text('错误详情消息'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      // 验证布局结构
      expect(find.byType(CustomErrorWidget), findsOneWidget);
      expect(find.byType(Column), findsAtLeast(1));
      expect(find.byType(Padding), findsAtLeast(1));
    });
  });
}
