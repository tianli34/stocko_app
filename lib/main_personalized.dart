// Entry point for the personalized flavor
import 'package:stocko_app/config/flavor_config.dart';
import 'package:stocko_app/main.dart' as app;

void main() {
  // 定义定制版配置
  final personalizedConfig = FlavorConfig(
    flavor: AppFlavor.personalized,
    appTitle: "定制版库存管理",
    featureFlags: {
      Feature.showDatabaseTools: true, // 定制版保留数据库工具
    },
  );

  // 使用定制配置运行应用
  app.runStockoApp(personalizedConfig);
}