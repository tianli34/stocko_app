import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyDialog extends StatefulWidget {
  final Future<void> Function() onAgreed;

  const PrivacyPolicyDialog({super.key, required this.onAgreed});

  @override
  State<PrivacyPolicyDialog> createState() => _PrivacyPolicyDialogState();
}

class _PrivacyPolicyDialogState extends State<PrivacyPolicyDialog> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('用户协议与隐私政策'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                const TextSpan(text: '请您在使用本应用前，仔细阅读并充分理解'),
                TextSpan(
                  text: '《用户协议》',
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      context.push('/settings/user-agreement');
                    },
                ),
                const TextSpan(text: '和'),
                TextSpan(
                  text: '《隐私政策》',
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      context.push('/settings/privacy-policy');
                    },
                ),
                const TextSpan(
                  text: '的全部内容。当您点击"同意"并开始使用我们的产品或服务，即表示您已充分理解并同意本协议和政策。',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _agreed,
                onChanged: (bool? value) {
                  setState(() {
                    _agreed = value ?? false;
                  });
                },
              ),
              const Flexible(
                child: Text('我已阅读并同意《用户协议》和《隐私政策》'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            // 用户不同意隐私政策，退出应用
            SystemNavigator.pop();
          },
          child: const Text('不同意'),
        ),
        TextButton(
          onPressed: _agreed
              ? () async {
                  await widget.onAgreed();
                }
              : null,
          child: const Text('同意'),
        ),
      ],
    );
  }
}
