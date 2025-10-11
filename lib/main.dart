// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stocko_app/app.dart';
import 'core/services/image_cache_service.dart';
import 'config/flavor_config.dart';
// AppInitializer is now injected inside StockoApp via MaterialApp.builder

Future<void> runStockoApp(FlavorConfig config) async {
  // 1. 确保 Flutter 引擎的绑定已经初始化。
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 设置系统UI样式，移除底部导航栏的半透明遮罩
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.white, // 设置为白色或透明
      systemNavigationBarIconBrightness: Brightness.dark, // 图标颜色
      systemNavigationBarDividerColor: Colors.transparent, // 分隔线透明
    ),
  );

  // 启用边到边显示（可选，让应用内容延伸到系统栏下方）
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // 3. 初始化图片缓存服务
  final imageCacheService = ImageCacheService();
  await imageCacheService.initialize();

  // 4. 运行应用
  runApp(
    ProviderScope(
      overrides: [flavorConfigProvider.overrideWithValue(config)],
      child: const StockoApp(),
    ),
  );
}

void main() {
  // 默认运行 personalized 配置
  runStockoApp(
    FlavorConfig(
      flavor: AppFlavor.personalized,
      appTitle: "定制版库存管理",
      featureFlags: {Feature.showDatabaseTools: true},
    ),
  );
}
