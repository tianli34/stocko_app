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
    
    // 根据系统主题更新UI样式
    final brightness = MediaQuery.platformBrightnessOf(context);
    AppTheme.updateSystemUIOverlay(brightness);
    
    return AppInitializer(
      child: MaterialApp.router(
        title: '铺得清 库存管理系统',
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
      ),
    );
  }
}
