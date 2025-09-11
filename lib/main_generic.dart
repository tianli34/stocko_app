// Entry point for the generic flavor
import 'package:stocko_app/config/flavor_config.dart';
import 'package:stocko_app/main.dart' as app;

void main() {
  // 定义通用版配置
  final genericConfig = FlavorConfig(
    flavor: AppFlavor.generic,
    appTitle: "通用库存管理",
    featureFlags: {
      Feature.showDatabaseTools: false, // 通用版关闭数据库工具
    },
  );

  // 使用通用配置运行应用
  app.runStockoApp(genericConfig);
}