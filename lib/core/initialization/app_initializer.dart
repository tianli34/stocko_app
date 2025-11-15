import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_providers.dart';
import '../services/user_agreement_provider.dart';
import '../../features/settings/presentation/widgets/privacy_policy_dialog.dart';

/// 应用启动初始化Widget
/// 负责数据库初始化和用户协议检查
class AppInitializer extends ConsumerStatefulWidget {
  final Widget child;

  const AppInitializer({super.key, required this.child});

  @override
  ConsumerState<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<AppInitializer> {
  bool _agreementDialogShown = false;

  @override
  Widget build(BuildContext context) {
    final initializationState = ref.watch(databaseInitializationProvider);
    final agreementStatus = ref.watch(userAgreementStatusProvider);

    return initializationState.when(
      data: (_) {
        // 数据库初始化完成后，检查用户协议
        return agreementStatus.when(
          data: (hasAccepted) {
            if (!hasAccepted && !_agreementDialogShown) {
              // 用户未同意协议，显示协议对话框
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_agreementDialogShown) {
                  _agreementDialogShown = true;
                  _showAgreementDialog();
                }
              });
            }
            return widget.child;
          },
          loading: () => const _LoadingScreen(),
          error: (error, stackTrace) => _ErrorScreen(
            error: error,
            onRetry: () => ref.invalidate(userAgreementStatusProvider),
          ),
        );
      },
      loading: () => const _LoadingScreen(),
      error: (error, stackTrace) => _ErrorScreen(
        error: error,
        onRetry: () => ref.invalidate(databaseInitializationProvider),
      ),
    );
  }

  void _showAgreementDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PrivacyPolicyDialog(
        onAgreed: () async {
          final service = ref.read(userAgreementServiceProvider);
          await service.acceptAgreement();
          ref.invalidate(userAgreementStatusProvider);
          if (mounted) {
            Navigator.of(context).pop();
          }
        },
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
                '铺得清 App',
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
