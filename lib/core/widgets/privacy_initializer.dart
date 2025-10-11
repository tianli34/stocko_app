import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/settings/presentation/widgets/privacy_policy_dialog.dart';

class PrivacyInitializer extends ConsumerStatefulWidget {
  const PrivacyInitializer({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PrivacyInitializer> createState() => _PrivacyInitializerState();
}

class _PrivacyInitializerState extends ConsumerState<PrivacyInitializer> {
  bool _isDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _showDialogsIfNeeded();
      });
    });
  }

  Future<void> _showDialogsIfNeeded() async {
    if (_isDialogShown || !mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      bool isPrivacyPolicyAgreed = await _handlePrivacyPolicy(prefs);

      if (!isPrivacyPolicyAgreed && mounted) {
        _isDialogShown = true;
        await _showPrivacyPolicyDialog(prefs, (context) {
          Navigator.of(context).pop();
        });
        _isDialogShown = false;
      }
    } catch (e) {
      print('❌ Dialog check failed: $e');
    }
  }

  Future<bool> _handlePrivacyPolicy(SharedPreferences prefs) async {
    final oldKeyAgreed = prefs.getBool('privacy_policy_agreed') ?? false;
    final newKeyAgreed = prefs.getBool('isPrivacyPolicyAgreed') ?? false;
    bool isAgreed = newKeyAgreed || oldKeyAgreed;

    if (oldKeyAgreed && !newKeyAgreed) {
      await prefs.setBool('isPrivacyPolicyAgreed', true);
      await prefs.remove('privacy_policy_agreed');
      isAgreed = true;
    }
    return isAgreed;
  }

  Future<void> _showPrivacyPolicyDialog(SharedPreferences prefs, Function(BuildContext) onAgreed) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PrivacyPolicyDialog(
          onAgreed: () async {
            await prefs.setBool('isPrivacyPolicyAgreed', true);
            if (mounted) onAgreed(context);
          },
        );
      },
    );
    
    // 如果用户点击"不同意"，退出应用
    if (result == false) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}