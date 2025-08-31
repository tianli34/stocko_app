import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/shared_widgets/error_widget.dart';

void main() {
  group('CustomErrorWidget', () {
    testWidgets('renders correctly with required message',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomErrorWidget(message: 'Test Error Message'),
          ),
        ),
      );

      expect(find.text('Test Error Message'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('renders with all optional parameters',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomErrorWidget(
              title: 'Error Title',
              message: 'Detailed error message.',
              icon: Icons.warning,
              onRetry: () {},
              retryText: 'Try Again',
              onSecondaryAction: () {},
              secondaryActionText: 'Cancel',
            ),
          ),
        ),
      );

      expect(find.text('Error Title'), findsOneWidget);
      expect(find.text('Detailed error message.'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('does not show icon when showIcon is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomErrorWidget(
              message: 'No Icon Message',
              showIcon: false,
            ),
          ),
        ),
      );

      expect(find.text('No Icon Message'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });
  });

  group('NetworkErrorWidget', () {
    testWidgets('renders correctly with default message',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkErrorWidget(onRetry: () {}),
          ),
        ),
      );

      expect(find.text('网络连接错误'), findsOneWidget);
      expect(find.text('请检查您的网络连接并重试'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.text('重新加载'), findsOneWidget);
    });

    testWidgets('renders with custom message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkErrorWidget(
              onRetry: () {},
              customMessage: 'Custom network error.',
            ),
          ),
        ),
      );

      expect(find.text('Custom network error.'), findsOneWidget);
    });
  });

  group('EmptyStateWidget', () {
    testWidgets('renders correctly with required message',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(message: 'No data available.'),
          ),
        ),
      );

      expect(find.text('暂无数据'), findsOneWidget);
      expect(find.text('No data available.'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('renders with all optional parameters',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'Empty Title',
              message: 'No items to display.',
              icon: Icons.hourglass_empty,
              onAction: () {},
              actionText: 'Refresh',
            ),
          ),
        ),
      );

      expect(find.text('Empty Title'), findsOneWidget);
      expect(find.text('No items to display.'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
    });
  });
}