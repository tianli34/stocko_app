import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_providers.dart';

/// 应用启动初始化Widget
/// 在应用启动时自动进行数据库初始化
class AppInitializer extends ConsumerWidget {
  final Widget child;

  const AppInitializer({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initializationState = ref.watch(databaseInitializationProvider);

    return initializationState.when(
      data: (_) => child, // 初始化完成，显示主应用
      loading: () => const _LoadingScreen(), // 显示加载界面
      error: (error, stackTrace) => _ErrorScreen(
        error: error,
        onRetry: () => ref.invalidate(databaseInitializationProvider),
      ),
    );
  }
}

/// 初始化加载界面
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.store, size: 60, color: Colors.blue.shade600),
              ),
              const SizedBox(height: 32),

              // App Title
              Text(
                'Stocko App',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),

              // Loading Text
              Text(
                '正在初始化数据库...',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              // Loading Indicator
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 初始化错误界面
class _ErrorScreen extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorScreen({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error Icon
                Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
                const SizedBox(height: 24),

                // Error Title
                Text(
                  '初始化失败',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),

                // Error Message
                Text(
                  '数据库初始化过程中发生错误',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Error Details
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    error.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Retry Button
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
