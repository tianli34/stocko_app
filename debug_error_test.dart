import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/widgets/cached_image_widget.dart';

void main() {
  testWidgets('Debug error widget test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CachedImageWidget(imagePath: '/non/existent/path.jpg'),
        ),
      ),
    );

    // 使用 pumpAndSettle 等待所有异步操作完成
    await tester.pumpAndSettle();

    // 查找所有图标
    final iconWidgets = find.byType(Icon);
    print('Found ${iconWidgets.evaluate().length} icons');
    for (final iconWidget in iconWidgets.evaluate()) {
      final icon = iconWidget.widget as Icon;
      print('Icon: ${icon.icon}');
    }

    // 查找broken image图标
    final brokenImageIcon = find.byIcon(Icons.broken_image);
    print('Broken image icons found: ${brokenImageIcon.evaluate().length}');

    expect(brokenImageIcon, findsOneWidget);
  });
}
