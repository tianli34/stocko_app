import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/router/router_provider.dart';
import 'core/theme/theme_provider.dart';
import 'core/initialization/app_initializer.dart';

class StockoApp extends ConsumerWidget {
  const StockoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('🏠 StockoApp build called');
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Stocko 库存管理系统',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
      builder: (context, child) {
        // 确保 AppInitializer（含隐私弹窗逻辑）位于 MaterialApp 之下，
        // 从而具备 MaterialLocalizations 和正确的语义环境。
        return AppInitializer(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
