import 'package:flutter/material.dart';

import '../../domain/models/auto_backup_settings.dart';

/// 备份选项配置卡片
class BackupOptionsCard extends StatelessWidget {
  final AutoBackupOptions options;
  final ValueChanged<AutoBackupOptions> onOptionsChanged;

  const BackupOptionsCard({
    super.key,
    required this.options,
    required this.onOptionsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '备份选项',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('包含图片文件'),
              subtitle: const Text('备份时包含产品图片等文件'),
              value: options.includeImages,
              onChanged: (value) {
                onOptionsChanged(options.copyWith(includeImages: value));
              },
            ),
            SwitchListTile(
              title: const Text('压缩备份文件'),
              subtitle: const Text('减少备份文件大小'),
              value: options.compress,
              onChanged: (value) {
                onOptionsChanged(options.copyWith(compress: value));
              },
            ),
            SwitchListTile(
              title: const Text('加密备份文件'),
              subtitle: const Text('使用密码保护备份文件'),
              value: options.encrypt,
              onChanged: (value) {
                if (value) {
                  _showPasswordDialog(context);
                } else {
                  onOptionsChanged(options.copyWith(
                    encrypt: false,
                    password: null,
                  ));
                }
              },
            ),
            if (options.encrypt && options.password != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '已设置加密密码',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _showPasswordDialog(context),
                      child: const Text('修改'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPasswordDialog(BuildContext context) {
    final passwordController = TextEditingController(text: options.password ?? '');
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置加密密码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '密码',
                hintText: '请输入加密密码',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '确认密码',
                hintText: '请再次输入密码',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final password = passwordController.text.trim();
              final confirm = confirmController.text.trim();

              if (password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('密码不能为空')),
                );
                return;
              }

              if (password != confirm) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('两次输入的密码不一致')),
                );
                return;
              }

              onOptionsChanged(options.copyWith(
                encrypt: true,
                password: password,
              ));

              Navigator.of(context).pop();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}