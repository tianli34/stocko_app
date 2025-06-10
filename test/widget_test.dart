// This is a basic Flutter widget test for Stocko App.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stocko_app/app.dart';

void main() {
  testWidgets('Stocko App homepage smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Wrap with ProviderScope as the app uses Riverpod
    await tester.pumpWidget(const ProviderScope(child: StockoApp()));

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Verify that the home page loads correctly.
    expect(find.text('欢迎使用 Stocko 库存管理系统'), findsOneWidget);
    expect(find.text('请选择功能模块'), findsOneWidget);

    // Verify that the navigation buttons are present.
    expect(find.text('产品管理'), findsOneWidget);
    expect(find.text('库存管理'), findsOneWidget);
    expect(find.text('销售管理'), findsOneWidget);
    expect(find.text('数据库测试'), findsOneWidget);

    // Test that buttons are tappable (without actually navigating)
    final productButton = find.text('产品管理');
    expect(productButton, findsOneWidget);

    // Verify the button exists and is enabled
    final buttonWidget = tester.widget<ElevatedButton>(
      find.ancestor(of: productButton, matching: find.byType(ElevatedButton)),
    );
    expect(buttonWidget.onPressed, isNotNull);
  });
}
