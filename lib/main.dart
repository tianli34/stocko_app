// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stocko_app/app.dart';
import 'core/services/image_cache_service.dart';
import 'core/widgets/privacy_initializer.dart';
import 'config/flavor_config.dart';
import 'core/initialization/app_initializer.dart';

Future<void> runStockoApp(FlavorConfig config) async {
  // 1. 确保 Flutter 引擎的绑定已经初始化。
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 初始化图片缓存服务
  final imageCacheService = ImageCacheService();
  await imageCacheService.initialize();

  // 3. 运行应用
  runApp(
    ProviderScope(
      overrides: [
        flavorConfigProvider.overrideWithValue(config),
      ],
      child: const AppInitializer(child: PrivacyInitializer(child: StockoApp())),
    ),
  );
}

void main() {
  // 默认运行 personalized 配置
  runStockoApp(
    FlavorConfig(
      flavor: AppFlavor.personalized,
      appTitle: "定制版库存管理",
      featureFlags: {
        Feature.showDatabaseTools: true,
      },
    ),
  );
}
