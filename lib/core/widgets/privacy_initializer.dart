import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/settings/presentation/widgets/privacy_policy_dialog.dart';
import '../../features/settings/presentation/widgets/terms_of_service_dialog.dart';

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
      bool isTermsOfServiceAgreed = await _handleTermsOfService(prefs);

      if (!isPrivacyPolicyAgreed && mounted) {
        _isDialogShown = true;
        await _showPrivacyPolicyDialog(prefs, (context) async {
          if (!isTermsOfServiceAgreed && mounted) {
            await _showTermsOfServiceDialog(prefs, (context) {
              Navigator.of(context).pop();
            });
          } else {
            Navigator.of(context).pop();
          }
        });
        _isDialogShown = false;
      } else if (!isTermsOfServiceAgreed && mounted) {
        _isDialogShown = true;
        await _showTermsOfServiceDialog(prefs, (context) {
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

  Future<bool> _handleTermsOfService(SharedPreferences prefs) async {
    return prefs.getBool('isTermsOfServiceAgreed') ?? false;
  }

  Future<void> _showPrivacyPolicyDialog(SharedPreferences prefs, Function(BuildContext) onAgreed) async {
    await showDialog(
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
  }

  Future<void> _showTermsOfServiceDialog(SharedPreferences prefs, Function(BuildContext) onAgreed) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return TermsOfServiceDialog(
          onAgreed: () async {
            await prefs.setBool('isTermsOfServiceAgreed', true);
            if (mounted) onAgreed(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}