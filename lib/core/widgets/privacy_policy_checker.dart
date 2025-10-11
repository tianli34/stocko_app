import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/settings/presentation/widgets/privacy_policy_dialog.dart';

/// 隐私政策检查器
/// 在 MaterialApp 内部使用，确保有 Navigator 可用
class PrivacyPolicyChecker extends StatefulWidget {
  final Widget child;

  const PrivacyPolicyChecker({super.key, required this.child});

  @override
  State<PrivacyPolicyChecker> createState() => _PrivacyPolicyCheckerState();
}

class _PrivacyPolicyCheckerState extends State<PrivacyPolicyChecker> {
  bool _isChecking = true;
  bool _needsAgreement = false;

  @override
  void initState() {
    super.initState();
    _checkPrivacyPolicy();
  }

  Future<void> _checkPrivacyPolicy() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isAgreed = prefs.getBool('isPrivacyPolicyAgreed') ?? false;

      debugPrint('🔐 隐私政策状态: isAgreed=$isAgreed');

      if (mounted) {
        setState(() {
          _needsAgreement = !isAgreed;
          _isChecking = false;
        });
      }
    } catch (e) {
      debugPrint('❗ 隐私政策检查失败: $e');
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _onAgreed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPrivacyPolicyAgreed', true);
    if (mounted) {
      setState(() {
        _needsAgreement = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_needsAgreement) {
      return _PrivacyPolicyScreen(onAgreed: _onAgreed);
    }

    return widget.child;
  }
}

/// 隐私政策全屏页面
class _PrivacyPolicyScreen extends StatelessWidget {
  final Future<void> Function() onAgreed;

  const _PrivacyPolicyScreen({required this.onAgreed});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 禁止返回
      child: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: PrivacyPolicyDialog(
                onAgreed: onAgreed,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
