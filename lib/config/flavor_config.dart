import 'package:flutter_riverpod/flutter_riverpod.dart';

// 定义所有支持的 Flavor
enum AppFlavor {
  generic,
  personalized,
}

// 定义功能开关的枚举
enum Feature {
  showDatabaseTools,
}

// Flavor 配置类
class FlavorConfig {
  final AppFlavor flavor;
  final String appTitle;
  // 在这里添加更多需要根据 Flavor 变化的配置
  // 例如：API 地址、主题颜色、功能开关等
  final Map<Feature, bool> featureFlags;

  FlavorConfig({
    required this.flavor,
    required this.appTitle,
    required this.featureFlags,
  });
}

// 创建一个 Provider 来访问 FlavorConfig
final flavorConfigProvider = Provider<FlavorConfig>((ref) {
  // 这个 provider 必须在 main 入口文件中被 override
  throw UnimplementedError('flavorConfigProvider must be overridden in the main entry point.');
});