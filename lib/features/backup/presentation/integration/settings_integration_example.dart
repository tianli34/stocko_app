import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/backup_button.dart';

/// 示例：如何将备份功能集成到设置页面
/// 
/// 在现有的 _DataManagementSection 中添加以下代码：
/// 
/// ```dart
/// // 在 _DataManagementSection 的 build 方法中添加：
/// const QuickBackupButton(),
/// const Divider(),
/// ```
/// 
/// 或者创建一个专门的备份管理部分：
class BackupManagementSection extends ConsumerWidget {
  const BackupManagementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '数据备份',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const QuickBackupButton(),
        ListTile(
          leading: const Icon(Icons.folder),
          title: const Text('管理备份文件'),
          subtitle: const Text('查看、删除或分享已创建的备份'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            // TODO: 导航到备份管理页面
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('备份管理功能即将推出')),
            );
          },
        ),
      ],
    );
  }
}

/// 使用示例：
/// 
/// 在 SettingsScreen 中使用：
/// ```dart
/// ListView(
///   children: [
///     // ... 其他设置项
///     const Divider(),
///     const BackupManagementSection(),
///     // ... 其他设置项
///   ],
/// )
/// ```