import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:markdown_widget/markdown_widget.dart';

class TermsOfServiceDialog extends StatefulWidget {
  final Future<void> Function() onAgreed;

  const TermsOfServiceDialog({super.key, required this.onAgreed});

  @override
  State<TermsOfServiceDialog> createState() => _TermsOfServiceDialogState();
}

class _TermsOfServiceDialogState extends State<TermsOfServiceDialog> {
  bool _agreed = false;
  String? _termsOfService;

  @override
  void initState() {
    super.initState();
    _loadTermsOfService();
  }

  Future<void> _loadTermsOfService() async {
    final policy =
        await rootBundle.loadString('assets/text/terms_of_service.md');
    setState(() {
      _termsOfService = policy;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('服务条款'),
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
                    text: '《服务条款》',
                    style: const TextStyle(color: Colors.blue),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        context.push('/settings/terms-of-service');
                      },
                  ),
                  const TextSpan(
                    text: '的全部内容。当您点击“同意”并开始使用我们的产品或服务，即表示您已充分理解并同意本政策。',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_termsOfService != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: Scrollbar(
                  child: SingleChildScrollView(
                    child: MarkdownWidget(
                      data: _termsOfService!,
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
                  child: Text('我已阅读并同意《服务条款》'),
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