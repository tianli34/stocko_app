import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/widgets/cached_image_widget.dart';

void main() {
  testWidgets('Debug CachedImageWidget error handling', (
    WidgetTester tester,
  ) async {
    debugPrint('开始测试 CachedImageWidget 错误处理');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CachedImageWidget(
            imagePath: '/non/existent/path.jpg',
            width: 100,
            height: 100,
          ),
        ),
      ),
    );

    debugPrint('初始组件已构建，等待加载...');

    // 等待初始渲染
    await tester.pump();
    debugPrint('第一次 pump 完成');

    // 等待异步操作
    await tester.pump(const Duration(milliseconds: 100));
    debugPrint('第二次 pump 完成');

    // 等待状态更新
    await tester.pump();
    debugPrint('第三次 pump 完成');

    // 查找所有图标
    debugPrint('查找所有Icon:');
    final iconFinder = find.byType(Icon);
    final icons = tester.widgetList<Icon>(iconFinder);
    for (final icon in icons) {
      debugPrint(
        '  - Icon: ${icon.icon}, size: ${icon.size}, color: ${icon.color}',
      );
    }

    // 查找broken_image图标
    debugPrint('查找 broken_image 图标');
    final brokenImageFinder = find.byIcon(Icons.broken_image);
    debugPrint(
      'Found ${brokenImageFinder.evaluate().length} broken_image icons',
    );

    // 查找CircularProgressIndicator
    debugPrint('查找 CircularProgressIndicator');
    final progressFinder = find.byType(CircularProgressIndicator);
    debugPrint(
      'Found ${progressFinder.evaluate().length} CircularProgressIndicator',
    );

    // 查找所有文本
    debugPrint('查找所有Text:');
    final textFinder = find.byType(Text);
    final texts = tester.widgetList<Text>(textFinder);
    for (final text in texts) {
      debugPrint('  - Text: "${text.data}"');
    }
  });
}
