import 'package:flutter/material.dart';

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
      title: const Text('隐私政策'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '请您在使用本应用前，仔细阅读并充分理解《隐私政策》的全部内容。当您点击“同意”并开始使用我们的产品或服务，即表示您已充分理解并同意本政策。',
            ),
            const SizedBox(height: 16),
            // 在此处添加您的完整隐私政策文本
            const Text(
              '完整的隐私政策文本...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
                  widget.onAgreed().then((_) {
                    // 在 onAgreed 完成后（即 SharedPreferences 已设置）
                    // 再关闭对话框
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  });
                }
              : null,
          child: const Text('同意'),
        ),
      ],
    );
  }
}