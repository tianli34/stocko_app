import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/widgets/universal_barcode_scanner.dart';

void main() {
  group('UniversalBarcodeScanner 连续扫码测试', () {
    testWidgets('连续扫码模式应该正确配置', (WidgetTester tester) async {
      // 设置合适的屏幕尺寸以避免布局溢出
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      final scannedCodes = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: UniversalBarcodeScanner(
            config: const BarcodeScannerConfig(
              title: '连续扫码测试',
              subtitle: '测试连续扫码功能',
              continuousMode: true,
              continuousDelay: 500, // 短延迟用于测试
            ),
            onBarcodeScanned: (barcode) {
              scannedCodes.add(barcode);
            },
          ),
        ),
      );

      // 验证页面能正常渲染
      await tester.pumpAndSettle();
      expect(find.text('连续扫码测试'), findsOneWidget);
      expect(find.text('测试连续扫码功能'), findsOneWidget);
    });

    testWidgets('非连续扫码模式应该有默认配置', (WidgetTester tester) async {
      // 设置合适的屏幕尺寸以避免布局溢出
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(
        MaterialApp(
          home: UniversalBarcodeScanner(
            config: const BarcodeScannerConfig(
              title: '普通扫码测试',
              subtitle: '测试普通扫码功能',
              continuousMode: false,
            ),
            onBarcodeScanned: (barcode) {
              // 处理扫码结果
            },
          ),
        ),
      );

      // 验证页面能正常渲染
      await tester.pumpAndSettle();
      expect(find.text('普通扫码测试'), findsOneWidget);
      expect(find.text('测试普通扫码功能'), findsOneWidget);
    });

    testWidgets('配置应该有正确的默认值', (WidgetTester tester) async {
      const config = BarcodeScannerConfig();

      expect(config.title, '扫描条码');
      expect(config.subtitle, '将条码对准扫描框');
      expect(config.continuousMode, false);
      expect(config.continuousDelay, 1000);
      expect(config.enableManualInput, true);
      expect(config.enableGalleryPicker, true);
      expect(config.enableFlashlight, true);
      expect(config.enableCameraSwitch, true);
      expect(config.enableScanSound, true);
      expect(config.backgroundColor, Colors.black);
      expect(config.foregroundColor, Colors.white);
    });

    testWidgets('连续扫码配置应该正确设置', (WidgetTester tester) async {
      const config = BarcodeScannerConfig(
        continuousMode: true,
        continuousDelay: 500,
      );

      expect(config.continuousMode, true);
      expect(config.continuousDelay, 500);
    });
  });
}
