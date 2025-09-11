import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/core/services/toast_service.dart';

// 由于 ToastService 直接调用 Fluttertoast 静态方法，在纯单元测试中我们只做接口可调用性验证。
// 若需要集成测试可在 flutter_test 环境下通过依赖注入或包装类进行替换，这里保持轻量。
void main() {
  // 初始化测试绑定，提供 BinaryMessenger 能力
  TestWidgetsFlutterBinding.ensureInitialized();

  // 为 fluttertoast 的 MethodChannel 设置 mock，避免 MissingPluginException
  // 注意：fluttertoast 实际使用的 channel 为 'PonnamKarthik/fluttertoast'
  const MethodChannel toastChannel = MethodChannel('PonnamKarthik/fluttertoast');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (MethodCall methodCall) async {
      // fluttertoast 常用方法：showToast / cancel
      switch (methodCall.method) {
        case 'showToast':
        case 'cancel':
          return null;
        default:
          return null;
      }
    });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, null);
  });

  test('ToastService 方法可被调用', () {
    // 不抛出异常即认为通过（Fluttertoast 在测试环境通常被忽略）
    ToastService.success('ok');
    ToastService.error('err');
    ToastService.warning('warn');
    ToastService.info('info');
    ToastService.show('raw');
  });
}
