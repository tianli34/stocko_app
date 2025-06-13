import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stocko_app/features/product/presentation/screens/barcode_scanner_screen.dart';

void main() {
  group('BarcodeScannerScreen Tests', () {
    Widget createTestWidget() {
      return ProviderScope(
        child: MaterialApp(
          home: const BarcodeScannerScreen(),
          theme: ThemeData(useMaterial3: true),
        ),
      );
    }

    setUp(() {
      // 设置测试环境的屏幕尺寸，避免布局溢出
      TestWidgetsFlutterBinding.ensureInitialized();
    });
    testWidgets('应该显示基本UI结构', (WidgetTester tester) async {
      // 设置更大的屏幕尺寸以避免溢出
      await tester.binding.setSurfaceSize(const Size(1080, 1920));

      // 构建Widget
      await tester.pumpWidget(createTestWidget());

      // 给更多时间让Widget和插件初始化
      await tester.pump(const Duration(seconds: 1));

      // 验证基本结构
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('扫描条码'), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 30)));
    testWidgets('AppBar应该有正确的样式', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // 验证AppBar样式
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, Colors.black);
      expect(appBar.foregroundColor, Colors.white);
      expect(appBar.elevation, 0);
    });

    testWidgets('应该显示主要UI元素', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // 验证关键UI元素
      expect(find.text('扫描条码'), findsOneWidget);
      expect(find.text('将条码对准扫描框'), findsOneWidget);
      expect(find.text('手动输入'), findsOneWidget);
    });

    testWidgets('AppBar应该包含控制按钮', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // 验证控制按钮
      expect(find.byIcon(Icons.flash_on), findsOneWidget);
      expect(find.byIcon(Icons.flip_camera_ios), findsOneWidget);
    });
    testWidgets('手动输入功能应该工作', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // 首先验证手动输入按钮存在
      expect(find.text('手动输入'), findsOneWidget);

      // 点击手动输入按钮
      await tester.tap(find.text('手动输入'));
      await tester.pumpAndSettle();

      // 验证对话框出现
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('手动输入条码'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('确定'), findsOneWidget);
    });
    testWidgets('手动输入对话框应该可以关闭', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // 首先验证手动输入按钮存在
      expect(find.text('手动输入'), findsOneWidget);

      // 打开对话框
      await tester.tap(find.text('手动输入'));
      await tester.pumpAndSettle();

      // 验证对话框存在
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);

      // 点击取消按钮
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      // 验证对话框关闭
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('应该有正确的主题颜色', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // 验证Scaffold背景色
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });
  });
}
