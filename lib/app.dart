import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// 临时的路由配置，您可以根据需要修改
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text('Welcome to Stocko App'),
          ),
        ),
      ),
    ],
  );
});

// 临时的主题 Provider，您可以根据需要修改
final themeProvider = Provider<ThemeData>((ref) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    useMaterial3: true,
  );
});

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final theme = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Stocko App',
      theme: theme,
      routerConfig: router,
    );
  }
}
