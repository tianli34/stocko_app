// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stocko_app/app.dart';
import 'package:stocko_app/features/settings/presentation/widgets/privacy_policy_dialog.dart';
import 'core/services/image_cache_service.dart';
import 'core/initialization/app_initializer.dart';

void main() async {
  // 1. 确保 Flutter 引擎的绑定已经初始化。
  // 这对于在 runApp() 之前调用原生代码或进行异步操作是必需的。
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 初始化图片缓存服务
  final imageCacheService = ImageCacheService();
  await imageCacheService.initialize();

  // 3. 运行应用，并使用 ProviderScope 将整个应用包裹起来。
  // ProviderScope 是 Riverpod 的核心，它存储了所有 Provider 的状态。
  // 任何在 ProviderScope 下的小部件都可以访问这些 Provider。
  runApp(ProviderScope(child: AppInitializer(child: PrivacyCheck())));
}

class PrivacyCheck extends StatefulWidget {
  const PrivacyCheck({super.key});

  @override
  State<PrivacyCheck> createState() => _PrivacyCheckState();
}

class _PrivacyCheckState extends State<PrivacyCheck> {
  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    _checkPrivacyAgreement();
  }

  Future<void> _checkPrivacyAgreement() async {
    final prefs = await SharedPreferences.getInstance();
    final agreed = prefs.getBool('privacy_policy_agreed') ?? false;
    if (agreed) {
      setState(() {
        _agreed = true;
      });
    } else {
      // 使用 WidgetsBinding.instance.addPostFrameCallback 确保在第一帧渲染完成后再显示对话框
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return PrivacyPolicyDialog(
              onAgreed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('privacy_policy_agreed', true);
                setState(() {
                  _agreed = true;
                });
              },
            );
          },
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _agreed ? const StockoApp() : const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
  }
}
