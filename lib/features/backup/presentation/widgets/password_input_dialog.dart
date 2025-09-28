import 'package:flutter/material.dart';

/// 密码输入对话框
class PasswordInputDialog extends StatefulWidget {
  final ValueChanged<String> onPasswordSubmitted;

  const PasswordInputDialog({
    super.key,
    required this.onPasswordSubmitted,
  });

  @override
  State<PasswordInputDialog> createState() => _PasswordInputDialogState();
}

class _PasswordInputDialogState extends State<PasswordInputDialog> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.lock,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Text('输入密码'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('此备份文件已加密，请输入密码以继续：'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '密码',
                hintText: '请输入备份密码',
                prefixIcon: const Icon(Icons.key),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入密码';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submitPassword(),
            ),
            const SizedBox(height: 8),
            Text(
              '提示：如果忘记密码，将无法恢复此备份文件',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitPassword,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('确定'),
        ),
      ],
    );
  }

  void _submitPassword() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final password = _passwordController.text.trim();
    
    // 关闭对话框并提交密码
    Navigator.of(context).pop();
    widget.onPasswordSubmitted(password);
  }
}