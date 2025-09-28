import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/backup_options.dart';

/// 创建备份对话框
class CreateBackupDialog extends ConsumerStatefulWidget {
  final Function(BackupOptions) onCreateBackup;

  const CreateBackupDialog({
    super.key,
    required this.onCreateBackup,
  });

  @override
  ConsumerState<CreateBackupDialog> createState() => _CreateBackupDialogState();
}

class _CreateBackupDialogState extends ConsumerState<CreateBackupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _includeImages = false;
  bool _encrypt = false;
  bool _compress = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    // 设置默认备份名称
    final now = DateTime.now();
    final defaultName = 'backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    _nameController.text = defaultName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('创建备份'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 备份名称
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '备份名称',
                    hintText: '请输入备份名称',
                    prefixIcon: Icon(Icons.label),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入备份名称';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 备份描述
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: '备份描述（可选）',
                    hintText: '请输入备份描述',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // 选项标题
                Text(
                  '备份选项',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                // 包含图片
                CheckboxListTile(
                  title: const Text('包含图片文件'),
                  subtitle: const Text('备份产品图片等媒体文件'),
                  value: _includeImages,
                  onChanged: (value) {
                    setState(() {
                      _includeImages = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),

                // 压缩备份
                CheckboxListTile(
                  title: const Text('压缩备份文件'),
                  subtitle: const Text('减小备份文件大小'),
                  value: _compress,
                  onChanged: (value) {
                    setState(() {
                      _compress = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),

                // 加密备份
                CheckboxListTile(
                  title: const Text('加密备份'),
                  subtitle: const Text('使用密码保护备份文件'),
                  value: _encrypt,
                  onChanged: (value) {
                    setState(() {
                      _encrypt = value ?? false;
                      if (!_encrypt) {
                        _passwordController.clear();
                        _confirmPasswordController.clear();
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),

                // 加密密码输入
                if (_encrypt) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: '加密密码',
                      hintText: '请输入加密密码',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _showPassword = !_showPassword;
                          });
                        },
                      ),
                    ),
                    obscureText: !_showPassword,
                    validator: (value) {
                      if (_encrypt && (value == null || value.length < 6)) {
                        return '密码长度至少6位';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: '确认密码',
                      hintText: '请再次输入密码',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_showConfirmPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _showConfirmPassword = !_showConfirmPassword;
                          });
                        },
                      ),
                    ),
                    obscureText: !_showConfirmPassword,
                    validator: (value) {
                      if (_encrypt && value != _passwordController.text) {
                        return '两次输入的密码不一致';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 16),

                // 提示信息
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '备份将包含所有业务数据，请确保设备有足够的存储空间。',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _createBackup,
          child: const Text('创建备份'),
        ),
      ],
    );
  }

  void _createBackup() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final options = BackupOptions(
      customName: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      includeImages: _includeImages,
      encrypt: _encrypt,
      password: _encrypt ? _passwordController.text : null,
      compress: _compress,
    );

    Navigator.of(context).pop();
    widget.onCreateBackup(options);
  }
}