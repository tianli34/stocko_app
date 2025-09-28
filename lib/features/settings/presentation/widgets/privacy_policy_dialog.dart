import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:markdown_widget/markdown_widget.dart';

class PrivacyPolicyDialog extends StatefulWidget {
  final Future<void> Function() onAgreed;

  const PrivacyPolicyDialog({super.key, required this.onAgreed});

  @override
  State<PrivacyPolicyDialog> createState() => _PrivacyPolicyDialogState();
}

class _PrivacyPolicyDialogState extends State<PrivacyPolicyDialog> {
  bool _agreed = false;
  String? _privacyPolicy;

  @override
  void initState() {
    super.initState();
    _loadPrivacyPolicy();
  }

  Future<void> _loadPrivacyPolicy() async {
    final policy =
        await rootBundle.loadString('assets/text/privacy_policy.md');
    setState(() {
      _privacyPolicy = policy;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('隐私政策'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  const TextSpan(
                    text: '请您在使用本应用前，仔细阅读并充分理解',
                  ),
                  TextSpan(
                    text: '《隐私政策》',
                    style: const TextStyle(color: Colors.blue),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        context.push('/settings/privacy-policy');
                      },
                  ),
                  const TextSpan(
                    text: '的全部内容。当您点击“同意”并开始使用我们的产品或服务，即表示您已充分理解并同意本政策。',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_privacyPolicy != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: Scrollbar(
                  child: SingleChildScrollView(
                    child: MarkdownWidget(
                      data: _privacyPolicy!,
                      shrinkWrap: true,
                    ),
                  ),
                ),
              )
            else
              const Center(child: CircularProgressIndicator()),
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
                  child: Text('我已阅读并同意《隐私政策》'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
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