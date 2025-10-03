import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/backup_options.dart';
import 'unified_backup_integration.dart';

/// 统一备份服务使用示例
class UnifiedBackupUsageExample extends ConsumerWidget {
  const UnifiedBackupUsageExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('统一备份示例'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '统一备份服务集成示例',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // 基本备份按钮
            UnifiedBackupIntegration.buildBackupButton(
              label: '创建基本备份',
              onSuccess: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('备份创建成功！')),
                );
              },
              onError: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('备份失败：$error')),
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            // 带描述的备份按钮
            UnifiedBackupIntegration.buildBackupButton(
              label: '创建带描述的备份',
              options: const BackupOptions(
                description: '手动创建的统一备份',
                customName: 'manual_backup',
              ),
              onSuccess: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('带描述的备份创建成功！')),
                );
              },
              onError: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('备份失败：$error')),
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            // 自定义备份按钮
            ElevatedButton(
              onPressed: () => _createCustomBackup(context, ref),
              child: const Text('创建自定义备份'),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              '特性说明：',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('✓ 流式数据处理，减少内存占用'),
                    Text('✓ 增强的错误处理和重试机制'),
                    Text('✓ 详细的进度显示'),
                    Text('✓ 数据库健康检查'),
                    Text('✓ 可取消的备份操作'),
                    Text('✓ 智能压缩和性能监控'),
                    Text('✓ 统一的资源管理'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _createCustomBackup(BuildContext context, WidgetRef ref) {
    // 显示自定义选项对话框
    showDialog(
      context: context,
      builder: (context) => _CustomBackupDialog(ref: ref),
    );
  }
}

class _CustomBackupDialog extends StatefulWidget {
  final WidgetRef ref;
  
  const _CustomBackupDialog({required this.ref});
  
  @override
  State<_CustomBackupDialog> createState() => _CustomBackupDialogState();
}

class _CustomBackupDialogState extends State<_CustomBackupDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final bool _encrypt = false;
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('自定义备份选项'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '备份名称（可选）',
              hintText: '例如：daily_backup',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: '备份描述',
              hintText: '例如：每日自动备份',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            title: const Text('加密备份'),
            subtitle: const Text('当前版本暂不支持'),
            value: _encrypt,
            onChanged: null, // 暂时禁用
          ),
        ],
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
    Navigator.of(context).pop();
    
    final options = BackupOptions(
      customName: _nameController.text.trim().isEmpty 
          ? null 
          : _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      encrypt: _encrypt,
    );
    
    UnifiedBackupIntegration.createBackupWithErrorHandling(
      context: context,
      ref: widget.ref,
      options: options,
      onSuccess: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('自定义备份创建成功！')),
        );
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('备份失败：$error')),
        );
      },
    );
  }
}