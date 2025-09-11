import 'package:flutter/material.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showPrivacyDialogIfNeeded());
  }

  Future<void> _showPrivacyDialogIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final isPrivacyPolicyAgreed = prefs.getBool('isPrivacyPolicyAgreed') ?? false;

    if (!isPrivacyPolicyAgreed && mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return PrivacyPolicyDialog(
            onAgreed: () async {
              await prefs.setBool('isPrivacyPolicyAgreed', true);
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}